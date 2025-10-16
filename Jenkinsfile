pipeline {
  agent none

  environment {
    PROJECT_ID   = 'internal-sandbox-446612'   // your project ID
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

    stage('Build & Push (Cloud Build)') {
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
        sh '''
          echo "Submitting build to Cloud Build..."
          gcloud builds submit \
            --project="${PROJECT_ID}" \
            --tag "${AR_IMAGE}:${BUILD_NUMBER}" .

          gcloud artifacts docker tags add \
            "${AR_IMAGE}:${BUILD_NUMBER}" "${AR_IMAGE}:latest" || true
        '''
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

  post {
    success { echo "✅ Pipeline finished successfully." }
    failure { echo "❌ Pipeline failed. Check logs." }
  }
}
