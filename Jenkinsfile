pipeline {
    agent any

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Branch to build')
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
                    
                    // Save new version if on main branch
                    if (params.BRANCH_NAME == 'main') {
                        sh "echo ${env.APP_VERSION} > ${env.VERSION_FILE}"
                    }
                    
                    echo "Building version ${env.APP_VERSION}"
                }
            }
        }

        stage('Run Tests') {
            steps {
                sh './gradlew test'
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
                    // Update version in Application.kt before building
                    sh "sed -i 's/const val APP_VERSION = \".*\"/const val APP_VERSION = \"${env.APP_VERSION}\"/' src/main/kotlin/com/example/Application.kt"
            
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
    }
}