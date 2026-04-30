package com.example.posefit_ai

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker

import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "posefit_ai/pose_landmarker"
    private var poseLandmarker: PoseLandmarker? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "initializePoseLandmarker" -> {
                    try {
                        initializePoseLandmarker()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("INIT_FAILED", e.message, null)
                    }
                }

                "detectPoseFromImage" -> {
                    try {
                        val imagePath = call.argument<String>("imagePath")

                        if (imagePath.isNullOrEmpty()) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "imagePath is required",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val detectionResult = detectPoseFromImage(imagePath)
                        result.success(detectionResult)
                    } catch (e: Exception) {
                        result.error("DETECTION_FAILED", e.message, null)
                    }
                }

                "detectPoseFromFrame" -> {
                    try {
                        val planes = call.argument<List<ByteArray>>("planes")
                        val bytesPerRow = call.argument<List<Int>>("bytesPerRow")
                        val bytesPerPixel = call.argument<List<Int?>>("bytesPerPixel")
                        val width = call.argument<Int>("width")
                        val height = call.argument<Int>("height")
                        val rotation = call.argument<Int>("rotation")

                        if (
                            planes == null || bytesPerRow == null || bytesPerPixel == null ||
                            width == null || height == null || rotation == null
                        ) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "Missing frame arguments",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val detectionResult = detectPoseFromFrame(
                            planes = planes,
                            bytesPerRow = bytesPerRow,
                            bytesPerPixel = bytesPerPixel,
                            width = width,
                            height = height,
                            rotation = rotation
                        )
                        result.success(detectionResult)
                    } catch (e: Exception) {
                        result.error("FRAME_DETECTION_FAILED", e.message, null)
                    }
                }

                "disposePoseLandmarker" -> {
                    disposePoseLandmarker()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun initializePoseLandmarker() {
        if (poseLandmarker != null) return

        val modelName = "pose_landmarker_lite.task"

        assets.open(modelName).close()

        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(modelName)
            .build()

        val options = PoseLandmarker.PoseLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.IMAGE)
            .setNumPoses(1)
            .setMinPoseDetectionConfidence(0.5f)
            .setMinPosePresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .build()

        poseLandmarker = PoseLandmarker.createFromOptions(this, options)
    }

    private fun detectPoseFromImage(imagePath: String): Map<String, Any> {
        if (poseLandmarker == null) {
            initializePoseLandmarker()
        }

        val bitmap = BitmapFactory.decodeFile(imagePath)
            ?: throw IllegalArgumentException("Could not decode image from path: $imagePath")

        return runDetection(bitmap)
    }

    private fun detectPoseFromFrame(
        planes: List<ByteArray>,
        bytesPerRow: List<Int>,
        bytesPerPixel: List<Int?>,
        width: Int,
        height: Int,
        rotation: Int
    ): Map<String, Any> {
        if (poseLandmarker == null) {
            initializePoseLandmarker()
        }

        val bitmap = yuv420ToBitmap(
            planes = planes,
            bytesPerRow = bytesPerRow,
            bytesPerPixel = bytesPerPixel,
            width = width,
            height = height
        )

        val rotatedBitmap = rotateBitmap(bitmap, rotation.toFloat())
        return runDetection(rotatedBitmap)
    }

    private fun runDetection(bitmap: Bitmap): Map<String, Any> {
        val mpImage = BitmapImageBuilder(bitmap).build()
        val result = poseLandmarker!!.detect(mpImage)

        val allPoses = result.landmarks()

        if (allPoses.isEmpty()) {
            return mapOf(
                "poseDetected" to false,
                "landmarks" to emptyList<Map<String, Any>>()
            )
        }

        val firstPose = allPoses[0]
        val landmarks = firstPose.mapIndexed { index, landmark ->
            mapOf(
                "index" to index,
                "x" to landmark.x(),
                "y" to landmark.y(),
                "z" to landmark.z()
            )
        }

        return mapOf(
            "poseDetected" to true,
            "landmarks" to landmarks
        )
    }

    private fun yuv420ToBitmap(
        planes: List<ByteArray>,
        bytesPerRow: List<Int>,
        bytesPerPixel: List<Int?>,
        width: Int,
        height: Int
    ): Bitmap {
        val yPlane = planes[0]
        val uPlane = planes[1]
        val vPlane = planes[2]

        val yRowStride = bytesPerRow[0]
        val uRowStride = bytesPerRow[1]
        val vRowStride = bytesPerRow[2]

        val uPixelStride = bytesPerPixel[1] ?: 1
        val vPixelStride = bytesPerPixel[2] ?: 1

        val nv21 = ByteArray(width * height + 2 * (width / 2) * (height / 2))

        var index = 0

        for (row in 0 until height) {
            val rowStart = row * yRowStride
            System.arraycopy(yPlane, rowStart, nv21, index, width)
            index += width
        }

        val chromaHeight = height / 2
        val chromaWidth = width / 2

        for (row in 0 until chromaHeight) {
            val uRowStart = row * uRowStride
            val vRowStart = row * vRowStride

            for (col in 0 until chromaWidth) {
                val uIndex = uRowStart + col * uPixelStride
                val vIndex = vRowStart + col * vPixelStride

                nv21[index++] = vPlane[vIndex]
                nv21[index++] = uPlane[uIndex]
            }
        }

        val yuvImage = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, width, height), 90, out)
        val jpegBytes = out.toByteArray()

        return BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)
            ?: throw IllegalStateException("Failed to decode bitmap from frame")
    }

    private fun rotateBitmap(bitmap: Bitmap, rotationDegrees: Float): Bitmap {
        if (rotationDegrees == 0f) return bitmap

        val matrix = Matrix().apply {
            postRotate(rotationDegrees)
        }

        return Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true
        )
    }

    private fun disposePoseLandmarker() {
        poseLandmarker?.close()
        poseLandmarker = null
    }

    override fun onDestroy() {
        disposePoseLandmarker()
        super.onDestroy()
    }
}