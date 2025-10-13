pipeline {
    agent any

    environment {
        PROJECT_ID = 'internal-sandbox-446612'
        REPOSITORY_NAME = 'simple-java-app'
        IMAGE_NAME = "gcr.io/${PROJECT_ID}/${REPOSITORY_NAME}"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        GCR_CRED_ID = 'gcr-json-key'
        KUBE_CRED_ID = 'kubeconfig-credentials-id'
    }

    stages {
        // ✅ Remove the “Checkout Source Code” stage completely!

        stage('Build with Maven') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11'
                    args '-u root'
                }
            }
            steps {
                echo 'Building the Maven project...'
                sh 'mvn -B clean package -DskipTests'
            }
        }

        stage('Unit Tests & Reports') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11'
                    args '-u root'
                }
            }
            steps {
                echo 'Running unit tests...'
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Push to GCR') {
            steps {
                echo 'Pushing image to GCR...'
                withCredentials([file(credentialsId: GCR_CRED_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
                        gcloud auth configure-docker --quiet
                    '''
                }
                sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                withCredentials([file(credentialsId: KUBE_CRED_ID, variable: 'KUBECONFIG')]) {
                    sh "kubectl set image deployment/simple-java-app simple-java-app=${IMAGE_NAME}:${IMAGE_TAG} --record"
                    sh "kubectl rollout status deployment/simple-java-app"
                }
            }
        }
    }

    post {
        success { echo '✅ Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed.' }
    }
}
