plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val oheyAndroidKeystorePath =
    (project.findProperty("OHEY_ANDROID_KEYSTORE_PATH") as String?)
        ?: System.getenv("OHEY_ANDROID_KEYSTORE_PATH")
val oheyAndroidKeystorePassword =
    (project.findProperty("OHEY_ANDROID_KEYSTORE_PASSWORD") as String?)
        ?: System.getenv("OHEY_ANDROID_KEYSTORE_PASSWORD")
val oheyAndroidKeyAlias =
    (project.findProperty("OHEY_ANDROID_KEY_ALIAS") as String?)
        ?: System.getenv("OHEY_ANDROID_KEY_ALIAS")
val oheyAndroidKeyPassword =
    (project.findProperty("OHEY_ANDROID_KEY_PASSWORD") as String?)
        ?: System.getenv("OHEY_ANDROID_KEY_PASSWORD")
val hasOheyAndroidReleaseSigning =
    !oheyAndroidKeystorePath.isNullOrBlank() &&
        !oheyAndroidKeystorePassword.isNullOrBlank() &&
        !oheyAndroidKeyAlias.isNullOrBlank() &&
        !oheyAndroidKeyPassword.isNullOrBlank()

android {
    namespace = "app.ohey.com"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "app.ohey.com"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["adMobApplicationId"] = "ca-app-pub-3940256099942544~3347511713"
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Ohey Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Ohey")
            manifestPlaceholders["adMobApplicationId"] =
                (project.findProperty("OHEY_ADMOB_ANDROID_APP_ID") as String?) ?: ""
        }
    }

    signingConfigs {
        if (hasOheyAndroidReleaseSigning) {
            create("oheyRelease") {
                storeFile = file(oheyAndroidKeystorePath!!)
                storePassword = oheyAndroidKeystorePassword!!
                keyAlias = oheyAndroidKeyAlias!!
                keyPassword = oheyAndroidKeyPassword!!
            }
        }
    }

    buildTypes {
        release {
            if (hasOheyAndroidReleaseSigning) {
                signingConfig = signingConfigs.getByName("oheyRelease")
            }
        }
    }
}

gradle.taskGraph.whenReady {
    val buildsProdRelease = allTasks.any { task ->
        task.name.equals("assembleProdRelease", ignoreCase = true) ||
            task.name.equals("bundleProdRelease", ignoreCase = true)
    }
    if (buildsProdRelease && !hasOheyAndroidReleaseSigning) {
        throw GradleException(
            "Prod Android release builds require OHEY_ANDROID_KEYSTORE_PATH, " +
                "OHEY_ANDROID_KEYSTORE_PASSWORD, OHEY_ANDROID_KEY_ALIAS, and " +
                "OHEY_ANDROID_KEY_PASSWORD. Refusing to sign prod with debug keys."
        )
    }
}

flutter {
    source = "../.."
}
