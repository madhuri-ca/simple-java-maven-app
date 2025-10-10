pipeline {
    agent any 

    environment {
        PROJECT_ID = 'internal-sandbox-446612'
        REPOSITORY_NAME = 'simple-java-maven-app'
        IMAGE_NAME = "gcr.io/${PROJECT_ID}/${REPOSITORY_NAME}"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        GCR_CRED_ID = 'gcr-json-key'
        KUBE_CRED_ID = 'kubeconfig-credentials-id'
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                echo 'Source code checked out by Jenkins.'
                sh 'git config --global --add safe.directory $PWD || true'
            }
        }

        stage('Build with Maven') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-11'
                    args '-u root'
                }
            }
            steps {
                sh 'git config --global --add safe.directory $PWD || true'
                echo 'Building the Maven project...'
                sh 'mvn -B clean package -DskipTests'
            }
        }

        stage('Unit Tests & Reports') {
            agent {
                docker {
                    image 'maven:3.9.6-eclipse-temurin-11'
                    args '-u root'
                }
            }
            steps {
                sh 'git config --global --add safe.directory $PWD || true'
                echo 'Running unit tests...'
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }

        stage('Build Docker Image') {
            agent any
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Push to GCR') {
            agent {
                docker {
                    image 'google/cloud-sdk:latest'
                    args '-u root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                withCredentials([file(credentialsId: GCR_CRED_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
                        gcloud auth configure-docker --quiet
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            agent {
                docker {
                    image 'google/cloud-sdk:latest'
                }
            }
            steps {
                withCredentials([file(credentialsId: KUBE_CRED_ID, variable: 'KUBECONFIG')]) {
                    sh '''
                        kubectl set image deployment/simple-java-app simple-java-app=${IMAGE_NAME}:${IMAGE_TAG} --record
                        kubectl rollout status deployment/simple-java-app
                    '''
                }
            }
        }
    }

    post {
        success { echo '✅ Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed.' }
    }
}
