import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// تحميل بيانات التوقيع من key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "j.food.com.jfood"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "j.food.com.jfood"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // أنشئ توقيع release من key.properties
        create("release") {
            val alias = keystoreProperties.getProperty("keyAlias")
            val keyPwd = keystoreProperties.getProperty("keyPassword")
            val storePwd = keystoreProperties.getProperty("storePassword")
            val storePath = keystoreProperties.getProperty("storeFile") // مثال: D:\\keys\\upload-key.jks

            if (storePath != null && alias != null && keyPwd != null && storePwd != null) {
                storeFile = File(storePath)
                keyAlias = alias
                keyPassword = keyPwd
                storePassword = storePwd
            } else {
                // لو الملف غير موجود أو القيم ناقصة، لا تضع توقيع لتتجنب أخطاء وقت البناء
                println("WARNING: key.properties is missing or incomplete. Release will not be signed.")
            }
        }
    }

    buildTypes {
        release {
            // استخدم توقيع release الحقيقي (وليس debug)
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            // يبقى كما هو
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
