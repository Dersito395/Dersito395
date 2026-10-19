import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Assinatura de release: crie android/key.properties (fora do git) com
// storeFile, storePassword, keyAlias e keyPassword. Veja docs/PUBLICACAO.md.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "br.app.sobreviva.sobreviva"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.app.sobreviva.sobreviva"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Chave APENAS para APKs de teste (pública no repositório). Mantém a mesma assinatura
        // entre builds, para que cada APK de teste instale por cima do anterior.
        // Nunca publique nas lojas com ela: use key.properties (veja docs/PUBLICACAO.md).
        create("teste") {
            storeFile = file("chave-teste-apenas.p12")
            storePassword = "sobreviva-teste"
            keyAlias = "teste"
            keyPassword = "sobreviva-teste"
        }
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Sem key.properties, assina com a chave de teste (APKs de teste, nunca para as lojas).
            signingConfig = if (keystoreProperties.isNotEmpty()) signingConfigs.getByName("release") else signingConfigs.getByName("teste")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
