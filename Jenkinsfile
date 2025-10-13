pipeline {
    agent any

    environment {
        // These are placeholders for future use (e.g., when you add Docker/GCR)
        PROJECT_ID = 'internal-sandbox-446612'
        REPOSITORY_NAME = 'simple-java-maven-app'
    }

    stages {
        // 1. Checkout the source code
        stage('Checkout Source Code') {
            steps {
                echo '📦 Checking out source code from GitHub...'
                git url: 'https://github.com/madhuri-ca/simple-java-maven-app.git', branch: 'master'
            }
        }

        // 2. Build with Maven
        stage('Build with Maven') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11'
                    args '-u root'
                }
            }
            steps {
                echo '⚙️ Building the Maven project...'
                sh 'mvn -B clean package -DskipTests'
            }
        }

        // 3. Run Unit Tests
        stage('Run Unit Tests') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11'
                    args '-u root'
                }
            }
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
