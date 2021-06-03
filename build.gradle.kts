import org.jetbrains.kotlin.gradle.targets.js.webpack.KotlinWebpack

plugins {
    kotlin("multiplatform") version "1.4.32"
    id("org.springframework.boot") version "2.5.0"
    id("io.spring.dependency-management") version "1.0.11.RELEASE"
    kotlin("plugin.spring") version "1.5.10"
    application
}

group = "org.seedcompany"
version = "4.0-SNAPSHOT"


repositories {
    jcenter()
    mavenCentral()
    maven { url = uri("https://maven.pkg.jetbrains.space/public/p/kotlin/p/kotlin/kotlin-js-wrappers") }
}


kotlin {
    jvm("api") {
        compilations.all {
            kotlinOptions.jvmTarget = "1.8"
        }
        testRuns["test"].executionTask.configure {
            useJUnitPlatform()
        }
        withJava()
    }
    js("frontend", IR) {
        binaries.executable()
        browser {
            commonWebpackConfig {
                cssSupport.enabled = true
            }
        }
    }
    sourceSets {
        val commonMain by getting
        val commonTest by getting {
            dependencies {
                implementation(kotlin("test-common"))
                implementation(kotlin("test-annotations-common"))
            }
        }
        val apiMain by getting {
            dependencies {
                implementation("org.neo4j.driver:neo4j-java-driver:4.2.5")
                implementation("org.springframework.boot:spring-boot-starter-web")
                implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
                implementation("org.jetbrains.kotlin:kotlin-reflect")
                implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
                runtimeOnly("org.postgresql:postgresql:42.2.20")
            }
        }
        val apiTest by getting {
            dependencies {
                implementation("org.springframework.boot:spring-boot-starter-test")
            }
        }
        val frontendMain by getting {
            dependencies {
                implementation("org.jetbrains:kotlin-react:16.13.1-pre.113-kotlin-1.4.0")
                implementation("org.jetbrains:kotlin-react-dom:16.13.1-pre.113-kotlin-1.4.0")
                implementation("org.jetbrains:kotlin-styled:1.0.0-pre.113-kotlin-1.4.0")
                implementation("org.jetbrains:kotlin-react-router-dom:5.1.2-pre.113-kotlin-1.4.0")
            }
        }
        val frontendTest by getting {
            dependencies {
                implementation(kotlin("test-js"))
            }
        }
    }
}

application {
//    mainClassName = "ServerKt"
}

tasks.getByName<KotlinWebpack>("frontendBrowserProductionWebpack") {
    outputFileName = "frontend.js"
}

tasks.getByName<Jar>("apiJar") {
    dependsOn(tasks.getByName("frontendBrowserProductionWebpack"))
    val frontendBrowserProductionWebpack = tasks.getByName<KotlinWebpack>("frontendBrowserProductionWebpack")
    from(File(frontendBrowserProductionWebpack.destinationDirectory, frontendBrowserProductionWebpack.outputFileName))
}

tasks.getByName<JavaExec>("run") {
    dependsOn(tasks.getByName<Jar>("apiJar"))
    classpath(tasks.getByName<Jar>("apiJar"))
}