pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Checkout code from GitHub master branch
                git url: 'https://github.com/madhuri-ca/simple-java-maven-app.git', branch: 'master'
            }
        }
    }

    post {
        success {
            echo 'Git checkout completed successfully!'
        }
        failure {
            echo 'Git checkout failed.'
        }
    }
}

