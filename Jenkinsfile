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

 stage('Build & Push Image (Cloud Build)') {
    steps {
        container('cloud-sdk') {
            sh '''
              echo "Submitting build to Cloud Build..."
              gcloud builds submit \
                --project=$PROJECT_ID \
                --tag us-central1-docker.pkg.dev/$PROJECT_ID/jenkins-repo/simple-java-app:$BUILD_NUMBER \
                --no-source
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
        sh '''
          echo "Deploying to GKE..."
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
