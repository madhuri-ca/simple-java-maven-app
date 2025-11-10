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
    command: ["cat"]
    tty: true
  - name: cloud-sdk
    image: google/cloud-sdk:latest
    command: ["cat"]
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
      steps { checkout scm }
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
            echo "Polling build status (no log streaming)..."

            while true; do
              STATUS=$(gcloud builds describe "$BUILD_ID" --project=$PROJECT_ID --format='value(status)')
              echo "Cloud Build status: $STATUS"
              if [ "$STATUS" = "SUCCESS" ]; then
                echo "Cloud Build finished successfully."
                break
              elif [ "$STATUS" = "FAILURE" ] || [ "$STATUS" = "CANCELLED" ] || [ "$STATUS" = "EXPIRED" ]; then
                echo "Cloud Build failed with status: $STATUS"
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

            echo "Updating image in Deployment..."
            kubectl set image deployment/simple-java-app simple-java-app=us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER

            echo "Waiting for rollout..."
            kubectl rollout status deployment/simple-java-app
          '''
        }
      }
    }

    stage('Health Check') {
      steps {
        container('cloud-sdk') {
          script {
            echo "Fetching external IP..."
            def externalIP = sh(script: "kubectl get svc simple-java-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()

            if (!externalIP) {
              error("ERROR: External IP not assigned. Check LoadBalancer status.")
            }

            def url = "http://${externalIP}:80"
            echo "Health Check URL: ${url}"

            def statusCode = sh(script: "curl -s -o /dev/null -w '%{http_code}' ${url}", returnStdout: true).trim()

            if (statusCode != "200") {
              error("Health Check FAILED. Status: ${statusCode}")
            } else {
              echo "Health Check PASSED (200 OK)"
            }
          }
        }
      }
    }

    stage('Rollback') {
      when {
        expression { currentBuild.result == 'FAILURE' }
      }
      steps {
        container('cloud-sdk') {
          sh '''
            echo "Rolling back Deployment..."
            kubectl rollout undo deployment/simple-java-app
          '''
        }
      }
    }

  } 
  
  // end stages
  post {
    success {
      slackSend(
        channel: '#your-slack-channel',
        color: 'good',
        message: "✅ SUCCESS: ${env.JOB_NAME} (#${env.BUILD_NUMBER}) has been deployed and passed health checks."
      )
    }
    failure {
      slackSend(
        channel: '#your-slack-channel',
        color: 'danger',
        message: "❌ FAILED: ${env.JOB_NAME} (#${env.BUILD_NUMBER}). Rollback executed if applicable."
      )
    }
  }

}
