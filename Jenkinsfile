pipeline {
    agent any

    tools {
        jdk 'Java-21'
        maven 'Maven-3.9.11'
    }

    environment {
        // Project details (ready for later Docker/GCR use)
        PROJECT_ID      = 'internal-sandbox-446612'
        REPOSITORY_NAME = 'simple-java-maven-app'

        // Future Docker image (not used yet in this phase)
        IMAGE_NAME = "gcr.io/${PROJECT_ID}/${REPOSITORY_NAME}"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
    }

    stages {
        // 1. Checkout
        stage('Checkout Source Code') {
            steps {
                echo '📦 Checking out source code from GitHub...'
                git url: 'https://github.com/madhuri-ca/simple-java-maven-app.git', branch: 'master'
            }
        }

        // 2. Build
        stage('Build with Maven') {
            steps {
                echo '⚙️ Building the Maven project...'
                sh 'mvn -B clean package -DskipTests'
            }
        }

        // 3. Test
        stage('Run Unit Tests') {
            steps {
                echo '🧪 Running unit tests...'
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }
    }

    post {
        success {
            echo '✅ Build and test stages completed successfully!'
        }
        failure {
            echo '❌ Build or test stage failed!'
        }
    }
}
