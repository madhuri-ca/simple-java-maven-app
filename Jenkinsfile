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
            echo "Submitting build to Cloud Build..."
            gcloud builds submit \
              --project=$PROJECT_ID \
              --tag us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER .
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

    stage('Health Check') {
      steps {
        container('cloud-sdk') {
          script {
            echo "Fetching external IP of service simple-java-service..."
            def externalIP = sh(script: "kubectl get svc simple-java-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()

            if (!externalIP) {
              error("❌ Could not fetch External IP for simple-java-service. Check if service type is LoadBalancer.")
            }

            def appUrl = "http://${externalIP}:80"
            echo "Health check URL: ${appUrl}"

            def statusCode = sh(script: "curl -s -o /dev/null -w '%{http_code}' ${appUrl}", returnStdout: true).trim()

            if (statusCode != "200") {
              error("❌ Health check failed. Got status code: ${statusCode}")
            } else {
              echo "✅ Health check passed with 200 OK"
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
            echo "⚠️ Rolling back deployment..."
            kubectl rollout undo deployment/simple-java-app
          '''
        }
      }
    }
  }
}
