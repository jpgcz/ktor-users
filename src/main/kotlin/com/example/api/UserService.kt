package com.example.api

import com.example.dtos.UserDTO
import com.example.models.User

class UserService(
    private val userRepository: UserRepository
) {
    fun getAllUsers(): List<UserDTO> {
        return userRepository.getAllUsers().map { it.toDTO() }
    }

    fun getUserById(id: Int): UserDTO? {
        return userRepository.getUserById(id)?.toDTO()
    }

    fun addUser(userDTO: UserDTO) {
        userRepository.addUser(userDTO.toModel())
    }

    fun deleteUserById(id: Int): Boolean {
        return userRepository.deleteUserById(id)
    }

    fun updateUser(id: Int, userDTO: UserDTO): Boolean {
        val user = userDTO.toModel().copy(id = id)
        return userRepository.updateUser(user)
    }
}

fun User.toDTO(): UserDTO {
    return UserDTO(id, name, age, email)
}

fun UserDTO.toModel(): User {
    return User(id, name, age, email)
}