pipeline {
  agent any

  tools {
    jdk 'JDK'           // must match your Global Tool name
    maven 'Maven-3.9.11'    // must match your Global Tool name
  }

  environment {
    PROJECT_ID   = 'internal-sandbox-446612'              // <-- replace
    REGION       = 'us-central1'
    REPO         = 'apps'                         // artifact registry repo name
    IMAGE_NAME   = "us-central1-docker.pkg.dev/${PROJECT_ID}/${REPO}/simple-java-app"
    IMAGE_TAG    = "${env.BUILD_NUMBER}"
    K8S_DIR      = 'k8s'
    PATH         = "/google-cloud-sdk/bin:/usr/bin:${env.PATH}"
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
        // these will show in logs; helpful for debugging
        sh 'which gcloud || echo "gcloud missing"'
        sh 'which kubectl || echo "kubectl missing"'
        sh 'gcloud --version || true'
        sh 'kubectl version --client || true'
      }
    }

    stage('Build & Push Image (Cloud Build)') {
      steps {
        // Workload Identity handles auth — no JSON key
        sh """
          gcloud config set project ${PROJECT_ID}
          gcloud builds submit --tag ${IMAGE_NAME}:${IMAGE_TAG} .
          gcloud container images add-tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest -q || true
        """
      }
    }

    stage('Deploy to GKE') {
      steps {
        sh """
          # Ensure kubectl is configured in-pod via Workload Identity (no keyfile)
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
