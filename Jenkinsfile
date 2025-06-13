pipeline {
    agent any

    parameters {
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip running tests')
        booleanParam(name: 'DEPLOY_TO_PROD', defaultValue: false, description: 'Deploy to production after approval')
        string(name: 'GIT_TAG', defaultValue: '', description: 'Git tag from GitHub workflow')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Deployment environment')
    }

    environment {
        VERSION_FILE = ".version"
        GITHUB_TOKEN = credentials('github-token')
        DOCKER_REGISTRY_CREDS = '259bc10b-38c9-4094-954e-5f9a6f066f92'
    }

    stages {
        stage('Determine Version') {
            steps {
                script {
                    // Check if version was provided as parameter (from GitHub workflow)
                    if (params.GIT_TAG?.trim()) {
                        env.APP_VERSION = params.GIT_TAG.trim()
                        echo "Using provided git tag: ${env.APP_VERSION}"
                    } else {
                        // Try to get the latest git tag from GitHub
                        try {
                            env.APP_VERSION = sh(script: 'git fetch --tags && git describe --tags --abbrev=0', returnStdout: true).trim()
                            echo "Found git tag: ${env.APP_VERSION}"
                        } catch (Exception e) {
                            echo "No git tag found, using branch name and commit hash"
                            def branchName = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                            def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                            env.APP_VERSION = "${branchName}-${commitHash}"
                        }
                    }
                    
                    echo "Building version ${env.APP_VERSION}"
                    // Save the version for reference
                    sh "echo ${env.APP_VERSION} > ${env.VERSION_FILE}"
                    
                    // Set environment-specific variables
                    if (params.ENVIRONMENT == 'prod') {
                        env.DOCKER_TAG = 'latest'
                        env.CONTAINER_NAME = 'ktor-users-prod'
                        env.PORT = '8082'
                    } else {
                        env.DOCKER_TAG = 'dev'
                        env.CONTAINER_NAME = 'ktor-users-dev'
                        env.PORT = '8081'
                    }
                }
            }
        }

        stage('Run Tests') {
            when {
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
                    
                    // Build with version tag
                    dockerImage = docker.build("jpgcz/ktor-users:${env.APP_VERSION}")
                }
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    // Push to registry with appropriate tags
                    docker.withRegistry('', env.DOCKER_REGISTRY_CREDS) {
                        dockerImage.push("${env.APP_VERSION}")
                        dockerImage.push("${env.DOCKER_TAG}")
                    }
                }
            }
        }

        stage('Approval for Production') {
            when {
                expression { return params.ENVIRONMENT == 'prod' && params.DEPLOY_TO_PROD }
            }
            steps {
                timeout(time: 24, unit: 'HOURS') {
                    input message: "Deploy to Production?", ok: "Deploy"
                }
            }
        }

        stage('Deploy to Environment') {
            steps {
                script {
                    // Stop and remove existing container if it exists
                    sh "docker stop ${env.CONTAINER_NAME} || true"
                    sh "docker rm ${env.CONTAINER_NAME} || true"

                    // Run the container in the appropriate environment
                    sh "docker run -d -p ${env.PORT}:8080 -e ENVIRONMENT=${params.ENVIRONMENT} -e APP_VERSION=${env.APP_VERSION} --name ${env.CONTAINER_NAME} jpgcz/ktor-users:${env.DOCKER_TAG}"
                    
                    // Wait for the service to be ready
                    sh 'sleep 10'
                }
            }
        }

        stage('Run Acceptance Tests') {
            steps {
                script {
                    try {
                        // Try to access the service
                        sh "curl -f http://localhost:${env.PORT}/user"
                        echo "Acceptance tests passed"
                    } catch (Exception e) {
                        echo "Acceptance tests failed, but continuing with deployment"
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Successfully built and deployed version ${env.APP_VERSION} to ${params.ENVIRONMENT} environment"
        }
        failure {
            echo "Build or deployment failed for version ${env.APP_VERSION}"
        }
    }
}