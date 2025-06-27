package com.example.api

import com.example.models.User

class UserRepository {
    private val users = mutableListOf<User>(
        User(1, "persona1", 20, "persona1@gmail.com"),
        User(2, "persona2", 21, "persona2@gmail.com"),
        User(3, "persona3", 22, "persona3@gmail.com")
    )

    fun getAllUsers(): List<User> {
        return users
    }

    fun getUserById(id: Int): User? {
        return users.find { it.id == id }
    }

    fun addUser(user: User) {
        users.add(user)
    }

    fun deleteUserById(id: Int): Boolean {
        return users.removeIf { it.id == id }
    }

    fun updateUser(user: User): Boolean {
        val index = users.indexOfFirst { it.id == user.id }
        return if (index != -1) {
            users[index] = user
            true
        } else {
            false
        }
    }
}