pipeline {
    agent any

    environment {

        // Deployment Node
        DEPLOY_NODE = "192.168.20.50"

        // All App Servers
        APP1 = "192.168.20.50"
        APP2 = "192.168.21.139"
        APP3 = "192.168.20.155"

        // Deployment Paths
        BASE_PATH = "/var/www/production-taxsutra"
        RELEASES_PATH = "/var/www/production-taxsutra/releases"
        CURRENT_PATH = "/var/www/production-taxsutra/current"
        SHARED_PATH = "/var/www/production-taxsutra/shared"

        // Build Release
        RELEASE = "${BUILD_NUMBER}"
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

                        echo '===== DEPLOY NODE ====='

                        hostname

                        uptime

                        df -h

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

                        echo "======================================"
                        echo "Validating Server: $server"
                        echo "======================================"

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

        stage('Create Release Directory') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    ssh -o StrictHostKeyChecking=no ubuntu@$DEPLOY_NODE "

                        mkdir -p ${RELEASES_PATH}/${RELEASE}

                        mkdir -p ${SHARED_PATH}/files

                        mkdir -p ${SHARED_PATH}/sites

                        echo 'Release Directory Created'

                        ls -ltr ${RELEASES_PATH}

                    "
                    '''
                }
            }
        }

        stage('Upload Application Code') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    rsync -avz \
                    --exclude=.git \
                    --exclude=.terraform \
                    --exclude=terraform.tfstate \
                    --exclude=terraform.tfstate.backup \
                    --exclude=.terraform.lock.hcl \
                    -e "ssh -o StrictHostKeyChecking=no" \
                    ./ \
                    ubuntu@$DEPLOY_NODE:${RELEASES_PATH}/${RELEASE}/
                    '''
                }
            }
        }

        stage('Validate Uploaded Files') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    ssh -o StrictHostKeyChecking=no ubuntu@$DEPLOY_NODE "

                        echo '===== Uploaded Release ====='

                        ls -ltr ${RELEASES_PATH}/${RELEASE}

                    "
                    '''
                }
            }
        }

        stage('Switch Current Release') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    ssh -o StrictHostKeyChecking=no ubuntu@$DEPLOY_NODE "

                        ln -sfn \
                        ${RELEASES_PATH}/${RELEASE} \
                        ${CURRENT_PATH}

                        echo '===== Current Release ====='

                        ls -ltr ${BASE_PATH}

                    "
                    '''
                }
            }
        }

        stage('Validate Current Symlink') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    ssh -o StrictHostKeyChecking=no ubuntu@$DEPLOY_NODE "

                        readlink -f ${CURRENT_PATH}

                    "
                    '''
                }
            }
        }
    }

    post {

        success {

            echo 'Drupal deployment pipeline validation successful'
        }

        failure {

            echo 'Pipeline failed'
        }
    }
}
