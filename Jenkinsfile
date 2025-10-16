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
    image: maven:3.9.9-eclipse-temurin-21
    command:
    - cat
    tty: true
  - name: cloud-sdk
    image: google/cloud-sdk:latest   # includes gcloud + kubectl
    command:
    - cat
    tty: true
"""
    }
  }

  environment {
    PROJECT_ID = "internal-sandbox-446612"    // 🔹 your GCP project ID
    REGION     = "us-central1"
    CLUSTER    = "jenkins-cluster"            // 🔹 your cluster name
    ZONE       = "us-central1-a"              // 🔹 your cluster zone
    REPO       = "jenkins-repo"
    IMAGE      = "simple-java-app"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build (Maven)') {
      steps {
        container('maven') {
          sh 'mvn clean compile'
        }
      }
    }

    stage('Test (Maven)') {
      steps {
        container('maven') {
          sh 'mvn test'
        }
      }
    }

    stage('Package (Maven)') {
      steps {
        container('maven') {
          sh 'mvn package -DskipTests'
        }
      }
    }

    stage('Build & Push Image (Cloud Build)') {
  steps {
    container('cloud-sdk') {
      sh '''
        echo "Submitting build to Cloud Build..."
        gcloud builds submit \
          --project=$PROJECT_ID \
          --tag us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER \
          .
      '''
    }
  }
}


    stage('Deploy to GKE') {
  steps {
    container('cloud-sdk') {
      sh '''
        echo "Authenticating to GKE..."
        gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project=$PROJECT_ID

        echo "Updating image with current build number..."
        kubectl set image deployment/simple-java-app simple-java-app=us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER

        echo "Waiting for rollout..."
        kubectl rollout status deployment/simple-java-app
      '''
    }
  }
}

