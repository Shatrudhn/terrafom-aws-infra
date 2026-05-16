pipeline {
    agent any

    environment {
        APP_SERVER = "192.168.20.50"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/Shatrudhn/terrafom-aws-infra.git'
            }
        }

        stage('SSH Test') {
            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    ssh -o StrictHostKeyChecking=no ubuntu@$APP_SERVER "
                        hostname;
                        uptime;
                        df -h
                    "
                    '''
                }
            }
        }
    }
}
