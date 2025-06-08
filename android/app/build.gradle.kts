plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.rally_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Especifica tu Application ID único
        applicationId = "com.example.rally_app"
        minSdk = 21 // Android 5.0 (Lollipop) como mínimo
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Habilitar multidex si tu app usa muchas dependencias
        multiDexEnabled = true
    }

    signingConfigs {
        // Configuración de firma para release (descomenta y configura para producción)
        create("release") {
            keyAlias = "key"
            keyPassword = "123456"
            storeFile = file("../key.jks") // Ruta a tu archivo .jks
            storePassword = "123456"
        }
    }

    buildTypes {
        release {
            // Usa la configuración de firma para release
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            // Optimizar el tamaño del APK
            minifyEnabled = true
            shrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Mantener la firma de depuración para pruebas
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Configuración de recursos y compatibilidad
    aaptOptions {
        // Ignorar recursos no utilizados para reducir el tamaño
        ignoreAssetsPattern = "!*.txt:!*.xml:!*.json"
    }
}

flutter {
    source = "../.."
}

// Dependencias adicionales
dependencies {
    implementation("androidx.multidex:multidex:2.0.1") // Para soportar multidex
}