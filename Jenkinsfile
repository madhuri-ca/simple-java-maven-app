pipeline {
  agent any

  tools {
    jdk 'Java-21'          // name you gave in Jenkins
    maven 'Maven-3.9.11'   // name you gave in Jenkins
  }

  environment {
    PROJECT_ID   = 'internal-sandbox-446612'
    REGION       = 'us-central1'
    REPO         = 'jenkins-repo'
    IMAGE_NAME   = 'simple-java-app'
    AR_IMAGE     = "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE_NAME}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build with Maven') {
      steps {
        sh 'mvn clean package -DskipTests'
      }
    }

    stage('Unit Tests') {
      steps {
        sh 'mvn test'
        junit '**/target/surefire-reports/*.xml'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          echo "Building Docker image..."
          docker build -t ${AR_IMAGE}:${BUILD_NUMBER} .
        '''
      }
    }

    stage('Push to Artifact Registry') {
      steps {
        sh '''
          echo "Pushing image to Artifact Registry..."
          gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet
          docker push ${AR_IMAGE}:${BUILD_NUMBER}
          docker tag ${AR_IMAGE}:${BUILD_NUMBER} ${AR_IMAGE}:latest
          docker push ${AR_IMAGE}:latest
        '''
      }
    }

    stage('Deploy to GKE') {
      steps {
        sh '''
          echo "Deploying to GKE..."
          kubectl apply -f k8s/deployment.yaml
          kubectl apply -f k8s/service.yaml

          kubectl set image deployment/simple-java-app \
            simple-java-app=${AR_IMAGE}:${BUILD_NUMBER}

          kubectl rollout status deployment/simple-java-app
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline finished successfully."
    }
    failure {
      echo "❌ Pipeline failed. Check logs."
    }
  }
}
