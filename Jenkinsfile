pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: maven
    image: maven:3.9.6-eclipse-temurin-21
    command:
    - cat
    tty: true
  - name: cloud-sdk
    image: google/cloud-sdk:slim
    command:
    - cat
    tty: true
"""
    }
  }
  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }
    stage('Build & Push Image (Cloud Build)') {
      steps {
        container('cloud-sdk') {
          sh '''
            gcloud builds submit \
              --project=$PROJECT_ID \
              --tag us-central1-docker.pkg.dev/$PROJECT_ID/jenkins-repo/simple-java-app:$BUILD_NUMBER \
              .
          '''
        }
      }
    }
    stage('Deploy to GKE') {
      steps {
        container('cloud-sdk') {
          sh "kubectl apply -f k8s/deployment.yaml"
          sh "kubectl apply -f k8s/service.yaml"
        }
      }
    }
  }
}
