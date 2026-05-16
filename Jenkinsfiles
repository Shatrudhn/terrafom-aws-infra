cat > Jenkinsfile << 'EOF'
pipeline {
    agent any

    environment {
        AWS_REGION = "us-east-1"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                url: 'https://github.com/Shatrudhn/terrafom-aws-infra.git'
            }
        }

        stage('Terraform Version') {
            steps {
                sh 'terraform version'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Format Check') {
            steps {
                sh 'terraform fmt -check'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -out=tfplan'
            }
        }

        stage('Approval') {
            steps {
                input message: 'Approve Terraform Apply?'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }
    }

    post {
        success {
            echo 'Terraform deployment completed successfully.'
        }

        failure {
            echo 'Terraform deployment failed.'
        }
    }
}
EOF
