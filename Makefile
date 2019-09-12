.DEFAULT_GOAL := help

version        := 2.176.3
war_sha256     := 9406c7bee2bc473f77191ace951993f89922f927a0cd7efb658a4247d67b9aa3

jenkins_home   ?= $(CURDIR)/jenkins_home
listen_address ?= 127.0.0.1
port           ?= 8080
prefix         ?= /jenkins
url            ?= http://$(listen_address):$(port)$(prefix)

user           ?= groot
password       ?= $(shell openssl rand -base64 32)
cli_auth       ?= $(user):$(password)

jenkins_war    ?= ./jenkins.war
cli_jar        ?= ./jenkins-cli.jar
plugin_list    ?= $(CURDIR)/plugins.txt

$(jenkins_war):
	curl -L -o $(jenkins_war) http://mirrors.jenkins.io/war-stable/$(version)/jenkins.war

.PHONY: validate-war
validate-war: $(jenkins_war)
	test `sha256sum $(jenkins_war) | cut -d ' ' -f 1` = $(war_sha256)

.PHONY: run
## run : run jenkins  e.g. make user=jenkins password=password run
run: validate-war
	mkdir -p $(jenkins_home)
	cp init.groovy $(jenkins_home)
	env \
	  JENKINS_HOME=$(jenkins_home) \
	  URL=$(url) \
	  USER=$(user) \
	  PASSWORD=$(password) \
	  java -Djenkins.install.runSetupWizard=false -jar $(jenkins_war) \
	    --httpPort=$(port) --httpListenAddress=$(listen_address) --prefix=$(prefix)

$(cli_jar):
	curl -o $(cli_jar) $(url)/jnlpJars/jenkins-cli.jar

.PHONY: reload
## reload : reload jenkins
reload: $(cli_jar)
	@java -jar $(cli_jar) -s $(url) -auth $(cli_auth) reload-configuration

.PHONY: safe-restart
## safe-restart : restart jenkins
safe-restart: $(cli_jar)
	@java -jar $(cli_jar) -s $(url) -auth $(cli_auth) safe-restart

.PHONY: install-plugins
## install-plugins : e.g. make plugin_list=plugins.txt install-plugins
install-plugins: $(cli_jar)
	@for p in `cat $(plugin_list)`; do \
	  java -jar $(cli_jar) -s $(url) -auth $(cli_auth) install-plugin $$p -deploy; \
	done

.PHONY: add-user
## add-user : e.g. make new_user=jenkins new_password=password add-user
add-user: $(cli_jar)
	@echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("$(new_user)", "$(new_password)")' \
	  | java -jar $(cli_jar) -s $(url) -auth $(cli_auth) -noKeyAuth groovy = –

.PHONY: cli-help
## cli-help : show jenkins-cli help
cli-help: $(cli_jar)
	@java -jar $(cli_jar) -s $(url) -auth $(cli_auth) help

.PHONY: help
## help : show help
help:
	@grep -E '^##' $(MAKEFILE_LIST) | column -s ':' -t
