pipeline {
    agent any
    stages {
        stage('Debug SCM Checkout') {
            steps {
                echo "🔍 Checking if workspace has .git folder..."
                sh 'ls -la'
                echo "🔹 Running checkout manually now..."
                checkout scm
                echo "✅ Checkout complete, listing files:"
                sh 'ls -la'
            }
        }
    }
}
