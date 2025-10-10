pipeline {

    agent any

    environment {
        PROJECT_ID      = 'internal-sandbox-446612'
        REPOSITORY_NAME = 'simple-java-app'
        IMAGE_NAME      = "gcr.io/${PROJECT_ID}/${REPOSITORY_NAME}"
    }

    stages {

        // 🔹 Build the Java app with Maven
        stage('Build with Maven') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'mvn -B -DskipTests clean package'
            }
        }

        // 🔹 Run unit tests and publish reports
        stage('Unit Tests & Reports') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        // 🔹 Build Docker image
        stage('Build Docker Image') {
            agent any
            steps {
                script {
                    def imageTag = "${BUILD_NUMBER}"
                    sh "docker build -t ${IMAGE_NAME}:${imageTag} ."
                }
            }
        }

        // 🔹 Push Docker image to Google Container Registry (GCR)
        stage('Push to GCR') {
            agent any
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'gcr-sa-json', usernameVariable: 'GCR_USER', passwordVariable: 'GCR_KEY')]) {
                        sh 'echo "$GCR_KEY" | docker login -u $GCR_USER --password-stdin https://gcr.io'
                        def imageTag = "${BUILD_NUMBER}"
                        sh "docker push ${IMAGE_NAME}:${imageTag}"
                        sh 'docker logout https://gcr.io'
                    }
                }
            }
        }

        // 🔹 Deploy to Kubernetes (optional)
        stage('Deploy to Kubernetes (optional)') {
            agent any
            when {
                expression { env.DEPLOY_TO_K8S == 'true' }
            }
            steps {
                script {
                    def imageTag = "${BUILD_NUMBER}"
                    sh "kubectl set image deployment/simple-java-app simple-java-app=${IMAGE_NAME}:${imageTag} -n default"
                }
            }
        }
    }

    post {
        failure {
            sh 'docker rmi $(docker images -q ${IMAGE_NAME}) || true'
        }
    }
}
