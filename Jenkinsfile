pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                dockerImage = docker.build("jpgcz/ktor-users:1.0.0")
            }
        }

        /*
        stage('Run Application') {
            steps {
                script {
                    dockerImage.inside {
                        sh 'gradle build'
                    }
                }
            }
        }
        */

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