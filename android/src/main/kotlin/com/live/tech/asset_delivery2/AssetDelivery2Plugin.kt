package com.live.tech.asset_delivery2

import android.content.Context
import android.content.res.AssetManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class AssetDelivery2Plugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private val mainScope = CoroutineScope(Dispatchers.Main)

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "asset_delivery2")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "initialize") {
      mainScope.launch {
        try {
          val basePath = withContext(Dispatchers.IO) {
            extractAssetsToCache()
          }
          result.success(basePath)
        } catch (e: Exception) {
          result.error("INIT_ERROR", "Failed to extract assets: ${e.localizedMessage}", null)
        }
      }
    } else {
      result.notImplemented()
    }
  }

  private fun extractAssetsToCache(): String {
    val cacheDir = context.cacheDir
    val targetRootDir = File(cacheDir, "fun_play_assets")
    
    // Create the root directory
    if (!targetRootDir.exists()) targetRootDir.mkdirs()

    // If directory exists and has files, assume already extracted.
    if (targetRootDir.listFiles()?.isNotEmpty() == true) {
        return targetRootDir.absolutePath
    }

    val assets = context.assets
    
    // Start recursive copy from root
    copyAssetFolder(assets, "", targetRootDir)

    return targetRootDir.absolutePath
  }

  private fun copyAssetFolder(assetManager: AssetManager, fromPath: String, toDir: File) {
    try {
      val files = assetManager.list(fromPath) ?: emptyArray()

      if (files.isEmpty()) {
        return
      } 

      if (!toDir.exists()) toDir.mkdirs()

      for (file in files) {
        // SKIP FLUTTER INTERNAL ASSETS
        if (fromPath == "" && (file == "flutter_assets" || file == "fonts" || file == "webkit")) {
          continue
        }
        
        val nextFromPath = if (fromPath == "") file else "$fromPath/$file"
        val nextToDir = File(toDir, file)
        
        // If it has an extension, treat as file. 
        // If not, treat as directory.
        if (file.contains(".")) {
           copyAssetFile(assetManager, nextFromPath, nextToDir)
        } else {
           copyAssetFolder(assetManager, nextFromPath, nextToDir)
        }
      }
    } catch (e: IOException) {
      e.printStackTrace()
    }
  }

  private fun copyAssetFile(assetManager: AssetManager, assetPath: String, destinationFile: File) {
    try {
        val inputStream = assetManager.open(assetPath)
        
        if (destinationFile.parentFile?.exists() == false) {
            destinationFile.parentFile?.mkdirs()
        }

        FileOutputStream(destinationFile).use { out ->
            inputStream.copyTo(out)
        }
        inputStream.close()
    } catch (e: IOException) {
        // If open() fails, it might be a directory that looked like a file.
        // We ignore it to prevent crashing the extraction.
        // Log.e("FunPlay", "Failed to copy $assetPath")
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}