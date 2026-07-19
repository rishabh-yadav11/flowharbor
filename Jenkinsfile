pipeline {
    agent any
    environment {
        TARGET_HOST = "10.0.1.118"
        IMAGE_NAME = "flowharbor"
    }
    stages {
        stage('Checkout') {
            steps {
               git branch: 'main',
                   url: 'https://github.com/rishabh-yadav11/flowharbor.git'
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }
        stage('Run Unit Tests') {
            steps {
                sh 'npm test'
            }
            post {
                always {
                    // Requires the "JUnit" plugin (usually already installed) and
                    // jest-junit configured to write junit.xml — see notes below.
                    junit allowEmptyResults: true, testResults: 'junit.xml'
                }
            }
        }
        stage('Build Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                    docker save ${IMAGE_NAME}:${BUILD_NUMBER} | gzip > image.tar.gz
                """
            }
        }
        stage('Copy Image To Private Server') {
            steps {
                sshagent(credentials: ['private-server-key']) {
                    sh """
                        scp -o StrictHostKeyChecking=no \
                        image.tar.gz \
                        ubuntu@${TARGET_HOST}:/tmp/image.tar.gz
                        ssh -o StrictHostKeyChecking=no \
                        ubuntu@${TARGET_HOST} "
                            docker load < /tmp/image.tar.gz
                        "
                    """
                }
            }
        }
        stage('Deploy Test') {
            steps {
                sshagent(credentials: ['private-server-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no \
                        ubuntu@${TARGET_HOST} "
                            docker rm -f test || true
                            docker run -d \
                              --name test \
                              --restart unless-stopped \
                              -p 8081:3000 \
                              ${IMAGE_NAME}:${BUILD_NUMBER}
                        "
                    """
                }
            }
        }
        stage('Approve Staging') {
            steps {
                input 'Deploy to staging?'
            }
        }
        stage('Deploy Staging') {
            steps {
                sshagent(credentials: ['private-server-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no \
                        ubuntu@${TARGET_HOST} "
                            docker rm -f staging || true
                            docker run -d \
                              --name staging \
                              --restart unless-stopped \
                              -p 8082:3000 \
                              ${IMAGE_NAME}:${BUILD_NUMBER}
                        "
                    """
                }
            }
        }
        stage('Approve Production') {
            steps {
                input 'Deploy to production?'
            }
        }
        stage('Deploy Production') {
            steps {
                sshagent(credentials: ['private-server-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no \
                        ubuntu@${TARGET_HOST} "
                            docker rm -f production || true
                            docker run -d \
                              --name production \
                              --restart unless-stopped \
                              -p 8083:3000 \
                              ${IMAGE_NAME}:${BUILD_NUMBER}
                        "
                    """
                }
            }
        }
    }
    post {
        always {
            sh 'rm -f image.tar.gz'
        }
    }
}
