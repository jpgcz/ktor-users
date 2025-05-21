pipeline {
    agent any

    parameters {
        choice(name: 'VERSION_INCREMENT', choices: ['PATCH', 'MINOR', 'MAJOR'], description: 'Which part of the version to increment')
    }

    environment {
        VERSION_FILE = 'version.txt'
    }

    stages {
        stage('Determine Version') {
            steps {
                script {
                    // Create version file if it doesn't exist
                    if (!fileExists(env.VERSION_FILE)) {
                        sh "echo '0.1.0' > ${env.VERSION_FILE}"
                    }
                    
                    // Read current version
                    def currentVersion = readFile(env.VERSION_FILE).trim()
                    def (major, minor, patch) = currentVersion.tokenize('.')
                    
                    // Increment version based on parameter
                    if (params.VERSION_INCREMENT == 'MAJOR') {
                        major = major.toInteger() + 1
                        minor = 0
                        patch = 0
                    } else if (params.VERSION_INCREMENT == 'MINOR') {
                        minor = minor.toInteger() + 1
                        patch = 0
                    } else {
                        patch = patch.toInteger() + 1
                    }
                    
                    // Set new version
                    env.APP_VERSION = "${major}.${minor}.${patch}"
                    
                    // Save new version
                    sh "echo ${env.APP_VERSION} > ${env.VERSION_FILE}"
                    
                    echo "Building version ${env.APP_VERSION}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                checkout scm
                script {
                    // Update version in Application.kt if it exists
                    sh '''
                    if [ -f "src/main/kotlin/com/example/Application.kt" ]; then
                        if grep -q "const val APP_VERSION" src/main/kotlin/com/example/Application.kt; then
                            sed -i 's/const val APP_VERSION = ".*"/const val APP_VERSION = "'${APP_VERSION}'"/' src/main/kotlin/com/example/Application.kt
                        else
                            sed -i "/package com.example/a\\\\nconst val APP_VERSION = \\"${APP_VERSION}\\"\\n" src/main/kotlin/com/example/Application.kt
                        fi
                    fi
                    '''
                    
                    // Build with version tag - exactly like the original
                    dockerImage = docker.build("jpgcz/ktor-users:${env.APP_VERSION}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Push to registry - exactly like the original
                    docker.withRegistry('', '259bc10b-38c9-4094-954e-5f9a6f066f92') {
                        dockerImage.push("${env.APP_VERSION}")
                        dockerImage.push('latest')
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Successfully built version ${env.APP_VERSION}"
        }
    }
}
