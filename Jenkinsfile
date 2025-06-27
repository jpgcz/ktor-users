pipeline {
    agent any

    parameters {
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip running tests')
        booleanParam(name: 'DEPLOY_TO_PROD', defaultValue: false, description: 'Deploy to production after approval')
        string(name: 'GIT_TAG', defaultValue: '', description: 'Git tag from GitHub workflow')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Deployment environment')
    }

    environment {
        AWS_REGION = "us-east-2"
        VERSION_FILE = ".version"
    }

    stages {
        stage('Fetch Secrets'){
            steps {
                script {
                    // Retrieve secrets from AWS Secrets Manager
                    def githubSecret = sh(
                        script: "aws secretsmanager get-secret-value --secret-id github/token --query SecretString --output text --region ${AWS_REGION}",
                        returnStdout: true
                    ).trim()
                    
                    env.GITHUB_TOKEN = githubSecret
                    
                    def dockerSecret = sh(
                        script: "aws secretsmanager get-secret-value --secret-id docker/registry-creds --query SecretString --output text --region ${AWS_REGION}",
                        returnStdout: true
                    ).trim()
                    
                    env.DOCKER_REGISTRY_CREDS = dockerSecret
                }
            }
        }

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
                    // Parse the Docker credentials JSON from Secrets Manager
                    def dockerCredsJson = readJSON text: env.DOCKER_REGISTRY_CREDS
                    
                    // Use the credentials to authenticate with Docker registry
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'docker-temp-creds', 
                            usernameVariable: 'DOCKER_USER', 
                            passwordVariable: 'DOCKER_PASS',
                            username: dockerCredsJson.username,
                            password: dockerCredsJson.password
                        )
                    ]) {
                        sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                        
                        // Push to registry with appropriate tags
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
        always {
            script {
                if (params.ENVIRONMENT == 'prod' && env.BRANCH_NAME == 'master') {
                    // Update README with status badge
                    try {
                        // Generate badge URL
                        def badgeUrl = "${env.JENKINS_URL}/buildStatus/icon?job=${env.JOB_NAME}&subject=build&status=${currentBuild.currentResult}"
                        
                        // Check if README exists and update it
                        if (fileExists('README.md')) {
                            def readmeContent = readFile('README.md')
                            if (!readmeContent.contains('![Build Status]')) {
                                // Add badge at the top of README
                                def updatedContent = "![Build Status](${badgeUrl})\n\n" + readmeContent
                                writeFile file: 'README.md', text: updatedContent
                                
                                // Parse GitHub credentials from Secrets Manager
                                def githubCredsJson = readJSON text: env.GITHUB_TOKEN
                                
                                // Commit and push the change using GitHub token
                                sh """
                                git config user.email "jenkins@example.com"
                                git config user.name "Jenkins"
                                git add README.md
                                git commit -m "Add build status badge [ci skip]"
                                git remote set-url origin https://${githubCredsJson.token}@github.com/jpgcz/ktor-users.git
                                git push origin master
                                """
                            }
                        }
                    } catch (Exception e) {
                        echo "Failed to update README with status badge: ${e.message}"
                    }
                }
                
                // Send email notification
                // emailext (
                //     subject: "Build ${currentBuild.currentResult}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                //     body: """<p>Build Status: ${currentBuild.currentResult}</p>
                //         <p>Build: ${env.BUILD_NUMBER}</p>
                //         <p>Job: ${env.JOB_NAME}</p>
                //         <p>Environment: ${params.ENVIRONMENT}</p>
                //         <p>Version: ${env.APP_VERSION}</p>
                //         <p>Check console output at <a href='${env.BUILD_URL}'>${env.BUILD_URL}</a></p>""",
                //     recipientProviders: [[$class: 'DevelopersRecipientProvider'], [$class: 'RequesterRecipientProvider']],
                //     to: '${env.DEFAULT_RECIPIENTS}',
                //     mimeType: 'text/html'
                // )
            }
        }
        success {
            echo "Successfully built and deployed version ${env.APP_VERSION} to ${params.ENVIRONMENT} environment"
        }
        failure {
            echo "Build or deployment failed for version ${env.APP_VERSION}"
        }
    }
}