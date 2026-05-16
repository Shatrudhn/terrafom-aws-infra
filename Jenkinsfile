pipeline {

    agent any

    environment {

        // Deploy Node
        DEPLOY_NODE = "192.168.20.50"

        // Application Servers
        APP1 = "192.168.20.50"
        APP2 = "192.168.21.139"
        APP3 = "192.168.20.155"

        // Deployment Paths
        BASE_PATH = "/var/www/production-taxsutra"

        RELEASES_PATH = "/var/www/production-taxsutra/releases"

        CURRENT_PATH = "/var/www/production-taxsutra/current"

        SHARED_PATH = "/var/www/production-taxsutra/shared"

        // Release Number
        RELEASE = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout Code') {

            steps {

                git branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/Shatrudhn/terrafom-aws-infra.git'
            }
        }

        stage('Validate App Servers') {

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

        stage('Prepare Deployment Structure') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    ssh -o StrictHostKeyChecking=no ubuntu@$DEPLOY_NODE "

                        mkdir -p ${RELEASES_PATH}/${RELEASE}

                        mkdir -p ${SHARED_PATH}/files

                        mkdir -p ${SHARED_PATH}/sites

                        sudo chown -R ubuntu:ubuntu ${BASE_PATH}

                        sudo chmod -R 755 ${BASE_PATH}

                        echo '===== Deployment Structure ====='

                        tree -L 2 ${BASE_PATH}

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
                    --delete \
                    --exclude=.git \
                    --exclude=.terraform \
                    --exclude=.terraform.lock.hcl \
                    --exclude=terraform.tfstate \
                    --exclude=terraform.tfstate.backup \
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

                        echo '===== Uploaded Files ====='

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

                        rm -rf ${CURRENT_PATH}

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

                        echo '===== Current Symlink ====='

                        ls -ltr ${CURRENT_PATH}

                    "
                    '''
                }
            }
        }

        stage('Validate Deployment On All Servers') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    for server in \
                    $APP1 \
                    $APP2 \
                    $APP3
                    do

                        echo "======================================"
                        echo "Deployment Validation On: $server"
                        echo "======================================"

                        ssh -o StrictHostKeyChecking=no ubuntu@$server "

                            echo
                            echo CURRENT STRUCTURE:
                            ls -ltr ${BASE_PATH}

                            echo
                            echo CURRENT RELEASE:
                            ls -ltr ${CURRENT_PATH}

                            echo
                            echo EFS:
                            findmnt | grep production-taxsutra

                        "

                    done
                    '''
                }
            }
        }

        stage('Validate Nginx Configuration') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    for server in \
                    $APP1 \
                    $APP2 \
                    $APP3
                    do

                        echo "======================================"
                        echo "Validating nginx on: $server"
                        echo "======================================"

                        ssh -o StrictHostKeyChecking=no ubuntu@$server "

                            sudo nginx -t

                        "

                    done
                    '''
                }
            }
        }

        stage('Reload Nginx') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    for server in \
                    $APP1 \
                    $APP2 \
                    $APP3
                    do

                        echo "======================================"
                        echo "Reloading nginx on: $server"
                        echo "======================================"

                        ssh -o StrictHostKeyChecking=no ubuntu@$server "

                            sudo systemctl reload nginx

                        "

                    done
                    '''
                }
            }
        }

        stage('Local Application Validation') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    for server in \
                    $APP1 \
                    $APP2 \
                    $APP3
                    do

                        echo "======================================"
                        echo "Testing Application On: $server"
                        echo "======================================"

                        ssh -o StrictHostKeyChecking=no ubuntu@$server "

                            curl -I localhost

                        "

                    done
                    '''
                }
            }
        }

        stage('ALB Health Check') {

            steps {

                sh '''
                curl -I http://taxsutra-alb-148605757.us-east-1.elb.amazonaws.com
                '''
            }
        }
    }

    post {

        success {

            echo 'Drupal deployment completed successfully'
        }

        failure {

            echo 'Drupal deployment failed'
        }
    }
}
