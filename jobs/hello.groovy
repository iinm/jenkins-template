pipeline {
    agent any

    options {
        ansiColor('xterm')
    }

    parameters {
        string(name: 'NAME', defaultValue: 'World', description: '')
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

        stage('Hello') {
            steps {
                echo "Hello, ${params.NAME}!"
            }
        }
    }
}
