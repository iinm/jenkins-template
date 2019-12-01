# Jenkins Job Configuration Template

## Purpose

I use Jenkins to automate many tasks like deployment of applications, summarizing error log, etc.
When those jobs are required for multiple environments, it is really painful to set up by using Jenkins GUI.

The Purpose of this project is managing Jenkins job configuration as code and automate deployment in a simple way.


## Warnings and Limitations

- It supports only Pipeline project.  FreeStyle project is not supported.
- `update_jobs.sh` always runs every pipelines, because it is required to update parameter configuration. (see [JENKINS-41929](https://issues.jenkins-ci.org/browse/JENKINS-41929))
  **All pipeline must check `JUST_UPDATE_JENKINSFILE` parameter to prevent execution.  For more detail, see example `hello_pipeline.groovy`.**
- It does not support deletion of Job and View.

## Directory structure

```
.
├── jobs
│   ├── hello_pipeline.groovy  # Example pipeline script
│   └── jenkins_update.groovy  # This pipeline deploys Jenkins jobs
└── views
    ├── example
    │   └── hello_pipeline.groovy -> ../../jobs/hello_pipeline.groovy
    └── jenkins
        └── jenkins_update.groovy -> ../../jobs/jenkins_update.groovy
```
- `jobs`  : Pipeline script
- `views` : View definition.  Sub directory should contains only symbolic link to pipeline script.
  e.g. sub directory `example` above is view that contains job `hello_pipeline`.


## Bootstrap

Assume that Jenkins is running.  If it's not, you can use wrapper script for testing.

```sh
admin_password=$(openssl rand -base64 32)
echo "$admin_password" > .initial_admin_password
./jenkins
```
http://127.0.0.1:8080/jenkins


Setup environment to use Jenkins cli
```sh
export JENKINS_URL=http://127.0.0.1:8080/jenkins
echo "admin:$admin_password" > .cli_credential
```

Install Plugins
```sh
while read line; do ./jenkins-cli install-plugin "$line" -deploy < /dev/null; done < ./plugins.txt
```

Add Credentials
- Jenkins username / password (id: jenkins-cli) : Required to Update jobs and views using Jenkins itself.
- Github username / access token (id: github) : Required to pull git repository that contains jobs.

Update Jobs
```sh
env GIT_CREDENTIAL_ID="github" bash ./update_jobs.sh
```
- GIT_CREDENTIAL_ID : Jenkins credential ID to access git repository.

Update Views
```sh
bash ./update_views.sh
```
