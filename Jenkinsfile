pipeline {
  agent any

  tools {
    jdk 'JDK'              // must match your Jenkins Global Tool name
    maven 'Maven-3.9.11'   // must match your Jenkins Global Tool name
  }

  environment {
    PROJECT_ID = 'internal-sandbox-446612'
    REGION     = 'us-central1'
    REPO       = 'apps'
    IMAGE_NAME = "us-central1-docker.pkg.dev/${PROJECT_ID}/${REPO}/simple-java-app"
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
    K8S_DIR    = 'k8s'
    PATH       = "/google-cloud-sdk/bin:/usr/bin:${env.PATH}"
  }

  stages {
    stage('Clean') {
      steps { deleteDir() }
    }

    stage('Checkout') {
      steps {
        git url: 'https://github.com/madhuri-ca/simple-java-maven-app.git', branch: 'master'
      }
    }

    stage('Build & Test (Maven)') {
      steps {
        sh 'mvn -B clean test'
        junit '**/target/surefire-reports/*.xml'
      }
    }

    stage('Verify CLIs (optional)') {
      steps {
        sh 'which gcloud || echo "gcloud missing"'
        sh 'which kubectl || echo "kubectl missing"'
        sh 'gcloud --version || true'
        sh 'kubectl version --client || true'
      }
    }
        stage('Verify GCP Identity') {
      steps {
        sh '''
          echo "Checking active GCP identity..."
          gcloud auth list
          gcloud config list account
        '''
      }
    }

    stage('Build & Push Image (Cloud Build)') {
      steps {
        sh """
          echo "Building & pushing image with Google Cloud Build..."
          gcloud builds submit --tag ${IMAGE_NAME}:${IMAGE_TAG} .
        """
      }
    }

    stage('Deploy to GKE') {
      steps {
        sh """
          echo "Deploying to GKE..."
          kubectl apply -f ${K8S_DIR}/deployment.yaml
          kubectl apply -f ${K8S_DIR}/service.yaml
        """
      }
    }
  }

  post {
    success { echo '✅ Build+Push+Deploy succeeded' }
    failure { echo '❌ Check console logs' }
  }
}
