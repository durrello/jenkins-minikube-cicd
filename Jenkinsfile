pipeline {
    agent any

    environment {
        IMAGE_NAME = 'demo-app'
        REGISTRY   = 'localhost:5000'
        NAMESPACE  = 'demo'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Unit Test') {
            steps {
                sh '''
                    docker run --rm \
                        -v "${WORKSPACE}/app":/src \
                        -w /src \
                        golang:1.22-alpine \
                        go test -v ./...
                '''
            }
        }

        stage('Build Image') {
            steps {
                dir('app') {
                    sh """
                        docker build \
                            -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} \
                            -t ${REGISTRY}/${IMAGE_NAME}:latest \
                            .
                    """
                }
            }
        }

        stage('Push to Registry') {
            steps {
                sh """
                    docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${REGISTRY}/${IMAGE_NAME}:latest
                """
            }
        }

        stage('Deploy to Minikube') {
            steps {
                sh """
                    kubectl apply -f k8s/namespace.yaml
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                    kubectl rollout status deployment/${IMAGE_NAME} \
                        -n ${NAMESPACE} \
                        --timeout=120s
                """
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded! ${IMAGE_NAME}:${BUILD_NUMBER} deployed to namespace '${NAMESPACE}'."
        }
        failure {
            echo "❌ Pipeline failed. Check the logs above for details."
        }
        always {
            echo "Pipeline finished. Build #${BUILD_NUMBER}"
        }
    }
}
