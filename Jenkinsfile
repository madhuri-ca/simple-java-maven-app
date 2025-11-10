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
    image: google/cloud-sdk:latest
    command:
    - cat
    tty: true
"""
    }
  }

  environment {
    PROJECT_ID = "internal-sandbox-446612"
    REGION     = "us-central1"
    CLUSTER    = "jenkins-cluster"
    ZONE       = "us-central1-a"
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
          sh 'mvn clean install -DskipTests'
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
        set -e
        gcloud config set project $PROJECT_ID
        echo "Submitting build (async) to Cloud Build..."
        BUILD_ID=$(gcloud builds submit \
          --project=$PROJECT_ID \
          --tag us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER \
          --async \
          --format='value(id)' .)

        echo "Build ID: $BUILD_ID"
        # Poll until the build completes; do NOT stream logs
        while true; do
          STATUS=$(gcloud builds describe "$BUILD_ID" --project=$PROJECT_ID --format='value(status)')
          echo "Cloud Build status: $STATUS"
          if [ "$STATUS" = "SUCCESS" ]; then
            echo "Cloud Build finished successfully."
            break
          elif [ "$STATUS" = "FAILURE" ] || [ "$STATUS" = "CANCELLED" ] || [ "$STATUS" = "EXPIRED" ]; then
            echo "Cloud Build ended with status: $STATUS"
            exit 1
          fi
          sleep 5
        done
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
            
            echo "Updating image in deployment..."
            kubectl set image deployment/simple-java-app simple-java-app=us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER

            echo "Waiting for rollout..."
            kubectl rollout status deployment/simple-java-app
          '''
        }
      }
    }
  }
}
