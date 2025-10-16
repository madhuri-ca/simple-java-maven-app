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

  environment {
    PROJECT_ID = "internal-sandbox-446612"   // 🔹 set your project id here
    REGION = "us-central1"
    REPO = "jenkins-repo"
    IMAGE = "simple-java-app"
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
            echo "Using project: $PROJECT_ID"
            gcloud config set project $PROJECT_ID

            gcloud builds submit \
              --project=$PROJECT_ID \
              --tag $REGION-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER \
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
