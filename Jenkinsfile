pipeline {
    agent any

    environment {
        DEPLOY_NODE = "192.168.20.50"

        APP1 = "192.168.20.50"
        APP2 = "192.168.21.139"
        APP3 = "192.168.20.155"
    }

    stages {

        stage('Checkout') {
            steps {

                git branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/Shatrudhn/terrafom-aws-infra.git'
            }
        }

        stage('SSH Test - Deploy Node') {
            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    ssh -o StrictHostKeyChecking=no ubuntu@$DEPLOY_NODE "
                        echo '===== DEPLOY NODE =====';
                        hostname;
                        uptime;
                        df -h;
                    "
                    '''
                }
            }
        }

        stage('Validate All App Servers') {
            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    for server in \
                    $APP1 \
                    $APP2 \
                    $APP3
                    do

                        echo "=============================="
                        echo "Connecting to $server"
                        echo "=============================="

                        ssh -o StrictHostKeyChecking=no ubuntu@$server "

                            echo HOSTNAME:
                            hostname

                            echo
                            echo UPTIME:
                            uptime

                            echo
                            echo EFS:
                            findmnt | grep production-taxsutra

                            echo
                            echo DISK:
                            df -h

                        "

                    done
                    '''
                }
            }
        }
    }

    post {

        success {
            echo 'SSH validation successful on all app servers'
        }

        failure {
            echo 'Pipeline failed'
        }
    }
}
