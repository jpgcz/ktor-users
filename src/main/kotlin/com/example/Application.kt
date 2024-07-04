package com.example

import com.example.api.UserRepository
import com.example.api.UserService
import com.example.api.UserValidator
import com.example.routes.userRouting
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import io.ktor.server.plugins.contentnegotiation.*
import io.ktor.server.routing.*

fun main() {
    embeddedServer(Netty, port = 8080, host = "0.0.0.0", module = Application::module)
        .start(wait = true)
}

fun Application.module() {
    val userRepository = UserRepository()
    val userService = UserService(userRepository)
    val userValidator = UserValidator()

    install(ContentNegotiation) {
        json()
    }

    routing { userRouting(userService, userValidator) }
}
