pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Checkout code from GitHub master branch
                git url: 'https://github.com/madhuri-ca/simple-java-maven-app.git', branch: 'master'
            }
        }

        stage('Build') {
            steps {
                // Example build step (if Maven project)
                sh 'mvn clean install'
            }
        }

        stage('Test') {
            steps {
                // Example test step
                sh 'mvn test'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
