pipeline {
    agent any

    environment {
        // Define Project and Image variables
        PROJECT_ID = 'internal-sandbox-446612'
        REPOSITORY_NAME = 'simple-java-app' 
        
        IMAGE_NAME = "gcr.io/${PROJECT_ID}/${REPOSITORY_NAME}"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        
        // Credentials IDs
        GCR_CRED_ID = 'gcr-json-key' // Ensure this ID exists in Jenkins
        KUBE_CRED_ID = 'kubeconfig-credentials-id' // Ensure this ID exists in Jenkins
    }

    stages {
        // 1. Checkout (Runs on 'agent any')
        stage('Checkout Source Code') {
            steps {
                echo 'Checking out source code from Git...'
                // Explicit 'git' step is kept, as it resolved your initial SCM errors.
                git url: 'https://github.com/madhuri-ca/simple-java-maven-app.git', branch: 'master'
            }
        }

        // 2. Build (Runs inside 'maven:3.8.7-jdk-11' Docker container)
        stage('Build with Maven') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11'
                    // 🌟 FIX for 'dubious ownership': Run container as root 🌟
                    args '-u root' 
                }
            }
            steps {
                echo 'Building the Maven project...'
                // Use 'package' to compile and create the JAR/WAR
                sh 'mvn -B clean package -DskipTests' 
            }
        }

        // 3. Unit Tests & Reports (Runs inside 'maven:3.8.7-jdk-11' Docker container)
        stage('Unit Tests & Reports') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11'
                    // 🌟 FIX for 'dubious ownership': Run container as root 🌟
                    args '-u root' 
                }
            }
            steps {
                echo 'Running unit tests...'
                sh 'mvn test'
                // Publish reports for Jenkins UI
                junit '**/target/surefire-reports/*.xml'
            }
        }

        // 4. Build Docker Image (Runs on 'agent any', requires 'docker' installed)
        stage('Build Docker Image') {
            agent any
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        // 5. Push Docker Image to GCR (Requires 'docker' and 'gcloud' installed on agent)
        stage('Push to GCR') {
            agent any
            steps {
                echo 'Logging in to GCR and pushing image...'
                
                // Use the GCR Service Account key for authentication
                withCredentials([file(credentialsId: GCR_CRED_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    // Activate service account and configure Docker for GCR access
                    sh '''
                        gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
                        gcloud auth configure-docker --quiet
                    '''
                }
                
                sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        // 6. Deploy to Kubernetes (Requires 'kubectl' installed on agent)
        stage('Deploy to Kubernetes') {
            agent any
            steps {
                echo 'Deploying to Kubernetes...'
                
                // Use Kubeconfig credentials
                withCredentials([file(credentialsId: KUBE_CRED_ID, variable: 'KUBECONFIG')]) {
                    // The KUBECONFIG variable is automatically used by kubectl
                    sh "kubectl set image deployment/simple-java-app simple-java-app=${IMAGE_NAME}:${IMAGE_TAG} --record"
                    sh "kubectl rollout status deployment/simple-java-app"
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed.'
        }
    }
}
