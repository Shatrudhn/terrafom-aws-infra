pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/Shatrudhn/terrafom-aws-infra.git'
            }
        }

        stage('Test') {
            steps {
                sh 'pwd'
                sh 'ls -ltr'
            }
        }
    }
}
