package com.example.api

import com.example.models.User

interface UserService {
    fun getAllUsers(): List<User>

    fun getUserById(id: Int): User?

    fun addUser(user: User): Unit

    fun deleteUserById(id: Int): Boolean
}