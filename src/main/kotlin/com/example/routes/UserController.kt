package com.example.routes

import com.example.api.UserService
import com.example.api.UserValidator
import com.example.dtos.UserDTO
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject

fun Route.userRouting(userService: UserService, userValidator: UserValidator) {
    route("/user") {
        get {
            val users = userService.getAllUsers()
            if (users.isNotEmpty()) {
                call.respondText("$users", status = HttpStatusCode.OK)
            } else {
                call.respondText("User list is empty", status = HttpStatusCode.NoContent)
            }
        }
        get("{id?}") {
            val id = call.parameters["id"]?.let {
                userValidator.validateId(it)
            } ?: return@get call.respondText(
                "id not found",
                status = HttpStatusCode.BadRequest
            )

            val user = userService.getUserById(id) ?: return@get call.respondText(
                "User not found",
                status = HttpStatusCode.NotFound
            )

            call.respond(user)
        }
        post {
            val json = call.receiveText()
            val jsonObject = Json.parseToJsonElement(json).jsonObject

            if (!userValidator.validateUserJson(jsonObject)) {
                return@post call.respondText(
                    "Invalid data or incomplete",
                    status = HttpStatusCode.BadRequest
                )
            }

            val userDTO = Json.decodeFromString<UserDTO>(json)

            if (!userValidator.validateUserFields(userDTO)) {
                return@post call.respondText(
                    "All data must be provided",
                    status = HttpStatusCode.BadRequest
                )
            }

            userService.addUser(userDTO)
        }
        patch("{id?}") {
            val id = call.parameters["id"]?.let {
                userValidator.validateId(it)
            } ?: return@patch call.respondText(
                "id not found",
                status = HttpStatusCode.BadRequest
            )

            val json = call.receiveText()
            val jsonObject = Json.parseToJsonElement(json).jsonObject

            if (!userValidator.validateUserJson(jsonObject)) {
                return@patch call.respondText(
                    "Invalid data or incomplete",
                    status = HttpStatusCode.BadRequest
                )
            }

            val userDTO = Json.decodeFromString<UserDTO>(json)

            if (!userValidator.validateUserFields(userDTO)) {
                return@patch call.respondText(
                    "All data must be provided",
                    status = HttpStatusCode.BadRequest
                )
            }

            if (userService.updateUser(id, userDTO)) {
                call.respondText(
                    "Successfully updated",
                    status = HttpStatusCode.Accepted
                )
            } else {
                call.respondText(
                    "User not found",
                    status = HttpStatusCode.NotFound
                )
            }
        }
        delete("{id?}") {
            val id = call.parameters["id"]?.let {
                userValidator.validateId(it)
            } ?: return@delete call.respondText(
                "Id not found",
                status = HttpStatusCode.BadRequest
            )

            if (userService.deleteUserById(id)) {
                call.respondText(
                    "Successfully removed",
                    status = HttpStatusCode.Accepted
                )
            } else {
                call.respondText(
                    "User not found",
                    status = HttpStatusCode.NotFound
                )
            }
        }
    }
}