pipeline {
    agent any

    environment {
        TARGET_HOST    = "10.0.1.118"
        IMAGE_NAME     = "flowharbor"
        HOST_WORKSPACE = "/var/lib/docker/volumes/jenkins_home/_data/workspace/flowharbor"
    }

    stages {

        // ============================================================
        // Checkout Source
        // ============================================================

        stage('Checkout') {
            steps {
                git(
                    branch: 'main',
                    url: 'https://github.com/rishabh-yadav11/flowharbor.git'
                )

                script {
                    env.GIT_COMMIT = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()

                    env.GIT_SHORT_SHA = env.GIT_COMMIT.take(7)
                }
            }
        }

        // ============================================================
        // Install Dependencies
        // ============================================================

        stage('Install Dependencies') {
            steps {
                sh """
                    docker run --rm \
                        -v "${HOST_WORKSPACE}:/app" \
                        -w /app \
                        node:20-alpine \
                        npm ci
                """
            }
        }

        // ============================================================
        // Run Unit Tests
        // ============================================================

        stage('Run Unit Tests') {
            steps {
                sh """
                    docker run --rm \
                        -v "${HOST_WORKSPACE}:/app" \
                        -w /app \
                        node:20-alpine \
                        npm test
                """
            }

            post {
                always {
                    junit(
                        allowEmptyResults: true,
                        testResults: 'junit.xml'
                    )
                }
            }
        }

        // ============================================================
        // Build Docker Image
        // ============================================================

        stage('Build Image') {
            steps {
                sh """
                    docker build \
                        -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                        -t ${IMAGE_NAME}:${GIT_SHORT_SHA} \
                        .

                    docker save \
                        ${IMAGE_NAME}:${BUILD_NUMBER} \
                        ${IMAGE_NAME}:${GIT_SHORT_SHA} \
                    | gzip > image.tar.gz
                """
            }
        }

        // ============================================================
        // Copy Image to Private Server
        // ============================================================

        stage('Copy Image To Private Server') {
            steps {
                sshagent(credentials: ['private-server-key']) {

                    sh """
                        scp \
                            -o StrictHostKeyChecking=no \
                            image.tar.gz \
                            ubuntu@${TARGET_HOST}:/tmp/image.tar.gz

                        ssh \
                            -o StrictHostKeyChecking=no \
                            ubuntu@${TARGET_HOST} "

                            docker load < /tmp/image.tar.gz

                            echo
                            echo '=========================================='
                            echo ' Docker Images Loaded'
                            echo '=========================================='

                            docker images ${IMAGE_NAME} --format \
                            'table {{.Repository}}:{{.Tag}}\\t{{.ID}}\\t{{.CreatedSince}}'
                        "
                    """
                }
            }
        }

        // ============================================================
        // Deploy Testing
        // ============================================================

        stage('Deploy Test') {
            steps {
                sshagent(credentials: ['private-server-key']) {

                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_HOST} "

                            docker rm -f test || true

                            docker run -d \
                                --name test \
                                --restart unless-stopped \
                                -p 8081:3000 \
                                -e APP_ENV=testing \
                                -e BUILD_NUMBER=${BUILD_NUMBER} \
                                -e GIT_COMMIT=${GIT_COMMIT} \
                                -e DEPLOYED_AT=\\\$(date -u +%Y-%m-%dT%H:%M:%SZ) \
                                ${IMAGE_NAME}:${BUILD_NUMBER}
                        "
                    """
                }
            }
        }

        // ============================================================
        // Health Check - Testing
        // ============================================================

        stage('Health Check Test') {
            steps {
                sh """
                    for i in 1 2 3 4 5
                    do
                        if curl -sf http://${TARGET_HOST}:8081/health
                        then
                            echo "✅ Test environment is healthy."
                            exit 0
                        fi

                        echo "Attempt \$i failed...retrying in 3 seconds."
                        sleep 3
                    done

                    echo "❌ Test environment failed health check."
                    exit 1
                """
            }
        }

        // ============================================================
        // Manual Approval
        // ============================================================

        stage('Approve Staging') {
            steps {
                input message: 'Deploy to Staging?'
            }
        }

        // ============================================================
        // Deploy Staging
        // ============================================================

        stage('Deploy Staging') {
            steps {
                sshagent(credentials: ['private-server-key']) {

                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_HOST} "

                            docker rm -f staging || true

                            docker run -d \
                                --name staging \
                                --restart unless-stopped \
                                -p 8082:3000 \
                                -e APP_ENV=staging \
                                -e BUILD_NUMBER=${BUILD_NUMBER} \
                                -e GIT_COMMIT=${GIT_COMMIT} \
                                -e DEPLOYED_AT=\\\$(date -u +%Y-%m-%dT%H:%M:%SZ) \
                                ${IMAGE_NAME}:${BUILD_NUMBER}
                        "
                    """
                }
            }
        }

        // ============================================================
        // Health Check - Staging
        // ============================================================

        stage('Health Check Staging') {
            steps {
                sh """
                    for i in 1 2 3 4 5
                    do
                        if curl -sf http://${TARGET_HOST}:8082/health
                        then
                            echo "✅ Staging environment is healthy."
                            exit 0
                        fi

                        echo "Attempt \$i failed...retrying in 3 seconds."
                        sleep 3
                    done

                    echo "❌ Staging environment failed health check."
                    exit 1
                """
            }
        }

        // ============================================================
        // Manual Approval
        // ============================================================

        stage('Approve Production') {
            steps {
                input message: 'Deploy to Production?'
            }
        }

        // ============================================================
        // Deploy Production
        // ============================================================

        stage('Deploy Production') {
            steps {
                sshagent(credentials: ['private-server-key']) {

                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_HOST} "

                            docker rm -f production || true

                            docker run -d \
                                --name production \
                                --restart unless-stopped \
                                -p 8083:3000 \
                                -e APP_ENV=production \
                                -e BUILD_NUMBER=${BUILD_NUMBER} \
                                -e GIT_COMMIT=${GIT_COMMIT} \
                                -e DEPLOYED_AT=\\\$(date -u +%Y-%m-%dT%H:%M:%SZ) \
                                ${IMAGE_NAME}:${BUILD_NUMBER}
                        "
                    """
                }
            }
        }

        // ============================================================
        // Health Check - Production
        // ============================================================

        stage('Health Check Production') {
            steps {
                sh """
                    for i in 1 2 3 4 5
                    do
                        if curl -sf http://${TARGET_HOST}:8083/health
                        then
                            echo "✅ Production environment is healthy."
                            exit 0
                        fi

                        echo "Attempt \$i failed...retrying in 3 seconds."
                        sleep 3
                    done

                    echo "❌ Production environment failed health check."
                    exit 1
                """
            }
        }
    }

    // ============================================================
    // Cleanup
    // ============================================================

    post {
        always {
            sh 'rm -f image.tar.gz'
        }
    }
}2