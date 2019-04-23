// https://wiki.jenkins.io/plugins/servlet/mobile?contentId=38142057#content/view/70877247
import jenkins.model.*
import hudson.security.*
import hudson.security.csrf.*

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
def user = jenkins.getSecurityRealm().createAccount(env.JENKINS_USER as String, env.JENKINS_PASSWORD as String)
user.save()

// configure security
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
jenkins.setAuthorizationStrategy(strategy)

// enable csrf protection
if (jenkins.getCrumbIssuer() == null) {
    jenkins.setCrumbIssuer(new DefaultCrumbIssuer(true))
}

// disable cli
jenkins.getDescriptor("jenkins.CLI").get().setEnabled(false)

jenkins.save()
