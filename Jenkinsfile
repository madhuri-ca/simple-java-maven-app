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
      steps { container('maven') { sh 'mvn -B clean install -DskipTests' } }
    }

    stage('Test (Maven)') {
      steps { container('maven') { sh 'mvn -B test' } }
    }

    stage('Package (Maven)') {
      steps { container('maven') { sh 'mvn -B package -DskipTests' } }
    }

    stage('Build & Push Image (Cloud Build)') {
      steps {
        container('cloud-sdk') {
          // keep it "short": your org blocks streaming, so we do async+poll silently
          sh '''
            set -e
            gcloud config set project $PROJECT_ID
            BUILD_ID=$(gcloud builds submit \
              --project=$PROJECT_ID \
              --tag us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER \
              --async --format='value(id)' .)
            until [ "$(gcloud builds describe "$BUILD_ID" --project=$PROJECT_ID --format='value(status)')" = "SUCCESS" ]; do
              STATUS=$(gcloud builds describe "$BUILD_ID" --project=$PROJECT_ID --format='value(status)')
              [ "$STATUS" = "FAILURE" -o "$STATUS" = "CANCELLED" -o "$STATUS" = "EXPIRED" ] && exit 1
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
            set -e
            gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project=$PROJECT_ID
            kubectl set image deployment/simple-java-app simple-java-app=us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER
            kubectl rollout status deployment/simple-java-app --timeout=180s
          '''
        }
      }
    }

    stage('Health Check') {
      steps {
        container('cloud-sdk') {
          script {
            def ip = sh(script: "kubectl get svc simple-java-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()
            if (!ip) error("No External IP yet for simple-java-service")
            def url = "http://${ip}:80"
            def code = sh(script: "curl -s --max-time 5 -o /dev/null -w '%{http_code}' ${url}", returnStdout: true).trim()
            if (code != "200") error("Health check failed, HTTP ${code}")
          }
        }
      }
    }

    stage('Rollback') {
      when { expression { currentBuild.result == 'FAILURE' } }
      steps {
        container('cloud-sdk') {
          sh 'kubectl rollout undo deployment/simple-java-app || true'
        }
      }
    }
  }

  post {
    success {
      slackSend channel: '#ci-cd',
        color: 'good',
        message: "✅ *SUCCESS* ${env.JOB_NAME} #${env.BUILD_NUMBER}\nDeployed image `${env.IMAGE}:${env.BUILD_NUMBER}` and passed health checks.\n${env.BUILD_URL}"
    }
    failure {
      slackSend channel: '#ci-cd',
        color: 'danger',
        message: "❌ *FAILED* ${env.JOB_NAME} #${env.BUILD_NUMBER}\nRollback attempted for `deployment/simple-java-app`.\n${env.BUILD_URL}"
    }
  }
}
