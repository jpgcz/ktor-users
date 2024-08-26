pipeline {
    agent { dockerfile true }

    stages {
        stage('Build Docker Image') {
            steps {
                checkout scm
                script {
                    dockerImage = docker.build("jpgcz/ktor-users:1.0.0")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('', '259bc10b-38c9-4094-954e-5f9a6f066f92') {
                        dockerImage.push('1.0.0')
                    }
                }
            }
        }
    }
}