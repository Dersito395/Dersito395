package br.app.sobreviva.sobreviva

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Espaço livre para o gerenciador de pacotes de conteúdo.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "br.app.sobreviva/storage").setMethodCallHandler { call, result ->
            when (call.method) {
                "freeBytes" -> result.success(StatFs(filesDir.absolutePath).availableBytes)
                else -> result.notImplemented()
            }
        }
    }
}
