pipeline {
    agent any

    stages {
        stage('Build Docker Image with Kaniko') {
            steps {
                script {
                    withCredentials([string(credentialsId: '259bc10b-38c9-4094-954e-5f9a6f066f92', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh """
                    mkdir -p /kaniko/.docker
                    echo '{ "auths": { "https://index.docker.io/v1/": { "username": "${DOCKER_USERNAME}", "password": "${DOCKER_PASSWORD}" } } }' > /kaniko/.docker/config.json
                    docker run --rm \
                    -v `pwd`:/workspace \
                    -v /kaniko/.docker:/kaniko/.docker \
                    gcr.io/kaniko-project/executor:latest \
                    --dockerfile /workspace/Dockerfile \
                    --context /workspace \
                    --destination=docker.io/${DOCKER_USERNAME}/ktor-users:1.0.0
                    """
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('', '259bc10b-38c9-4094-954e-5f9a6f066f92') {
                        sh "docker push ${DOCKER_USERNAME}/ktor-users:1.0.0"Z
                    }
                }
            }
        }
    }
}