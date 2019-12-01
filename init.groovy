// https://wiki.jenkins.io/display/JENKINS/Groovy+Hook+Script
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

// configure security
if (jenkins.getSecurityRealm().equals(HudsonPrivateSecurityRealm.NO_AUTHENTICATION)) {

    jenkins.setSecurityRealm(new HudsonPrivateSecurityRealm(false))

    // create admin user
    def password = new File(env.JENKINS_INITIAL_ADMIN_PASSWORD_FILE).getText().trim()
    def user = jenkins.getSecurityRealm().createAccount(env.JENKINS_ADMIN_USER_NAME, password)
    user.save()

    def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
    strategy.setAllowAnonymousRead(false)
    jenkins.setAuthorizationStrategy(strategy)
}

// enable csrf protection
if (jenkins.getCrumbIssuer() == null) {
    jenkins.setCrumbIssuer(new DefaultCrumbIssuer(true))
}

// https://wiki.jenkins.io/display/JENKINS/Slave+To+Master+Access+Control
jenkins.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

// set the number of executors
jenkins.setNumExecutors(5)

jenkins.save()
