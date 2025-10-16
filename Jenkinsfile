pipeline {
  agent none

  environment {
    PROJECT_ID   = 'internal-sandbox-446612'
    REGION       = 'us-central1'
    REPO         = 'jenkins-repo'
    IMAGE_NAME   = 'simple-java-app'
    AR_IMAGE     = "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE_NAME}"
  }

  stages {
    stage('Checkout') {
      agent any
      steps {
        checkout scm
      }
    }

    stage('Build with Maven (Java 21)') {
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
    command: ['cat']
    tty: true
"""
        }
      }
      steps {
        container('maven') {
          sh 'mvn clean package -DskipTests'
        }
      }
    }

    stage('Unit Tests') {
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
    command: ['cat']
    tty: true
"""
        }
      }
      steps {
        container('maven') {
          sh 'mvn test'
          junit '**/target/surefire-reports/*.xml'
        }
      }
    }

    stage('Build Docker Image') {
      agent {
        kubernetes {
          yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: docker
    image: gcr.io/cloud-builders/docker
    command: ['cat']
    tty: true
"""
        }
      }
      steps {
        container('docker') {
          sh '''
            echo "Building Docker image..."
            docker build -t ${AR_IMAGE}:${BUILD_NUMBER} .
          '''
        }
      }
    }

    stage('Push to Artifact Registry') {
      agent {
        kubernetes {
          yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: docker
    image: gcr.io/cloud-builders/docker
    command: ['cat']
    tty: true
  - name: cloud-sdk
    image: google/cloud-sdk:slim
    command: ['cat']
    tty: true
"""
        }
      }
      steps {
        container('cloud-sdk') {
          sh '''
            echo "Authenticating and pushing image..."
            gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet
          '''
        }
        container('docker') {
          sh '''
            docker push ${AR_IMAGE}:${BUILD_NUMBER}
            docker tag ${AR_IMAGE}:${BUILD_NUMBER} ${AR_IMAGE}:latest
            docker push ${AR_IMAGE}:latest
          '''
        }
      }
    }

    stage('Deploy to GKE') {
      agent {
        kubernetes {
          yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: cloud-sdk
    image: google/cloud-sdk:slim
    command: ['cat']
    tty: true
"""
        }
      }
      steps {
        container('cloud-sdk') {
          sh '''
            echo "Deploying to GKE..."
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/service.yaml

            kubectl set image deployment/simple-java-app \
              simple-java-app=${AR_IMAGE}:${BUILD_NUMBER}

            kubectl rollout status deployment/simple-java-app
          '''
        }
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline finished successfully."
    }
    failure {
      echo "❌ Pipeline failed. Check logs."
    }
  }
}
