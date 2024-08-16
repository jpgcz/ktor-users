# Ktor-users
Application for managing users.

## Artifacts requirements
___
- Codigo fuente
  - Java 17
  - Port 8080
  - Gradle
- Dockerfile
  - Docker 25.0.3
- Jenkinsfile
  - Jenkins Server
    - Docker Plugin

## Run the application
___

Build the docker container

```bash
docker build -t ktor-users:1.0.0 .
```

Run the docker container

```bash
docker run -dp 8080:8080 ktor-users:1.0.0
```

# API endpoints
___

## GET
`get all users` [user](#get-user) <br/>
`get user by id` [userById](#get-userid) <br/>

## POST
`add user` [/user](#post-user) <br/>

## PATCH
`update user` [/user/id](#patch-userid) <br/>

## DELETE
`delete user` [/user/id](#delete-userid) <br/>
___

### GET user
Get all user

**Response**

```json lines
[
    {
        "id": 1,
        "name": "persona1",
        "age": 20,
        "email": "persona1@gmail.com"
    },
    {
        "id": 2,
        "name": "persona2",
        "age": 21,
        "email": "persona2@gmail.com"
    },
    {
        "id": 3,
        "name": "persona3",
        "age": 22,
        "email": "persona3@gmail.com"
    }
]
```
___

### GET /user/id
Get user by `id`

**Parameters**

|              Name | Required | Type | Description                                  |
|------------------:|:--------:|:----:|----------------------------------------------|
|              `id` | required | int  | The id of the user you are looking for <br/> |

**Response**

```json lines
{
    "id": 1,
    "name": "persona1",
    "age": 20,
    "email": "persona1@gmail.com"
}
```
___

### POST /user
Add a user in this application requires to follow a specific format.

**Parameters**

Follow this format to enter parameters: `id`, `name`, `age`, `email`.

|    Name | Required |  Type  | Description                                  |
|--------:|:--------:|:------:|----------------------------------------------|
|    `id` | required |  int   | The id of the user you are looking for <br/> |
|  `name` | required | string |                                              |
|   `age` | required |  int   |                                              |
| `email` | required | string |                                              |

___


### PATCH /user/id
Update user information requires a specific format.

**Parameters**

Follow this format to enter parameters: `id`, `name`, `age`, `email`.

|    Name | Required |  Type  | Description                                  |
|--------:|:--------:|:------:|----------------------------------------------|
|    `id` | required |  int   | The id of the user you are looking for <br/> |
|  `name` | required | string |                                              |
|   `age` | required |  int   |                                              |
| `email` | required | string |                                              |

**Response**

```json lines
Successfully updated
```

___

### DELETE /user/id
Delete user.

**Parameters**

|              Name | Required | Type | Description                                       |
|------------------:|:--------:|:----:|---------------------------------------------------|
|              `id` | required | int  | The id of the user you are going to delete  <br/> |

**Response**

```json lines
Successfully removed
```
