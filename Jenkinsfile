pipeline {
    agent any

    tools {
    jdk 'Java-21'
    maven 'Maven-3.9.11'
}


    environment {
        PROJECT_ID      = 'internal-sandbox-446612'
        REPOSITORY_NAME = 'simple-java-maven-app'
        IMAGE_NAME      = "gcr.io/${PROJECT_ID}/${REPOSITORY_NAME}"
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Clean Workspace') {
            steps {
                echo '🧹 Cleaning workspace...'
                deleteDir()
            }
        }

        stage('Checkout Source Code') {
            steps {
                echo '📦 Checking out source code...'
                git url: 'https://github.com/madhuri-ca/simple-java-maven-app.git', branch: 'master'
            }
        }

        stage('Build with Maven') {
            steps {
                echo '⚙️ Building the Maven project...'
                sh '''
                  mvn -B clean package -DskipTests \
                    -Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts \
                    -Djavax.net.ssl.trustStorePassword=changeit
                '''
            }
        }

        stage('Run Unit Tests') {
            steps {
                echo '🧪 Running unit tests...'
                sh '''
                  mvn test \
                    -Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts \
                    -Djavax.net.ssl.trustStorePassword=changeit
                '''
                junit '**/target/surefire-reports/*.xml'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                echo '🐳 Building and pushing Docker image to GCR...'
                withCredentials([file(credentialsId: 'gcr-sa-json', variable: 'GCLOUD_KEY')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GCLOUD_KEY
                        gcloud auth configure-docker gcr.io -q
                        docker build -t $IMAGE_NAME:$IMAGE_TAG -t $IMAGE_NAME:latest .
                        docker push $IMAGE_NAME:$IMAGE_TAG
                        docker push $IMAGE_NAME:latest
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Build or test stage failed!'
        }
    }
}
