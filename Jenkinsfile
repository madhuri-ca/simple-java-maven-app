pipeline {
    agent any

    environment {
        // Docker image details
        IMAGE_NAME = "gcr.io/internal-sandbox-446612/my-app"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        
        // Path to kubeconfig for Kubernetes deployment
        KUBECONFIG_CREDENTIALS_ID = "kubeconfig-credentials-id"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code from Git...'
                git url: 'https://github.com/madhuri-ca/simple-java-maven-app.git', branch: 'master'
            }
        }

        stage('Build') {
            steps {
                echo 'Building the Maven project...'
                sh 'mvn clean install -DskipTests'
            }
        }

        stage('Unit Tests') {
            steps {
                echo 'Running unit tests...'
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                
                echo 'Logging in to GCR...'
                withCredentials([file(credentialsId: 'gcr-json-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh 'gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS'
                    sh "gcloud auth configure-docker --quiet"
                }
                
                echo 'Pushing Docker image to GCR...'
                sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS_ID}", variable: 'KUBECONFIG')]) {
                    sh "kubectl set image deployment/my-app my-app=${IMAGE_NAME}:${IMAGE_TAG} --record"
                    sh "kubectl rollout status deployment/my-app"
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
