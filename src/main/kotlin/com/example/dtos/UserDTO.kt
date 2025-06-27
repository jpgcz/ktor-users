package com.example.dtos

import kotlinx.serialization.Serializable

@Serializable
data class UserDTO (val id: Int?, val name: String?, val age: Int?, val email:String?) {
}