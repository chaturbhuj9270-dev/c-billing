package com.cbilling.app

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ClipDescription
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHATSAPP_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "sendFile") {
                    val phone = call.argument<String>("phone") ?: ""
                    val path = call.argument<String>("path") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    val mime = call.argument<String>("mime") ?: "application/pdf"
                    val chatFirst = call.argument<Boolean>("chatFirst") ?: false
                    result.success(
                        sendToWhatsAppChat(phone, path, message, mime, chatFirst)
                    )
                } else {
                    result.notImplemented()
                }
            }
    }

    // Opens the customer's WhatsApp chat with the file attached and the message
    // as its caption. The user only has to press Send. Returns false when this
    // is not possible so Dart can fall back to the normal share sheet.
    private fun sendToWhatsAppChat(
        phone: String,
        path: String,
        message: String,
        mime: String,
        chatFirst: Boolean = false
    ): Boolean {
        if (phone.isEmpty()) return false
        val file = File(path)
        if (!file.exists()) return false
        val uri = shareableUri(file) ?: return false

        val jid = "$phone@s.whatsapp.net"
        for (pkg in listOf("com.whatsapp", "com.whatsapp.w4b")) {
            if (!isInstalled(pkg)) continue
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mime
                setPackage(pkg)
                putExtra(Intent.EXTRA_STREAM, uri)
                if (message.isNotEmpty()) putExtra(Intent.EXTRA_TEXT, message)
                putExtra("jid", jid)
                // WhatsApp's direct-share shortcut for a chat uses the jid as id.
                putExtra(EXTRA_SHORTCUT_ID, jid)
                // WhatsApp's document preview takes its caption from the ClipData
                // item, so it must carry the text as well as the file.
                clipData = ClipData(
                    ClipDescription("report", arrayOf(mime)),
                    ClipData.Item(message.ifEmpty { null }, null, null, uri)
                )
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            try {
                if (chatFirst && message.isNotEmpty()) {
                    // WhatsApp drops the caption of a shared PDF, so the message
                    // goes in as the chat's draft: the chat (with the message
                    // typed in) is opened first and the PDF preview is stacked
                    // on top. After the PDF is sent the user lands in the same
                    // chat with the message waiting in the box.
                    val chat = Intent(
                        Intent.ACTION_VIEW,
                        Uri.parse("https://wa.me/$phone?text=${Uri.encode(message)}")
                    ).apply { setPackage(pkg) }
                    // Last intent ends up on top: the chat link is started last so
                    // its message is typed in before the PDF preview opens.
                    startActivities(arrayOf(intent, chat))
                    Log.d(TAG, "Opened $pkg chat $jid with message + PDF")
                } else {
                    startActivity(intent)
                    Log.d(TAG, "Shared $mime to $pkg chat $jid")
                }
                return true
            } catch (e: ActivityNotFoundException) {
                Log.w(TAG, "$pkg cannot receive the share", e)
            }
        }
        Log.w(TAG, "WhatsApp not available for direct share")
        return false
    }

    // Content URI WhatsApp can read. Dart's temp folder is the app's code_cache,
    // which FileProvider cannot share, so files outside the shared folders are
    // copied into cache first (otherwise the direct chat share silently failed
    // and the generic share sheet appeared instead).
    private fun shareableUri(file: File): Uri? {
        val authority = "$packageName.billing_fileprovider"
        try {
            return FileProvider.getUriForFile(this, authority, file)
        } catch (e: IllegalArgumentException) {
            Log.d(TAG, "${file.path} is outside the shared folders, copying")
        }
        return try {
            val dir = File(cacheDir, "whatsapp_share").apply { mkdirs() }
            val copy = File(dir, file.name)
            file.copyTo(copy, overwrite = true)
            FileProvider.getUriForFile(this, authority, copy)
        } catch (e: Exception) {
            Log.w(TAG, "Could not prepare ${file.path} for sharing", e)
            null
        }
    }

    private fun isInstalled(pkg: String): Boolean {
        return try {
            packageManager.getPackageInfo(pkg, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    companion object {
        private const val WHATSAPP_CHANNEL = "c_billing/whatsapp"
        private const val TAG = "WhatsAppShare"
        private const val EXTRA_SHORTCUT_ID = "android.intent.extra.shortcut.ID"
    }
}

// Own FileProvider class so it never clashes with the share plugin's provider.
class BillingFileProvider : FileProvider()
