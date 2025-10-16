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
    image: google/cloud-sdk:latest   # ✅ use full image with kubectl included
    command:
    - cat
    tty: true
"""
    }
  }

  environment {
    PROJECT_ID = "internal-sandbox-446612"   // 🔹 your project id
    REGION     = "us-central1"
    CLUSTER    = "your-gke-cluster-name"     // 🔹 replace with your cluster name
    ZONE       = "us-central1-a"             // 🔹 or your GKE zone
    REPO       = "jenkins-repo"
    IMAGE      = "simple-java-app"
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
            echo "Submitting build to Cloud Build (async)..."
            gcloud builds submit \
              --project=$PROJECT_ID \
              --tag us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER \
              --async .
          '''
        }
      }
    }

    stage('Deploy to GKE') {
  steps {
    container('cloud-sdk') {
      sh '''
        echo "Authenticating to GKE..."
        gcloud container clusters get-credentials jenkins-cluster --zone us-central1-a --project=$PROJECT_ID
        kubectl apply -f k8s/deployment.yaml
        kubectl apply -f k8s/service.yaml
      '''
    }
  }
}
