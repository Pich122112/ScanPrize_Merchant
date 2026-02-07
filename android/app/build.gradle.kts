import java.util.Properties
import java.io.FileInputStream


val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// Add above

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // <-- Correct way in .kts add this
    id("org.jetbrains.kotlin.android") //add this
}

android {
    namespace = "com.ganzberg.scanprizemerchantapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"


    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // <-- Add this line! add this

    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.ganzberg.scanprizemerchantapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion  //add this
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // buildTypes {
    //     release {
    //         // TODO: Add your own signing config for the release build.
    //         // Signing with the debug keys for now, so `flutter run --release` works.
    //         signingConfig = signingConfigs.getByName("debug")
    //     }
    // }

    buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.create("release").apply {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
        // ✅ Enable obfuscation
        isMinifyEnabled = false
        isShrinkResources = false

         proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
        )
    }
}

}

flutter {
    source = "../.."
}

//add this
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.android.gms:play-services-auth-api-phone:18.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

