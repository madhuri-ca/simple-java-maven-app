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
        CLUSTER_NAME    = 'simple-cluster'
        CLUSTER_ZONE    = 'us-central1-a'
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

        stage('Clean Maven Repo') {
            steps {
                echo '🗑 Clearing local Maven repo cache...'
                sh 'rm -rf ~/.m2/repository/*'
            }
        }

        stage('Build with Maven') {
    steps {
        sh 'mvn -B clean package -DskipTests -Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts -Djavax.net.ssl.trustStorePassword=changeit'
    }
}

stage('Run Unit Tests') {
    steps {
        sh 'mvn test -Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts -Djavax.net.ssl.trustStorePassword=changeit'
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

        stage('Deploy to GKE') {
            steps {
                echo '🚀 Deploying application to GKE...'
                withCredentials([file(credentialsId: 'gcr-sa-json', variable: 'GCLOUD_KEY')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GCLOUD_KEY
                        gcloud config set project $PROJECT_ID
                        gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_ID

                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully and app deployed on GKE!'
        }
        failure {
            echo '❌ Build, test, or deploy stage failed!'
        }
    }
}
