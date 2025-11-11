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
    stage('Checkout') { steps { checkout scm } }

    stage('Build (Maven)')   { steps { container('maven') { sh 'mvn -B clean install -DskipTests' } } }
    stage('Test (Maven)')    { steps { container('maven') { sh 'mvn -B test' } } }
    stage('Package (Maven)') { steps { container('maven') { sh 'mvn -B package -DskipTests' } } }

    stage('Build & Push Image (Cloud Build)') {
      steps {
        container('cloud-sdk') {
          // Org blocks streaming; do async + poll.
          sh '''
            set -e
            gcloud config set project "$PROJECT_ID" >/dev/null
            BUILD_ID=$(gcloud builds submit \
              --project="$PROJECT_ID" \
              --tag "us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER" \
              --async --format='value(id)' .)

            # Poll until SUCCESS/FAIL
            while true; do
              S=$(gcloud builds describe "$BUILD_ID" --project="$PROJECT_ID" --format='value(status)')
              [ "$S" = "SUCCESS" ] && break
              case "$S" in FAILURE|CANCELLED|EXPIRED) echo "Cloud Build status: $S"; exit 1;; esac
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
            echo "Authenticating to GKE..."
            gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project="$PROJECT_ID"
            echo "Updating image..."
            kubectl set image deployment/simple-java-app simple-java-app="us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER"
            echo "Waiting for rollout..."
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
            if (!ip) { error("No External IP yet for simple-java-service") }
            def url = "http://${ip}:80"
            // Try once (matches your PDF); you can add retries later if you like
            def code = sh(script: "curl -s --max-time 5 -o /dev/null -w '%{http_code}' ${url}", returnStdout: true).trim()
            if (code != "200") { error("Health check failed, HTTP ${code}") }
          }
        }
      }
    }

    stage('Rollback') {
      when { expression { currentBuild.result == 'FAILURE' } }
      steps {
        container('cloud-sdk') {
          sh 'echo "Rolling back..." && kubectl rollout undo deployment/simple-java-app || true'
        }
      }
    }
  }

  // --- Slack notifications via Incoming Webhook (no plugin) ---
  post {
    success {
      withCredentials([string(credentialsId: 'SLACK_WEBHOOK', variable: 'SLACK_WEBHOOK')]) {
        sh '''
          set -e
          MSG="✅ *SUCCESS* ${JOB_NAME} #${BUILD_NUMBER}%0AImage: `${IMAGE}:${BUILD_NUMBER}`%0A${BUILD_URL}"
          curl -sS -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"${MSG}\"}" \
            "$SLACK_WEBHOOK" >/dev/null
        '''
      }
    }
    failure {
      withCredentials([string(credentialsId: 'SLACK_WEBHOOK', variable: 'SLACK_WEBHOOK')]) {
        sh '''
          set -e
          MSG="❌ *FAILED* ${JOB_NAME} #${BUILD_NUMBER}%0ARollback attempted on \`deployment/simple-java-app\`.%0A${BUILD_URL}"
          curl -sS -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"${MSG}\"}" \
            "$SLACK_WEBHOOK" >/dev/null
        '''
      }
    }
  }
}
