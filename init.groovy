// https://wiki.jenkins.io/plugins/servlet/mobile?contentId=38142057#content/view/70877247
import hudson.security.*
import hudson.security.csrf.*
import jenkins.model.*
import jenkins.security.s2m.*

def env = System.getenv()
def jenkins = Jenkins.getInstance()

// set url
urlConfig = JenkinsLocationConfiguration.get()
urlConfig.setUrl(env.JENKINS_URL)
urlConfig.save()

// create admin user
if (!(jenkins.getSecurityRealm() instanceof HudsonPrivateSecurityRealm)) {
    jenkins.setSecurityRealm(new HudsonPrivateSecurityRealm(false))
}
def user = jenkins.getSecurityRealm().createAccount(env.JENKINS_USER, env.JENKINS_PASSWORD)
user.save()

// configure security
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
jenkins.setAuthorizationStrategy(strategy)

// enable csrf protection
if (jenkins.getCrumbIssuer() == null) {
    jenkins.setCrumbIssuer(new DefaultCrumbIssuer(true))
}

// https://wiki.jenkins.io/display/JENKINS/Slave+To+Master+Access+Control
jenkins.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

jenkins.save()
