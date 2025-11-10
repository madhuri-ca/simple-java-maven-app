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
            # Timeout after ~12 minutes (144 * 5s)
            ATTEMPTS=0
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
              ATTEMPTS=$((ATTEMPTS+1))
              if [ $ATTEMPTS -gt 144 ]; then
                echo "Cloud Build timed out while polling."
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
            set -e
            echo "Authenticating to GKE..."
            gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project=$PROJECT_ID

            echo "Updating image in Deployment..."
            kubectl set image deployment/simple-java-app simple-java-app=us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER

            echo "Waiting for rollout..."
            kubectl rollout status deployment/simple-java-app --timeout=180s
          '''
        }
      }
    }

    stage('Wait for Service External IP') {
      steps {
        container('cloud-sdk') {
          sh '''
            set -e
            echo "Waiting for LoadBalancer External IP..."
            for i in $(seq 1 60); do
              EXTERNAL_IP=$(kubectl get svc simple-java-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
              if [ -n "$EXTERNAL_IP" ]; then
                echo "External IP: $EXTERNAL_IP"
                break
              fi
              echo "Still pending... ($i/60)"
              sleep 5
            done
            [ -n "$EXTERNAL_IP" ] || { echo "Timed out waiting for External IP"; exit 1; }
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

            // Retry up to 10 times (50s) for pod warmup/app startup
            def ok = false
            for (int i = 0; i < 10; i++) {
              def statusCode = sh(script: "curl -s --max-time 5 -o /dev/null -w '%{http_code}' ${url}", returnStdout: true).trim()
              echo "Probe ${i+1}/10 -> HTTP ${statusCode}"
              if (statusCode == "200") { ok = true; break }
              sleep 5
            }
            if (!ok) {
              error("Health Check FAILED after retries.")
            } else {
              echo "Health Check PASSED (200 OK)."
            }
          }
        }
      }
    }
  } // stages

  post {
    success {
      // Slack webhook (no plugin)
      withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_WEBHOOK')]) {
        sh '''
          curl -s -X POST -H 'Content-type: application/json' \
          --data "$(jq -n --arg t \"✅ SUCCESS: ${JOB_NAME} #${BUILD_NUMBER} deployed & healthy\" --arg u \"${BUILD_URL}\" '{text: ($t + "\\n" + $u)}')" \
          "$SLACK_WEBHOOK" >/dev/null || true
        '''
      }
    }
    failure {
      // Rollback first
      container('cloud-sdk') {
        sh '''
          echo "Rolling back Deployment..."
          kubectl rollout undo deployment/simple-java-app || true
        '''
      }
      // Slack webhook (no plugin)
      withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_WEBHOOK')]) {
        sh '''
          curl -s -X POST -H 'Content-type: application/json' \
          --data "$(jq -n --arg t \"❌ FAILED: ${JOB_NAME} #${BUILD_NUMBER}. Rollback executed.\" --arg u \"${BUILD_URL}\" '{text: ($t + "\\n" + $u)}')" \
          "$SLACK_WEBHOOK" >/dev/null || true
        '''
      }
    }
  }
}
