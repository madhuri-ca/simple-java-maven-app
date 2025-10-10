pipeline {
    agent any // The default agent for the initial checkout

    environment {
        // Define key variables used in subsequent stages
        PROJECT_ID = 'internal-sandbox-446612'
        REPOSITORY_NAME = 'simple-java-app' 
        IMAGE_NAME = "gcr.io/${PROJECT_ID}/${REPOSITORY_NAME}"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
    }

    stages {
        // 1. Checkout (The Necessary First Step)
        stage('Checkout Source Code') {
            steps {
                echo 'Checking out source code from Git...'
                // Explicit checkout step to ensure code is present
                git url: 'https://github.com/madhuri-ca/simple-java-maven-app.git', branch: 'master'
            }
        }

        // 2. Build (Corrected to use Docker and Git fix)
        stage('Build with Maven') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11' // Provides the 'mvn' command
                    args '-u root' // Helps with initial permissions
                }
            }
            steps {
                // 🌟 CRITICAL FIX: Resolves the "fatal: detected dubious ownership" error
                sh 'git config --global --add safe.directory $PWD || true' 

                echo 'Building the Maven project...'
                sh 'mvn -B clean package -DskipTests' 
            }
        }

        // 3. Unit Tests & Reports (Corrected to use Docker and Git fix)
        stage('Unit Tests & Reports') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11'
                    args '-u root' 
                }
            }
            steps {
                // 🌟 CRITICAL FIX: Repeated for the new Docker agent context
                sh 'git config --global --add safe.directory $PWD || true' 
                
                echo 'Running unit tests...'
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml' // Generates test reports
            }
        }
        
        // ... (Remaining Stages: Build Docker Image, Push to GCR, Deploy to Kubernetes)
        // You would place the rest of your pipeline stages here.
        
    }
    
    // The Necessary Last Step (Post-build actions)
    post {
        success {
            echo '✅ Pipeline execution of Maven stages succeeded.'
        }
        failure {
            echo '❌ Maven or Checkout stage failed.'
        }
    }
}
