import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    packaging {
        resources {
            excludes += "META-INF/*"
        }
    }
    namespace = "co.puntoya.cajarapida"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "co.puntoya.cajarapida"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Lee credenciales del keystore desde android/key.properties (gitignored).
    // Si el archivo no existe o está incompleto, se usa el signing de debug
    // para que `flutter run --release` siga funcionando durante desarrollo.
    val keystoreProperties = Properties().apply {
        val keyPropsFile = rootProject.file("key.properties")
        if (keyPropsFile.exists()) {
            keyPropsFile.inputStream().use { load(it) }
        }
    }

    signingConfigs {
        // Solo habilita release signing cuando TODOS los campos requeridos
        // están rellenos en key.properties. Si falta cualquiera, mantiene
        // el fallback a debug para no romper el build.
        val requiredKeys = listOf(
            "storeFile",
            "keyAlias",
            "keyPassword",
            "storePassword",
        )
        val hasAllKeys = requiredKeys.all {
            keystoreProperties.getProperty(it)?.isNotEmpty() == true
        }
        if (hasAllKeys) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (signingConfigs.findByName("release") != null) {
                signingConfigs.getByName("release")
            } else {
                // Fallback: firma con debug.keystore mientras no se configure key.properties.
                signingConfigs.getByName("debug")
            }
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