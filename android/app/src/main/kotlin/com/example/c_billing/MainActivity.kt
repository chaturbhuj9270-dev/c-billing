package com.example.c_billing

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
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
                    result.success(sendToWhatsAppChat(phone, path, message, mime))
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
        mime: String
    ): Boolean {
        if (phone.isEmpty()) return false
        val file = File(path)
        if (!file.exists()) return false
        val uri = try {
            FileProvider.getUriForFile(this, "$packageName.billing_fileprovider", file)
        } catch (e: IllegalArgumentException) {
            return false
        }

        for (pkg in listOf("com.whatsapp", "com.whatsapp.w4b")) {
            if (!isInstalled(pkg)) continue
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mime
                setPackage(pkg)
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_TEXT, message)
                putExtra("jid", "$phone@s.whatsapp.net")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            try {
                startActivity(intent)
                return true
            } catch (e: ActivityNotFoundException) {
                // try the next WhatsApp package
            }
        }
        return false
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
    }
}

// Own FileProvider class so it never clashes with the share plugin's provider.
class BillingFileProvider : FileProvider()
