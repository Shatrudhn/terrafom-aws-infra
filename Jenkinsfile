pipeline {

    agent any

    environment {

        // Deploy Node
        DEPLOY_NODE = "192.168.20.50"

        // App Servers
        APP1 = "192.168.20.50"
        APP2 = "192.168.21.139"
        APP3 = "192.168.20.155"

        // Deployment Paths
        BASE_PATH = "/var/www/production-taxsutra"

        RELEASES_PATH = "/var/www/production-taxsutra/releases"

        CURRENT_PATH = "/var/www/production-taxsutra/current"

        SHARED_PATH = "/var/www/production-taxsutra/shared"

        // Release Version
        RELEASE = "${BUILD_NUMBER}"

        // ALB DNS
        ALB_URL = "http://taxsutra-alb-148605757.us-east-1.elb.amazonaws.com"
    }

    options {

        timestamps()

        disableConcurrentBuilds()

        buildDiscarder(logRotator(numToKeepStr: '10'))
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

                            hostname

                            uptime

                            findmnt | grep production-taxsutra

                            df -h

                        "

                    done
                    '''
                }
            }
        }

        /*
        stage('Composer Install') {

            steps {

                sh '''
                composer install \
                --no-dev \
                --optimize-autoloader
                '''
            }
        }

        stage('Drupal Validation') {

            steps {

                sh '''
                php -v

                composer validate
                '''
            }
        }
        */

        stage('Prepare Release Structure') {

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

        stage('Deploy To EFS') {

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

        stage('Validate Deployment Files') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    ssh -o StrictHostKeyChecking=no ubuntu@$DEPLOY_NODE "

                        echo '===== Release Files ====='

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

                        echo '===== Active Release ====='

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

                        ls -ltr ${CURRENT_PATH}

                    "
                    '''
                }
            }
        }

        stage('Validate nginx Configuration') {

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

        stage('Reload nginx') {

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

        /*
        stage('Drupal Cache Rebuild') {

            steps {

                sshagent(credentials: ['app-server-key']) {

                    sh '''
                    ssh -o StrictHostKeyChecking=no ubuntu@$DEPLOY_NODE "

                        cd ${CURRENT_PATH}

                        if [ -f vendor/bin/drush ]
                        then

                            vendor/bin/drush cr

                        else

                            echo 'Drush not installed yet'

                        fi

                    "
                    '''
                }
            }
        }
        /*
        
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
                        echo "Application Validation On: $server"
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
                curl -I ${ALB_URL}
                '''
            }
        }
    }

    post {

        success {

            echo 'Production Drupal deployment completed successfully'
        }

        failure {

            echo 'Production Drupal deployment failed'
        }

        always {

            cleanWs()
        }
    }
}
