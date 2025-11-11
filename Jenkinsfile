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
      steps { container('maven') { sh 'mvn clean install -DskipTests' } }
    }

    stage('Test (Maven)') {
      steps { container('maven') { sh 'mvn test' } }
    }

    stage('Package (Maven)') {
      steps { container('maven') { sh 'mvn package -DskipTests' } }
    }

    stage('Build & Push Image (Cloud Build)') {
      steps {
        container('cloud-sdk') {
          sh '''
            echo "Submitting build..."
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
            gcloud container clusters get-credentials $CLUSTER --zone $ZONE --project=$PROJECT_ID
            kubectl set image deployment/simple-java-app simple-java-app=us-central1-docker.pkg.dev/$PROJECT_ID/$REPO/$IMAGE:$BUILD_NUMBER
            kubectl rollout status deployment/simple-java-app
          '''
        }
      }
    }

    stage('Health Check') {
      steps {
        container('cloud-sdk') {
          script {
            def ip = sh(script: "kubectl get svc simple-java-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'", returnStdout: true).trim()
            if (!ip) { error("External IP not assigned") }

            def url = "http://${ip}:80"
            def sc = sh(script: "curl -s -o /dev/null -w '%{http_code}' ${url}", returnStdout: true).trim()
            if (sc != "200") { error("Health check failed: HTTP ${sc}") }
          }
        }
      }
    }

    stage('Rollback') {
      when { expression { currentBuild.result == 'FAILURE' } }
      steps {
        container('cloud-sdk') {
          sh 'kubectl rollout undo deployment/simple-java-app'
        }
      }
    }
  }

  post {
    success {
      withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_WEBHOOK')]) {
        sh '''
          curl -X POST -H 'Content-type: application/json' \
          --data "{\"text\":\"✅ SUCCESS: ${JOB_NAME} #${BUILD_NUMBER} deployed successfully\"}" \
          $SLACK_WEBHOOK
        '''
      }
    }

    failure {
      withCredentials([string(credentialsId: 'slack-webhook', variable: 'SLACK_WEBHOOK')]) {
        sh '''
          curl -X POST -H 'Content-type: application/json' \
          --data "{\"text\":\"❌ FAILURE: ${JOB_NAME} #${BUILD_NUMBER} failed. Rollback executed.\"}" \
          $SLACK_WEBHOOK
        '''
      }
    }
  }
}
