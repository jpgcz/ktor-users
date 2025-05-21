package com.example.routes

import com.example.api.UserService
import com.example.api.UserValidator
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.application.*
import io.ktor.server.plugins.contentnegotiation.*
import io.ktor.server.routing.*

fun Application.testModule(userService: UserService, userValidator: UserValidator) {
    install(ContentNegotiation) {
        json()
    }
    
    routing { 
        userRouting(userService, userValidator) 
    }
}