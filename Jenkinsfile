// params defined in Jenkins pipeline setting
// string params
def DOCKER_REGISTRY = "${params.docker_registry}"
def DOCKER_PROJECT = "${params.docker_project}"
def DOCKER_REGISTRY_CREDENTIAL_ID = "${params.docker_credential_id}"
def RELEASE_VERSION = "${params.release_version}"

// docker registry prefix
def DOCKER_REGISTRY_PREFIX = "cargo.caicloudprivatetest.com/caicloud"
// this guarantees the node will use this template
def PROJECT_NAME = "product-release-${UUID.randomUUID().toString()}"

// Kubernetes pod template to run.
podTemplate(
    cloud: "dev-cluster",
    namespace: "kube-system",
    name: PROJECT_NAME,
    label: PROJECT_NAME,
    yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - env:
    - name: DOCKER_HOST
      value: unix:///home/jenkins/docker.sock
    - name: RELEASE_VERSION
      value: "${RELEASE_VERSION}"
    - name: REGISTRY
      value: "${DOCKER_REGISTRY}"
    - name: PROJECT
      value: "${DOCKER_PROJECT}"
    name: golang-docker
    image: "${DOCKER_REGISTRY_PREFIX}/golang-docker:1.10-17.09"
    imagePullPolicy: IfNotPresent
    tty: true
  - name: jnlp
    args: ["\$(JENKINS_SECRET)", "\$(JENKINS_NAME)"]
    image: "${DOCKER_REGISTRY_PREFIX}/jnlp-slave:3.14-1-alpine"
    imagePullPolicy: IfNotPresent
  - name: dind
    args:
    - --host=unix:///home/jenkins/docker.sock
    image: "${DOCKER_REGISTRY_PREFIX}/docker:17.09-dind"
    imagePullPolicy: IfNotPresent
    securityContext:
      privileged: true
    tty: true
""",
) {
    node(PROJECT_NAME) {
        container("golang-docker") {
            ansiColor("xterm") {
                stage("Checkout") {
                    checkout scm
                }

                stage("Lint charts") {
                    sh("""
                        make lint
                    """)
                }

                stage("Build & Push & Tar image") {
                    // bool params defined in Jenkins pipeline setting.
                    if (params.publish_image) {
                        docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_REGISTRY_CREDENTIAL_ID}") {
                            sh("""
                                # Env will replace params in Makefile.
                                make release-image
                            """)
                        }
                    }
                }
            }
        }
    }
}
