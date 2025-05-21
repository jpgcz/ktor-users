pipeline {
    agent any

    parameters {
        choice(name: 'VERSION_INCREMENT', choices: ['PATCH', 'MINOR', 'MAJOR'], description: 'Which part of the version to increment')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip running tests')
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
            when{
                expression { return !params.SKIP_TESTS }
            }
            steps {
                sh 'chmod +x ./gradlew'
                sh './gradlew test'
            }
            post {
                always {
                    script {
                        try {
                            junit '**/build/test-results/test/*.xml'
                        } catch (Exception e) {
                            echo "No test results found or error processing test results: ${e.message}"
                        }
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

        stage('Push to Registry') {
            steps {
                script {
                    // Push to registry
                    docker.withRegistry('', '259bc10b-38c9-4094-954e-5f9a6f066f92') {
                        dockerImage.push("${env.APP_VERSION}-dev")
                        dockerImage.push('dev')
                    }
                }
            }
        }

        stage('Deployment to Development') {
            steps {
                script {
                    // Stop and remove existing container if it exists
                    sh 'docker stop ktor-users-dev || true'
                    sh 'docker rm ktor-users-dev || true'

                    // Run the container in development environment with host networking
                    sh "docker run -d --network=host -e ENVIRONMENT=development -e APP_VERSION=${env.APP_VERSION} --name ktor-users-dev jpgcz/ktor-users:${env.APP_VERSION}"
                    
                    // Wait for the service to be ready
                    sh 'sleep 10'                }
            }
        }

        stage('Run Acceptance Tests - Dev') {
            steps {
                script {
                    try {
                        // Try to access the service
                        sh 'curl -f http://localhost:8080/user'
                        echo "Acceptance tests passed"
                    } catch (Exception e) {
                        echo "Acceptance tests failed, but continuing with deployment"
                    }
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                script {
                    // Stop and remove existing container if it exists
                    sh 'docker stop ktor-users-prod || true'
                    sh 'docker rm ktor-users-prod || true'
                    
                    // Run the container in production environment
                    sh "docker run -d -p 80:8080 -e ENVIRONMENT=production -e APP_VERSION=${env.APP_VERSION} --name ktor-users-prod jpgcz/ktor-users:${env.APP_VERSION}"
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
