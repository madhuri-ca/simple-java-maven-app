pipeline {
    agent any 

    environment {
        PROJECT_ID = 'internal-sandbox-446612'
        REPOSITORY_NAME = 'simple-java-app' 
        IMAGE_NAME = "gcr.io/${PROJECT_ID}/${REPOSITORY_NAME}"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        GCR_CRED_ID = 'gcr-json-key' 
        KUBE_CRED_ID = 'kubeconfig-credentials-id' 
    }

    stages {
        // 1. Checkout Source
        stage('Checkout Source Code') {
            steps {
                echo 'Checking out source code from Git...'
                // 🔧 Add safety line before using git
                sh 'git config --global --add safe.directory $PWD || true'
                
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
                // 🔧 Add safety line again (new Docker agent = new workspace)
                sh 'git config --global --add safe.directory $PWD || true'

                echo 'Building the Maven project...'
                sh 'mvn -B clean package -DskipTests' 
            }
        }

        // 3. Unit Tests & Reports
        stage('Unit Tests & Reports') {
            agent {
                docker {
                    image 'maven:3.8.7-jdk-11'
                    args '-u root'
                }
            }
            steps {
                // 🔧 Add safety line again
                sh 'git config --global --add safe.directory $PWD || true'

                echo 'Running unit tests...'
                sh 'mvn test'
                junit '**/target/surefire-reports/*.xml'
            }
        }

        // 4. Build Docker Image
        stage('Build Docker Image') {
            agent any
            steps {
                // 🔧 Add safety line again
                sh 'git config --global --add safe.directory $PWD || true'

                echo 'Building Docker image...'
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        // 5. Push to GCR
        stage('Push to GCR') {
            agent any
            steps {
                // 🔧 Add safety line again
                sh 'git config --global --add safe.directory $PWD || true'

                echo 'Logging in to GCR and pushing image...'
                withCredentials([file(credentialsId: GCR_CRED_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS
                        gcloud auth configure-docker --quiet
                    '''
                }
                sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        // 6. Deploy to Kubernetes
        stage('Deploy to Kubernetes') {
            agent any
            steps {
                // 🔧 Add safety line again
                sh 'git config --global --add safe.directory $PWD || true'

                echo 'Deploying to Kubernetes...'
                withCredentials([file(credentialsId: KUBE_CRED_ID, variable: 'KUBECONFIG')]) {
                    sh "kubectl set image deployment/simple-java-app simple-java-app=${IMAGE_NAME}:${IMAGE_TAG} --record"
                    sh "kubectl rollout status deployment/simple-java-app"
                }
            }
        }
    }

    post {
        success { echo '✅ Pipeline completed successfully!' }
        failure { echo '❌ Pipeline failed.' }
    }
}
