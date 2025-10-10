pipeline {
    agent any

    stages {
        stage('Prepare Git') {
            steps {
                // Mark the Jenkins workspace as a safe directory for Git
                sh 'git config --global --add safe.directory $WORKSPACE'
            }
        }

        stage('Checkout') {
            steps {
                // Checkout code from GitHub master branch
                git url: 'https://github.com/madhuri-ca/simple-java-maven-app.git', branch: 'master'
            }
        }

        stage('Build') {
            steps {
                // Build the Maven project
                sh 'mvn clean install'
            }
        }

        stage('Test') {
            steps {
                // Run Maven tests
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
