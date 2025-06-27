plugins {
    kotlin("jvm") version "1.8.22"
    kotlin("plugin.serialization") version "1.9.0"
    application
}

group = "com.example"
version = "1.0-SNAPSHOT"

application {
    mainClass.set("com.example.ApplicationKt")
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("io.ktor:ktor-server-core-jvm:2.3.4")
    implementation("io.ktor:ktor-server-netty-jvm:2.3.4")
    implementation("io.ktor:ktor-server-content-negotiation:2.3.4")
    implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.4")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.5.1")

    // Añadir dependencias de logging
    implementation("ch.qos.logback:logback-classic:1.2.11")
    implementation("org.slf4j:slf4j-api:1.7.36")

    testImplementation("io.ktor:ktor-server-tests-jvm:2.3.4")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit:1.8.22")
    testImplementation("io.ktor:ktor-server-test-host-jvm:2.3.4")
    testImplementation("org.mockito:mockito-core:5.3.1")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.0.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
}

tasks.withType<Test> {
    useJUnit()
}

val acceptanceTest by tasks.registering(Test::class) {
    description = "Runs acceptance tests."
    group = "verification"
    
    testClassesDirs = sourceSets["test"].output.classesDirs
    classpath = sourceSets["test"].runtimeClasspath
    
    filter {
        includeTestsMatching("*AcceptanceTest")
    }
    
    systemProperty("test.env", project.findProperty("env") ?: "dev")
}


kotlin {
    jvmToolchain {
        languageVersion.set(JavaLanguageVersion.of(17)) //Aquí especifiqué esta versión porque usamos una librería deprecada y cambiamos a otra
    }
}