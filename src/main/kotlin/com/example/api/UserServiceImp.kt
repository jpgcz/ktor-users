package com.example.api

import com.example.models.User

class UserServiceImp : UserService {
    private val users = mutableListOf<User> (
        User(1,"persona1", 20, "persona1@gmail.com"),
        User(2,"persona2", 21, "persona2@gmail.com"),
        User(3,"persona3", 22, "persona3@gmail.com")
    )

    override fun getAllUsers(): List<User> {
        return users
    }

    override fun getUserById(id: Int): User? {
        return users.find{it.id == id}
    }

    override fun addUser(user: User) {
        users.add(user)
    }

    override fun deleteUserById(id: Int): Boolean {
        return users.removeIf{it.id == id}
    }
}