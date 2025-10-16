pipeline {
    agent none   // no global agent

    stages {
        stage('Checkout') {
            agent { label 'default' }
            steps {
                checkout scm
            }
        }

        stage('Build & Push Image (Cloud Build)') {
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
    command:
    - cat
    tty: true
"""
        }
    }
    steps {
        container('cloud-sdk') {
            timeout(time: 15, unit: 'MINUTES') {
                sh '''
                  echo "Submitting build to Cloud Build (async)..."
                  BUILD_ID=$(gcloud builds submit \
                    --project=$PROJECT_ID \
                    --tag us-central1-docker.pkg.dev/$PROJECT_ID/jenkins-repo/simple-java-app:$BUILD_NUMBER \
                    --format='value(id)' --async .)

                  echo "Submitted Build ID: $BUILD_ID"

                  echo "Waiting for build to finish..."
                  gcloud builds wait $BUILD_ID --project=$PROJECT_ID
                '''
            }
        }
    }
}


        stage('Deploy to GKE') {
            agent { label 'default' }
            steps {
                sh "kubectl apply -f k8s/deployment.yaml"
                sh "kubectl apply -f k8s/service.yaml"
            }
        }
    }
}
