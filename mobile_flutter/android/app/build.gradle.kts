import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}

fun signingProperty(propertyName: String, envName: String): String? {
    val fileValue = keystoreProperties.getProperty(propertyName)?.trim()
    if (!fileValue.isNullOrEmpty()) {
        return fileValue
    }
    val envValue = System.getenv(envName)?.trim()
    return envValue?.takeIf { it.isNotEmpty() }
}

val releaseStoreFile = signingProperty("storeFile", "BETAUP_ANDROID_STORE_FILE")
val releaseStorePassword = signingProperty("storePassword", "BETAUP_ANDROID_STORE_PASSWORD")
val releaseKeyAlias = signingProperty("keyAlias", "BETAUP_ANDROID_KEY_ALIAS")
val releaseKeyPassword = signingProperty("keyPassword", "BETAUP_ANDROID_KEY_PASSWORD")
val hasReleaseSigning =
    !releaseStoreFile.isNullOrEmpty() &&
    !releaseStorePassword.isNullOrEmpty() &&
    !releaseKeyAlias.isNullOrEmpty() &&
    !releaseKeyPassword.isNullOrEmpty()

android {
    namespace = "com.betaup.betaup_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.betaup.betaup_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseSigning) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.fromTarget(JavaVersion.VERSION_17.toString())
    }
}

flutter {
    source = "../.."
}
