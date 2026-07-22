pipeline {
    agent { label 'docker-build' }

    environment {
        ECR_URI      = "766037821505.dkr.ecr.ap-south-1.amazonaws.com/flowharbor-app"
        AWS_REGION   = "ap-south-1"
        CLUSTER      = "flowharbor-cluster-aws"
        IMAGE_TAG    = "${env.BUILD_NUMBER}"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Verify Branch') {
            steps {
                script {
                    def branch = env.GIT_BRANCH ?: env.BRANCH_NAME ?: ''
                    if (!branch.endsWith('testing')) {
                        error("This pipeline only runs on the 'testing' branch. Current branch: ${branch}")
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                sh """
                    docker build -t ${ECR_URI}:testing-${IMAGE_TAG} .
                """
            }
        }

        stage('Push to ECR (testing)') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}
                    docker push ${ECR_URI}:testing-${IMAGE_TAG}
                """
            }
        }

        stage('Deploy to Testing') {
            steps {
                sh """
                    aws ecs update-service --cluster ${CLUSTER} --service svc-testing --force-new-deployment --region ${AWS_REGION}
                    aws ecs wait services-stable --cluster ${CLUSTER} --services svc-testing --region ${AWS_REGION}
                """
            }
        }

        stage('Approval: Staging') {
            steps {
                input message: "Deploy build #${IMAGE_TAG} to staging?", ok: 'Deploy'
            }
        }

        stage('Promote & Push to ECR (staging)') {
            steps {
                sh """
                    docker tag ${ECR_URI}:testing-${IMAGE_TAG} ${ECR_URI}:staging-${IMAGE_TAG}
                    docker push ${ECR_URI}:staging-${IMAGE_TAG}
                """
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh """
                    aws ecs update-service --cluster ${CLUSTER} --service svc-staging --force-new-deployment --region ${AWS_REGION}
                    aws ecs wait services-stable --cluster ${CLUSTER} --services svc-staging --region ${AWS_REGION}
                """
            }
        }

        stage('Approval: Production') {
            steps {
                input message: "Deploy build #${IMAGE_TAG} to production?", ok: 'Deploy'
            }
        }

        stage('Promote & Push to ECR (production)') {
            steps {
                sh """
                    docker tag ${ECR_URI}:testing-${IMAGE_TAG} ${ECR_URI}:prod-${IMAGE_TAG}
                    docker push ${ECR_URI}:prod-${IMAGE_TAG}
                """
            }
        }

        stage('Deploy to Production') {
            steps {
                sh """
                    aws ecs update-service --cluster ${CLUSTER} --service svc-production --force-new-deployment --region ${AWS_REGION}
                    aws ecs wait services-stable --cluster ${CLUSTER} --services svc-production --region ${AWS_REGION}
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully for build #${IMAGE_TAG}"
        }
        failure {
            echo "Pipeline failed for build #${IMAGE_TAG} — check the stage logs above"
        }
        always {
            sh "docker logout ${ECR_URI} || true"
        }
    }
}