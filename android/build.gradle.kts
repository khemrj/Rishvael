import org.jetbrains.kotlin.gradle.dsl.JvmTarget

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Toolchain approach — declares ONE JDK for the whole build.
// Every subproject (your app AND every plugin, including
// flutter_image_compress_lite) inherits this automatically,
// regardless of what each plugin's own build.gradle specifies
// internally. This is the mechanism Gradle's suggestion refers to.
subprojects {
    afterEvaluate {
        extensions.findByType<org.gradle.api.plugins.JavaPluginExtension>()
            ?.toolchain {
                languageVersion.set(JavaLanguageVersion.of(17))
            }

        extensions.findByType<org.jetbrains.kotlin.gradle.dsl.KotlinProjectExtension>()
            ?.jvmToolchain(17)
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}