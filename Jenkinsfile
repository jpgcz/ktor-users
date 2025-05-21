pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'master', description: 'Branch to build')
        choice(name: 'VERSION_INCREMENT', choices: ['PATCH', 'MINOR', 'MAJOR'], description: 'Which part of the version to increment')
    }

    environment {
        VERSION_FILE = 'version.txt'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                // Make gradlew executable
                sh 'chmod +x ./gradlew || true'
            }
        }

        stage('Check Docker') {
            steps {
                sh 'docker --version'
                sh 'sudo docker ps || docker ps'
                docker.ps
            }
        }
        
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
                    
                    // Save new version if on main branch
                    if (params.BRANCH_NAME == 'master') {
                        sh "echo ${env.APP_VERSION} > ${env.VERSION_FILE}"
                    }
                    
                    echo "Building version ${env.APP_VERSION}"
                }
            }
        }

        stage('Run Tests') {
            steps {
                // Check if gradlew exists and is executable
                sh '''
                if [ -f "./gradlew" ]; then
                    chmod +x ./gradlew
                    ./gradlew test
                else
                    echo "Gradle wrapper not found, trying with gradle directly"
                    gradle test || echo "No Gradle installation found"
                fi
                '''
            }
            post {
                always {
                    junit '**/build/test-results/test/*.xml'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                checkout scm
                script {
                    // Check if Application.kt exists before trying to update it
                    sh '''
                    if [ -f "src/main/kotlin/com/example/Application.kt" ]; then
                        if grep -q "const val APP_VERSION" src/main/kotlin/com/example/Application.kt; then
                            sed -i 's/const val APP_VERSION = ".*"/const val APP_VERSION = "'${APP_VERSION}'"/' src/main/kotlin/com/example/Application.kt
                        else
                            # Add the version constant if it doesn't exist
                            sed -i '1s/^/package com.example\\n\\nconst val APP_VERSION = "'${APP_VERSION}'"\\n\\n/' src/main/kotlin/com/example/Application.kt
                        fi
                    else
                        echo "Application.kt not found at expected location"
                    fi
                    '''

                    // Build with version tag
                    dockerImage = docker.build("jpgcz/ktor-users:${env.APP_VERSION}")
                }
            }
        }

        stage('Deploy to Development') {
            steps {
                script {
                    // Push to registry
                    docker.withRegistry('', '259bc10b-38c9-4094-954e-5f9a6f066f92') {
                        dockerImage.push('dev')
                        dockerImage.push("${env.APP_VERSION}-dev")
                    }

                    // Update version in application
                    sh "sed -i 's/const val APP_VERSION = \".*\"/const val APP_VERSION = \"${env.APP_VERSION}\"/' src/main/kotlin/com/example/Application.kt"
                    
                    // Deploy to dev environment
                    sh '''
                    docker-compose -f docker-compose.dev.yml down
                    export APP_VERSION=${APP_VERSION}
                    docker-compose -f docker-compose.dev.yml up -d
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Successfully built version ${env.APP_VERSION}"
        }
        failure {
            echo "Build failed"
        }
    }
}