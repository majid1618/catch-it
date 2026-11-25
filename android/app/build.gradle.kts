import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin now handles Kotlin when android.builtInKotlin=true
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.majid.catch_it"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.majid.catch_it"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(keystorePropertiesFile.inputStream())
    }

    signingConfigs {
        getByName("debug") {
            val home = System.getProperty("user.home")
            val debugKeystore = file("$home/.android/debug.keystore")
            if (debugKeystore.exists()) {
                storeFile = debugKeystore
            }
        }
        create("release") {
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            if (storeFilePath != null) {
                storeFile = file(storeFilePath)
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    applicationVariants.configureEach {
        val variant = this
        variant.outputs.configureEach {
            val abi = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            abi.outputFileName = "catch_it-${variant.buildType.name}.apk"
        }
    }
}

flutter {
    source = "../.."
}
