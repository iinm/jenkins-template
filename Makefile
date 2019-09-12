jenkins_version        ?= 2.176.3
jenkins_war_sha256     ?= 9406c7bee2bc473f77191ace951993f89922f927a0cd7efb658a4247d67b9aa3

jenkins_home           ?= $(CURDIR)/jenkins_home
jenkins_listen_address ?= 127.0.0.1
jenkins_port           ?= 8080
jenkins_prefix         ?= /jenkins
jenkins_url            ?= http://$(jenkins_listen_address):$(jenkins_port)$(jenkins_prefix)

jenkins_user           ?= jenkins
jenkins_password       ?= password
jenkins_cli_auth       ?= $(jenkins_user):$(jenkins_password)

jenkins_plugin_file    ?= $(CURDIR)/plugins.txt

jenkins.war:
	curl -L -o jenkins.war http://mirrors.jenkins.io/war-stable/$(jenkins_version)/jenkins.war

.PHONY: validate-war
validate-war: jenkins.war
	test `sha256sum jenkins.war | cut -d ' ' -f 1` = $(jenkins_war_sha256)

.PHONY: run
run: validate-war
	mkdir -p $(jenkins_home)
	cp init.groovy $(jenkins_home)
	env \
	  JENKINS_HOME=$(jenkins_home) \
	  JENKINS_URL=$(jenkins_url) \
	  JENKINS_USER=$(jenkins_user) \
	  JENKINS_PASSWORD=$(jenkins_password) \
	  java -Djenkins.install.runSetupWizard=false -jar jenkins.war \
	    --httpPort=$(jenkins_port) --httpListenAddress=$(jenkins_listen_address) --prefix=$(jenkins_prefix)

.PHONY: show-passwd
show-passwd:
	@cat $(admin_password_file)

jenkins-cli.jar:
	curl -o jenkins-cli.jar $(jenkins_url)/jnlpJars/jenkins-cli.jar

.PHONY: reload
reload: jenkins-cli.jar
	@java -jar jenkins-cli.jar -s $(jenkins_url) -auth $(jenkins_cli_auth) reload-configuration

.PHONY: safe-restart
safe-restart: jenkins-cli.jar
	@java -jar jenkins-cli.jar -s $(jenkins_url) -auth $(jenkins_cli_auth) safe-restart

.PHONY: install-plugins
install-plugins: jenkins-cli.jar
	@for p in `cat $(jenkins_plugin_file)`; do \
	  java -jar jenkins-cli.jar -s $(jenkins_url) -auth $(jenkins_cli_auth) install-plugin $$p -deploy; \
	done

.PHONY: add-user
add-user: jenkins-cli.jar
	@echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("$(username)", "$(password)")' \
	  | java -jar jenkins-cli.jar -s $(jenkins_url) -auth $(jenkins_cli_auth) -noKeyAuth groovy = –

.PHONY: cli-help
cli-help: jenkins-cli.jar
	java -jar jenkins-cli.jar -s $(jenkins_url) -auth $(jenkins_cli_auth) help
