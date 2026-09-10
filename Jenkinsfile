// CI pipeline: scan -> analyse -> build -> push -> hand off to CD.
// Image tags are derived from the commit, never typed by hand.

pipeline {
    agent { label 'jenkins-worker' }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    environment {
        REPO_URL        = 'https://github.com/hammad558/End-to-End-DevOps-Pipeline.git'
        DOCKERHUB_USER  = 'hammad558'
        BACKEND_IMAGE   = "${DOCKERHUB_USER}/wanderlust-backend"
        FRONTEND_IMAGE  = "${DOCKERHUB_USER}/wanderlust-frontend"
        SONAR_HOME      = tool 'sonar-scanner'
        SONAR_PROJECT   = 'wanderlust'
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                git url: env.REPO_URL, branch: 'main'
                script {
                    env.GIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_SHORT}"
                }
                echo "Image tag for this build: ${env.IMAGE_TAG}"
            }
        }

        stage('Trivy: filesystem scan') {
            steps {
                sh '''
                  trivy fs --scanners vuln,secret,misconfig \
                    --severity HIGH,CRITICAL --exit-code 0 \
                    --format table -o trivy-fs-report.txt .
                '''
            }
        }

        stage('OWASP: dependency check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./backend --scan ./frontend --format ALL --disableYarnAudit',
                                odcInstallation: 'owasp-dependency-check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('SonarQube: analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh """
                      ${SONAR_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=${SONAR_PROJECT} \
                        -Dsonar.projectKey=${SONAR_PROJECT} \
                        -Dsonar.sources=backend,frontend/src \
                        -Dsonar.exclusions=**/node_modules/**,**/dist/**
                    """
                }
            }
        }

        stage('SonarQube: quality gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker: build') {
            parallel {
                stage('backend') {
                    steps {
                        dir('backend') {
                            sh "docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} ."
                        }
                    }
                }
                stage('frontend') {
                    steps {
                        dir('frontend') {
                            sh "docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} ."
                        }
                    }
                }
            }
        }

        stage('Trivy: image scan') {
            steps {
                sh """
                  trivy image --severity CRITICAL --exit-code 1 --ignore-unfixed ${BACKEND_IMAGE}:${IMAGE_TAG}
                  trivy image --severity CRITICAL --exit-code 1 --ignore-unfixed ${FRONTEND_IMAGE}:${IMAGE_TAG}
                """
            }
        }

        stage('Docker: push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-cred',
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_PASS')]) {
                    sh '''
                      echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                      docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                      docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                      docker logout
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivy-fs-report.txt, **/dependency-check-report.html', allowEmptyArchive: true
            sh 'docker image prune -f || true'
        }
        success {
            build job: 'wanderlust-cd', wait: false, parameters: [
                string(name: 'IMAGE_TAG', value: env.IMAGE_TAG)
            ]
        }
    }
}
