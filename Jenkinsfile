pipeline {
    agent any

    environment {
        PROJECT_ID     = 'internal-sandbox-446612'
        REPOSITORY_NAME = 'simple-java-app'
        IMAGE_NAME     = "gcr.io/${PROJECT_ID}/${REPOSITORY_NAME}"
        IMAGE_TAG      = "${env.BUILD_NUMBER}"
        GCR_CRED_ID    = 'gcr-json-key'
        KUBE_CRED_ID   = 'kubeconfig-credentials-id'
    }

    stages {

        // ✅ Build Stage
        stage('Build with Maven') {
            agent {
                docker {
                    image 'maven:3.9.9-eclipse-temurin-17'   // ✅ updated to a valid image tag
                    args '-v /root/.m2:/root/.m2'
                }
            }
            steps {
                echo '🔧 Building the Maven project...'
                sh 'mvn -B clean package -DskipTests'
            }
        }

        // ✅ Test Stage
        stage('Unit Tests & Reports') {
            agent {
                docker {
                    image 'maven:3.9.9-eclipse-temurin-17'   // ✅ using same version for consistency
                    args '-v /root/.m2:/root/.m2'
                }
            }
            steps {
                echo '🧪 Running unit tests...'
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }

        // ✅ Docker Build
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        // ✅ Push to GCR
        stage('Push to GCR') {
            steps {
                echo '☁️ Pushing image to Google Container Registry...'
                withCredentials([file(credentialsId: GCR_CRED_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        gcloud auth configure-docker --quiet
                    '''
                }
                sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        // ✅ Deploy to Kubernetes
        stage('Deploy to Kubernetes') {
            steps {
                echo '🚀 Deploying to Kubernetes...'
                withCredentials([file(credentialsId: KUBE_CRED_ID, variable: 'KUBECONFIG')]) {
                    sh "kubectl set image deployment/simple-java-app simple-java-app=${IMAGE_NAME}:${IMAGE_TAG} --record"
                    sh "kubectl rollout status deployment/simple-java-app"
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs for details.'
        }
    }
}
