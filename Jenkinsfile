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
                    // Add timeout + no-stream
                    timeout(time: 10, unit: 'MINUTES') {
                        sh '''
                          echo "Submitting build to Cloud Build (no-stream)..."
                          gcloud builds submit \
                            --project=$PROJECT_ID \
                            --tag us-central1-docker.pkg.dev/$PROJECT_ID/jenkins-repo/simple-java-app:$BUILD_NUMBER \
                            --no-stream .
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
