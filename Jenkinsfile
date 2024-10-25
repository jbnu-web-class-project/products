pipeline {
    agent {
        kubernetes {
            yaml """
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: docker
                image: docker:20.10.7
                command:
                - cat
                tty: true
                securityContext:
                  privileged: true
                volumeMounts:
                - name: docker-socket
                  mountPath: /var/run/docker.sock
              volumes:
              - name: docker-socket
                hostPath:
                  path: /var/run/docker.sock
            """
        }
    }

    environment {
        REGISTRY_CREDENTIALS = 'harbor-id'
        IMAGE_NAME = 'web-back-k8s'
        GITHUB_REPO = 'https://github.com/jbnu-web-class-project/backend.git'
        HARBOR_URL = credentials('harbor-url')
        HARBOR_REPO = credentials('harbor-repo')
        MANIFEST_REPO = 'git@github.com:jbnu-web-class-project/k8s-manifest.git'
        SSH_CREDENTIALS_ID = 'github-ssh'
    }

    stages {
        stage('Setup SSH') {
            steps {
                script {
                    sh 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
                    sh 'ssh-keyscan github.com >> ~/.ssh/known_hosts'
                    sh 'chmod 644 ~/.ssh/known_hosts'
                }
            }
        }

        stage('Clone Repository') {
            steps {
                git url: GITHUB_REPO, branch: 'main', credentialsId: 'web-service-pj-token'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    container('docker') {
                        sh "docker build -t heim/${IMAGE_NAME}:${env.BUILD_ID} ."
                    }
                }
            }
        }

        stage('Push to Harbor') {
            steps {
                script {
                    container('docker') {
                        docker.withRegistry(HARBOR_URL, REGISTRY_CREDENTIALS) {
                            def app = docker.image("heim/${IMAGE_NAME}:${env.BUILD_ID}")
                            app.push()
                            app.push('latest')
                        }
                    }
                }
            }
        }

        stage('Update Kubernetes Manifest') {
            steps {
                script {
                    sshagent(credentials: [SSH_CREDENTIALS_ID]) {
                        // Kubernetes manifest 파일을 수정하고 Git 레포지토리에 푸시
                        script {
                            def gitCloneCommand = "git clone ${MANIFEST_REPO} k8s-manifest"
                            sh gitCloneCommand
                            sh """
                            cd k8s-manifest &&
                            ls -l &&
                            sed -i 's|image: .*\$|image: ${HARBOR_REPO}/heim/${IMAGE_NAME}:${env.BUILD_ID}|' web-back-deployment.yaml &&
                            git config --global user.email "gjdhks1212@gmail.com"
                            git config --global user.name "hodu26"
                            git add web-back-deployment.yaml &&
                            git commit -m 'update: update image to ${env.BUILD_ID}' &&
                            git push --set-upstream origin main
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
