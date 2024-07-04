package com.example.api

import com.example.models.User
import kotlinx.serialization.json.JsonObject

class UserValidator {
    //validar si existe
    fun validateId(id: String?): Int? {
        return id?.toIntOrNull()
    }

    //validar valores de los campos
    fun validateUserFields(user: User): Boolean {
        return user.id != null &&
                !user.name.isNullOrBlank() &&
                user.age != null &&
                !user.email.isNullOrBlank()
    }

    //validar que existan los parametros
    fun validateUserJson(jsonObject: JsonObject): Boolean {
        return jsonObject.containsKey("id") ||
                jsonObject.containsKey("name") ||
                jsonObject.containsKey("age") ||
                jsonObject.containsKey("email")
    }
}