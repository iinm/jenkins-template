jenkins_version        ?= 2.164.2
jenkins_war_sha256     ?= c851b603e3d320295eed671fde7c661209645c818da9b7564caee8371e52bede
jenkins_cli_sha256     ?= 6d510758708da16d4fb6392039a76686ffc84db73e57832b2ddc3b64e5995152
jenkins_listen_address ?= 127.0.0.1
jenkins_port           ?= 8080
jenkins_prefix         ?= /jenkins
jenkins_url            := http://$(jenkins_listen_address):$(jenkins_port)$(jenkins_prefix)
jenkins_home           ?= $(CURDIR)/jenkins_home

jenkins.war:
	curl -L -o jenkins.war http://mirrors.jenkins.io/war-stable/$(jenkins_version)/jenkins.war

.PHONY: validate-war
validate-war: jenkins.war
	test `sha256sum jenkins.war | cut -d ' ' -f 1` = $(jenkins_war_sha256)

.PHONY: run
## make jenkins_user=admin jenkins_password=password run
run: validate-war
	mkdir -p $(jenkins_home)
	cp init.groovy $(jenkins_home)
	env JENKINS_HOME=$(jenkins_home) JENKINS_URL=$(jenkins_url) JENKINS_USER=$(jenkins_user) JENKINS_PASSWORD=$(jenkins_password) java -Djenkins.install.runSetupWizard=false -jar jenkins.war --httpPort=$(jenkins_port) --httpListenAddress=$(jenkins_listen_address) --prefix=$(jenkins_prefix)

.PHONY: show-passwd
show-passwd:
	@cat $(admin_password_file)

jenkins-cli.jar:
	curl -o jenkins-cli.jar $(jenkins_url)/jnlpJars/jenkins-cli.jar

.PHONY: validate-cli-jar
validate-cli-jar: jenkins-cli.jar
	test `sha256sum jenkins-cli.jar | cut -d ' ' -f 1` = $(jenkins_cli_sha256)

.PHONY: reload
reload: validate-cli-jar
	@java -jar jenkins-cli.jar -s $(jenkins_url) -auth $(jenkins_cli_auth) reload-configuration

.PHONY: safe-restart
safe-restart: validate-cli-jar
	@java -jar jenkins-cli.jar -s $(jenkins_url) -auth $(jenkins_cli_auth) safe-restart

.PHONY: install-plugins
install-plugins: validate-cli-jar
	@for p in `cat plugins.txt`; do \
	  java -jar jenkins-cli.jar -s $(jenkins_url) -auth $(jenkins_cli_auth) install-plugin $$p -deploy; \
	done

.PHONY: add-user
add-user: validate-cli-jar
	@echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("$(username)", "$(password)")' \
	  | java -jar jenkins-cli.jar -s $(jenkins_url) -auth $(jenkins_cli_auth) -noKeyAuth groovy = –
