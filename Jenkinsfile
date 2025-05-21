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

        stage('Run Tests') {
            steps {
                sh 'chmod +x ./gradlew'
                sh './gradlew test'
            }
            post {
                always {
                    try {
                        junit '**/build/test-results/test/*.xml'
                    } catch (Exception e) {
                        echo "No test results found or error processing test results: ${e.message}"
                    }
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

        stage('Deployment to Development') {
            steps {
                script {
                    // Push to registry - exactly like the original
                    docker.withRegistry('', '259bc10b-38c9-4094-954e-5f9a6f066f92') {
                        dockerImage.push("${env.APP_VERSION}-dev")
                        dockerImage.push('dev')
                    }

                    // Stop and remove existing container if it exists
                    sh 'docker stop ktor-users-dev || true'
                    sh 'docker rm ktor-users-dev || true'
                    
                    // Run the container in development environment
                    docker.image("jpgcz/ktor-users:${env.APP_VERSION}").run("-p 8081:8080 -e ENVIRONMENT=development -e APP_VERSION=${env.APP_VERSION} --name ktor-users-dev")
                }
            }
        }

        stage('Run Acceptance Tests - Dev') {
            steps {
                // Wait for the service to be ready
                sh 'sleep 5'
                
                // Run acceptance tests against dev environment
                sh '''
                curl -f http://localhost:8081/user || exit 1
                echo "Acceptance tests passed"
                '''
            }
        }

        stage('Deploy to Production') {
            steps {
                script {
                    // Push to registry with prod tag
                    docker.withRegistry('', '259bc10b-38c9-4094-954e-5f9a6f066f92') {
                        dockerImage.push('prod')
                        dockerImage.push("${env.APP_VERSION}")
                        dockerImage.push('latest')
                    }
                    
                    // Stop and remove existing container if it exists
                    sh 'docker stop ktor-users-prod || true'
                    sh 'docker rm ktor-users-prod || true'
                    
                    // Run the container in production environment
                    docker.image("jpgcz/ktor-users:${env.APP_VERSION}").run("-p 8080:8080 -e ENVIRONMENT=production -e APP_VERSION=${env.APP_VERSION} --name ktor-users-prod")
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
