plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") 
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.example.teletracker"
    compileSdk = 35 // Changed from 35 to 34 (latest stable)
    ndkVersion = "27.0.12077973"  // Updated to a stable version

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.teletracker"
        multiDexEnabled = true
        minSdk = 21  // Explicitly set instead of using flutter.minSdkVersion
        targetSdk = 34  // Explicitly set instead of using flutter.targetSdkVersion
        versionCode = 1  // Explicitly set instead of using flutter.versionCode
        versionName = "1.0.0"  // Explicitly set instead of using flutter.versionName
    }

    buildTypes {
        release {
            // Using debug signing config is not recommended for production
            // Consider setting up a proper signing config
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            configure<com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension> {
                mappingFileUploadEnabled = false
            }
        }
    }

    lint {
        disable += "InvalidPackage"
        checkReleaseBuilds = false
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
    
    // Firebase dependencies - using non-ktx versions to avoid Kotlin compatibility issues
    implementation(platform("com.google.firebase:firebase-bom:32.5.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-messaging")
    
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}