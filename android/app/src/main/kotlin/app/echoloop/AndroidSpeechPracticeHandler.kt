package app.echoloop

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/**
 * Android 语音练习平台桥接。
 *
 * 通过 MethodChannel/EventChannel 与 Dart 侧通信，
 * 使用 AudioRecord（WAV 录音 + VAD）实现
 * 与 iOS 侧 IOSSpeechPracticeHandler 相同的协议。
 *
 * 语音识别由 Dart 侧的离线 ASR 引擎（sherpa-onnx）负责，
 * 原生层仅负责录音和 VAD。
 */
class AndroidSpeechPracticeHandler(
    private val activity: Activity,
    binaryMessenger: io.flutter.plugin.common.BinaryMessenger,
) : MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    PluginRegistry.RequestPermissionsResultListener {

    private val methodChannel = MethodChannel(binaryMessenger, "top.echo-loop/speech_practice")
    private val eventChannel = EventChannel(binaryMessenger, "top.echo-loop/speech_practice/events")
    private val mainHandler = Handler(Looper.getMainLooper())
    // 单线程串口执行器，确保录音启停、WAV 头回填、静音裁剪与释放严格串行且不阻塞主线程。
    private val audioIoExecutor = Executors.newSingleThreadExecutor()

    private var eventSink: EventChannel.EventSink? = null

    // 引擎级资源（warmup 创建，shutdown 释放）
    private val wavRecorder = WavRecorder()
    private var isEngineReady = false
    private var isDisposed = false

    // 句子级状态（仅在主线程读写；sessionGeneration 加 @Volatile 供 IO 线程快照校验代数）
    private var isRecording = false
    private var currentPromptId: String? = null
    private var currentFilePath: String? = null
    @Volatile private var sessionGeneration = 0
    private var finalTranscriptEmitted = false

    // VAD 状态
    private var hasDetectedSpeech = false
    private var silenceStartAt: Long = 0L
    private var lastReportedSilenceMs = -1
    private var recordedDurationMs: Double = 0.0
    private var firstDetectedSpeechMs: Double? = null
    private var lastDetectedSpeechMs: Double? = null

    /** 有声判定门槛，按环境底噪自适应（替代旧固定门槛 0.015）。 */
    private val vadThreshold = AdaptiveVadThreshold()

    // 权限请求回调
    private var pendingPermissionResult: MethodChannel.Result? = null

    companion object {
        private const val TAG = "SpeechPractice"
        private const val PERMISSION_REQUEST_CODE = 9001
    }

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
        attachRecorderBufferCallback()
    }

    // region StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // endregion

    // region MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPermissionStatus" -> result.success(permissionMap())
            "requestPermissions" -> requestPermissions(result)
            "warmup" -> warmup(result)
            "startSession" -> startSession(call, result)
            "stopSession" -> stopSession(result)
            "cancelSession" -> cancelSession(result)
            "shutdown" -> shutdown(result)
            "deleteRecording" -> deleteRecording(call, result)
            "getDeviceInfo" -> {
                val runtime = Runtime.getRuntime()
                val memInfo = android.app.ActivityManager.MemoryInfo()
                (activity.getSystemService(android.content.Context.ACTIVITY_SERVICE) as android.app.ActivityManager)
                    .getMemoryInfo(memInfo)
                result.success(mapOf("ramBytes" to memInfo.totalMem))
            }
            "setRecognitionEnabled" -> result.success(emptyMap<String, Any>()) // Android 纯录音，ASR 由 Dart 层处理
            else -> result.notImplemented()
        }
    }

    // endregion

    // region 权限

    private fun permissionMap(): Map<String, String> {
        val status = microphonePermissionStatus()
        // Android 只有 RECORD_AUDIO 一个权限，两个字段返回相同值。
        return mapOf("microphoneStatus" to status, "speechStatus" to status)
    }

    private fun microphonePermissionStatus(): String {
        return when {
            ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO)
                == PackageManager.PERMISSION_GRANTED -> "granted"
            ActivityCompat.shouldShowRequestPermissionRationale(
                activity, Manifest.permission.RECORD_AUDIO
            ) -> "denied"
            else -> "notDetermined"
        }
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO)
            == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(permissionMap())
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            PERMISSION_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        pendingPermissionResult?.success(permissionMap())
        pendingPermissionResult = null
        return true
    }

    // endregion

    // region warmup / shutdown

    private fun warmup(result: MethodChannel.Result) {
        if (isEngineReady) {
            result.success(emptyMap<String, Any>())
            return
        }

        // AudioRecord 需要权限，若未授予则延迟到 startSession 再初始化。
        val hasPermission = microphonePermissionStatus() == "granted"
        isEngineReady = true
        if (!hasPermission) {
            result.success(emptyMap<String, Any>())
            return
        }

        if (!runOnAudioIo {
                initWavRecorder()
                mainHandler.post { result.success(emptyMap<String, Any>()) }
            }) {
            result.success(emptyMap<String, Any>())
        }
    }

    private fun shutdown(result: MethodChannel.Result) {
        isRecording = false
        sessionGeneration++
        resetMainSentenceState()
        isEngineReady = false
        if (!runOnAudioIo {
                stopWavRecorderQuietly()
                wavRecorder.release()
                mainHandler.post { result.success(emptyMap<String, Any>()) }
            }) {
            result.success(emptyMap<String, Any>())
        }
    }

    private fun initWavRecorder() {
        if (!wavRecorder.isInitialized) {
            val ok = wavRecorder.initialize()
            if (!ok) Log.w(TAG, "WavRecorder initialization failed")
        }
        // release() 会清空 onBuffer，重新初始化后必须恢复。
        attachRecorderBufferCallback()
    }

    private fun attachRecorderBufferCallback() {
        wavRecorder.onBuffer = { rms, frameCount ->
            val capturedGeneration = sessionGeneration
            mainHandler.post { handleVoiceActivityOnMain(rms, frameCount, capturedGeneration) }
        }
    }

    // endregion

    // region startSession / stopSession / cancelSession

    private fun startSession(call: MethodCall, result: MethodChannel.Result) {
        val promptId = call.argument<String>("promptId")
        if (promptId.isNullOrEmpty()) {
            result.error("invalidArguments", "Missing promptId", null)
            return
        }
        val locale = call.argument<String>("locale") ?: "en-US"

        if (!isEngineReady) {
            warmup(object : MethodChannel.Result {
                override fun success(r: Any?) {
                    doStartSession(promptId, result)
                }
                override fun error(code: String, msg: String?, details: Any?) {
                    result.error(code, msg, details)
                }
                override fun notImplemented() {}
            })
            return
        }

        doStartSession(promptId, result)
    }

    private fun doStartSession(promptId: String, result: MethodChannel.Result) {
        resetSentenceState(promptId)

        val fileName = sanitizeFileName(promptId)
        val file = File(activity.cacheDir, "$fileName-${System.currentTimeMillis()}.wav")
        currentFilePath = file.absolutePath
        val capturedGeneration = sessionGeneration
        val hasPermission = microphonePermissionStatus() == "granted"
        isRecording = true

        runOnAudioIo {
            stopWavRecorderQuietly()
            if (sessionGeneration != capturedGeneration) return@runOnAudioIo
            wavRecorder.resetCaptureDiagnostics()
            // 延迟初始化 AudioRecord（权限可能在 warmup 之后才授予）。
            if (!wavRecorder.isInitialized && hasPermission) initWavRecorder()
            if (wavRecorder.isInitialized && sessionGeneration == capturedGeneration) {
                try {
                    wavRecorder.startRecording(file.absolutePath)
                } catch (e: Exception) {
                    Log.w(TAG, "WavRecorder.startRecording failed", e)
                }
            }
        }

        result.success(mapOf("filePath" to file.absolutePath))
    }

    private fun stopSession(result: MethodChannel.Result) {
        isRecording = false
        val promptId = currentPromptId ?: ""
        val fallbackPath = currentFilePath
        val vadDescription = vadThreshold.describe()
        val shouldEmitFinal = !finalTranscriptEmitted
        if (shouldEmitFinal) {
            finalTranscriptEmitted = true
        }

        val scheduled = runOnAudioIo {
            val filePath = if (wavRecorder.isInitialized) {
                wavRecorder.stopRecording() ?: fallbackPath
            } else {
                fallbackPath
            }
            val wavBeforeTrim = filePath?.let(wavRecorder::wavFileMetrics)
            // 裁剪首尾静音（对齐 iOS/macOS），在单线程串口 IO 执行器上完成避免卡顿主线程。
            if (!filePath.isNullOrEmpty()) {
                wavRecorder.trimSilence(filePath)
            }
            val wavAfterTrim = filePath?.let(wavRecorder::wavFileMetrics)
            val captureDiagnostics = wavRecorder.captureDiagnostics()

            mainHandler.post {
                val diagnostics = buildString {
                    append(captureDiagnostics)
                    append(" $vadDescription")
                    append(" wavBeforeTrim=$wavBeforeTrim")
                    append(" wavAfterTrim=$wavAfterTrim")
                }

                // 确保 Dart 侧总能收到 finalTranscriptReady，避免等超时。
                if (shouldEmitFinal && !isDisposed) {
                    emitEvent(mapOf(
                        "type" to "finalTranscriptReady",
                        "promptId" to promptId,
                        "transcript" to "",
                    ))
                }

                result.success(
                    mapOf(
                        "filePath" to (filePath ?: ""),
                        "diagnostics" to diagnostics,
                    ),
                )
            }
        }

        if (!scheduled) {
            if (shouldEmitFinal && !isDisposed) {
                emitEvent(mapOf(
                    "type" to "finalTranscriptReady",
                    "promptId" to promptId,
                    "transcript" to "",
                ))
            }
            result.success(
                mapOf(
                    "filePath" to (fallbackPath ?: ""),
                    "diagnostics" to vadDescription,
                ),
            )
        }
    }

    private fun cancelSession(result: MethodChannel.Result) {
        isRecording = false
        sessionGeneration++
        resetMainSentenceState()
        if (!runOnAudioIo {
                stopWavRecorderQuietly()
                mainHandler.post { result.success(emptyMap<String, Any>()) }
            }) {
            result.success(emptyMap<String, Any>())
        }
    }

    // endregion

    // region deleteRecording

    private fun deleteRecording(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath")
        if (!filePath.isNullOrEmpty()) {
            if (!runOnAudioIo {
                    try { File(filePath).delete() } catch (_: Exception) {}
                }) {
                try { File(filePath).delete() } catch (_: Exception) {}
            }
        }
        if (currentFilePath == filePath) {
            currentFilePath = null
        }
        result.success(emptyMap<String, Any>())
    }

    // endregion

    // region VAD

    /** 仅在主线程执行，避免与 resetSentenceState/stopSession 并发读写非同步字段。 */
    private fun handleVoiceActivityOnMain(
        rms: Float,
        frameCount: Int,
        capturedGeneration: Int,
    ) {
        if (isDisposed || !isRecording || sessionGeneration != capturedGeneration) return
        val promptId = currentPromptId ?: return

        val bufferDurationMs = (frameCount.toDouble() / 16000.0) * 1000.0
        val bufferStartMs = recordedDurationMs
        val bufferEndMs = bufferStartMs + bufferDurationMs

        if (vadThreshold.isVoiced(rms)) {
            if (!hasDetectedSpeech) {
                hasDetectedSpeech = true
                emitEvent(mapOf("type" to "speechStarted", "promptId" to promptId))
            }
            if (firstDetectedSpeechMs == null) firstDetectedSpeechMs = bufferStartMs
            lastDetectedSpeechMs = bufferEndMs

            if (silenceStartAt > 0 || lastReportedSilenceMs > 0) {
                emitEvent(mapOf(
                    "type" to "silenceProgress",
                    "promptId" to promptId,
                    "silenceMs" to 0,
                ))
            }
            silenceStartAt = 0L
            lastReportedSilenceMs = 0
            recordedDurationMs = bufferEndMs
            return
        }

        recordedDurationMs = bufferEndMs
        if (!hasDetectedSpeech) return

        val now = System.currentTimeMillis()
        if (silenceStartAt == 0L) silenceStartAt = now
        val silenceMs = (now - silenceStartAt).toInt()
        if (silenceMs == 0 || silenceMs - lastReportedSilenceMs >= 200) {
            lastReportedSilenceMs = silenceMs
            emitEvent(mapOf(
                "type" to "silenceProgress",
                "promptId" to promptId,
                "silenceMs" to silenceMs,
            ))
        }
    }

    // endregion

    // region 内部工具

    private fun runOnAudioIo(task: () -> Unit): Boolean {
        if (isDisposed || audioIoExecutor.isShutdown) return false
        return try {
            audioIoExecutor.execute(task)
            true
        } catch (_: RejectedExecutionException) {
            false
        }
    }

    private fun stopWavRecorderQuietly() {
        if (wavRecorder.isInitialized) {
            try { wavRecorder.stopRecording() } catch (_: Exception) {}
        }
    }

    private fun resetSentenceState(promptId: String) {
        sessionGeneration++
        resetMainSentenceState()
        currentPromptId = promptId
    }

    private fun resetMainSentenceState() {
        currentPromptId = null
        currentFilePath = null
        finalTranscriptEmitted = false
        hasDetectedSpeech = false
        silenceStartAt = 0L
        lastReportedSilenceMs = -1
        recordedDurationMs = 0.0
        firstDetectedSpeechMs = null
        lastDetectedSpeechMs = null
        vadThreshold.reset()
    }

    private fun emitEvent(event: Map<String, Any>) {
        if (isDisposed) return
        if (Looper.myLooper() == Looper.getMainLooper()) {
            eventSink?.success(event)
        } else {
            mainHandler.post {
                if (!isDisposed) eventSink?.success(event)
            }
        }
    }

    private fun sanitizeFileName(promptId: String): String {
        return promptId.replace(Regex("[^a-zA-Z0-9\\-_]"), "-")
    }

    // endregion

    /** 页面退出时由 MainActivity 调用。 */
    fun dispose() {
        isRecording = false
        sessionGeneration++
        resetMainSentenceState()
        isEngineReady = false
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        runOnAudioIo {
            stopWavRecorderQuietly()
            wavRecorder.release()
        }
        isDisposed = true
        audioIoExecutor.shutdown()
    }
}
