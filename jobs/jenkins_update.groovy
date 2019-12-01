pipeline {
    agent any

    options {
        ansiColor('xterm')
    }

    triggers { pollSCM 'H/2 * * * *' }

    environment {
        JENKINS_URL = 'http://127.0.0.1:8080/jenkins'
        JENKINS_CLI_CREDENTIAL = credentials('jenkins-cli')
    }

    parameters {
        string(name: 'GIT_BRANCH', defaultValue: 'develop', description: '')
        booleanParam(name: 'JUST_RELOAD_JENKINSFILE', defaultValue: false, description: 'Just reload configuration, then abort job.')
    }

    stages {
        stage('Reload Jenkinsfile') {
            steps {
                script {
                    if (params.JUST_RELOAD_JENKINSFILE) {
                        currentBuild.result = 'ABORTED'
                        error('abort')
                    }
                }
            }
        }

        stage('Git clone') {
            steps {
                git url: 'https://github.com/iinm/jenkins-template', branch: params.GIT_BRANCH, poll: true
            }
        }

        stage("Prepare Jenkins cli credential file") {
            steps {
                sh 'echo "$JENKINS_CLI_CREDENTIAL" > .cli_credential'
            }
        }

        stage('Install plugins') {
            steps {
                sh 'while read line; do ./jenkins-cli install-plugin "$line" -deploy < /dev/null; done < ./plugins.txt'
            }
        }

        stage('Lint') {
            steps {
                sh 'make lint'
            }
        }

        stage('Update jobs') {
            environment {
                GIT_CREDENTIAL_ID = 'github'
            }
            steps {
              sh 'bash ./update_jobs.sh'
            }
        }

        stage('Update views') {
            steps {
              sh 'bash ./update_views.sh'
            }
        }
    }
}
