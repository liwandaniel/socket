// params defined in Jenkins pipeline setting
// string params
def DOCKER_REGISTRY = "${params.docker_registry}"
def DOCKER_PROJECT = "${params.docker_project}"
def DOCKER_REGISTRY_CREDENTIAL_ID = "${params.docker_credential_id}"
def RELEASE_VERSION = "${params.release_version}"
def BASE_BRANCH = "${params.base_branch}"
def GIT_EMAIL = "${params.git_email}"
def GITHUB_CREDENTIAL_ID = "${params.github_credential_id}"

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
    - name: BASE_BRANCH
      value: "${BASE_BRANCH}"
    - name: GIT_EMAIL
      value: "${GIT_EMAIL}"
    name: golang-docker
    image: "${DOCKER_REGISTRY_PREFIX}/golang-docker:1.10-17.09-product-release"
    imagePullPolicy: Always
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

                stage("Lint Charts") {
                    sh """
                        make lint
                    """
                }

                stage("Make Release") {
                    // bool params defined in Jenkins pipeline setting.
                    if (params.release) {
                        withCredentials([usernamePassword(credentialsId: "${GITHUB_CREDENTIAL_ID}", passwordVariable: "GITHUB_TOKEN", usernameVariable: "GITHUB_USERNAME")]) {
                            sh """
                                echo 'Prepare GitHub OAuth Token'
                                echo ${GITHUB_TOKEN} > ./token

                                # Init repo
                                git remote remove origin
                                git remote add upstream https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/caicloud/product-release
                                git remote add origin https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/product-release
                                git fetch upstream
                                git reset --hard upstream/${BASE_BRANCH}

                                # Prepare git email for CLA.
                                git config --global user.email ${GIT_EMAIL}

                                echo 'Collect & Update tags'
                                make update-tag CHART_LIST_PATH=./charts_list.yaml GITHUB_TOKEN_PATH=./token TARGET_COLLECT_TAG_PATH=./release_charts.yaml

                                # Make PR
                                git checkout -B ${RELEASE_VERSION}
                                git add release_charts.yaml
                                git commit -m "chore(*): update release_charts.yaml"
                                git push --set-upstream origin ${RELEASE_VERSION} --force

                                curl -X POST \
                                https://api.github.com/repos/caicloud/product-release/pulls \
                                -H 'Authorization: Bearer ${GITHUB_TOKEN}' \
                                -d '{
                                "title": "Updating new tags",
                                "body": "**What this PR does / why we need it**:\\n\\nUpdating new tags\\n\\n**Special notes for your reviewer**:\\n\\ncc @caicloud/platform-t2\\n\\n```release-note\\nNONE\\n```",
                                "head": "${GITHUB_USERNAME}:${RELEASE_VERSION}",
                                "base": "${BASE_BRANCH}"
                                }'
                            """

                            def collectTags = whetherPRMerged()
                            if (collectTags) {
                                sh """
                                    # Prepare git
                                    git checkout ${BASE_BRANCH}
                                    git fetch upstream
                                    git reset --hard upstream/${BASE_BRANCH}
                                    git checkout -B ${RELEASE_VERSION}

                                    # Collect Charts
                                    make collect-charts ADDONS_PATH=./addons GITHUB_TOKEN_PATH=./token TARGET_COLLECT_TAG_PATH=./release_charts.yaml
                                    # Update images
                                    make convert-images ADDONS_PATH=./addons TARGET_FILE=./images-lists/images_platform.list

                                    # Make PR
                                    git add addons images-lists/images_platform.list
                                    git commit -m "chore(*): update addons"
                                    git push --set-upstream origin ${RELEASE_VERSION} --force

                                    curl -X POST \
                                    https://api.github.com/repos/caicloud/product-release/pulls \
                                    -H 'Authorization: Bearer ${GITHUB_TOKEN}' \
                                    -d '{
                                    "title": "Updating charts",
                                    "body": "**What this PR does / why we need it**:\\n\\nUpdating charts\\n\\n**Special notes for your reviewer**:\\n\\ncc @caicloud/platform-release\\n\\n```release-note\\nNONE\\n```",
                                    "head": "${GITHUB_USERNAME}:${RELEASE_VERSION}",
                                    "base": "${BASE_BRANCH}"
                                    }'
                                """  
                            } else {
                                echo 'Why choose no?'
                            }

                            def collectCharts = whetherPRMerged()
                            if (collectCharts) {
                                docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_REGISTRY_CREDENTIAL_ID}") {
                                    sh """
                                        # Reset to upstream/master
                                        git checkout ${BASE_BRANCH}
                                        git fetch upstream
                                        git reset --hard upstream/${BASE_BRANCH}

                                        # Git tag
                                        git tag ${RELEASE_VERSION}
                                        git push upstream ${RELEASE_VERSION} --tags

                                        # Env will replace params in Makefile.
                                        make release-image
                                    """
                                }
                            } else {
                                echo 'Why choose no?'
                            }
                        }
                    }
                }
            }
        }
    }
}

def whetherPRMerged() {
    try {
        def merged = input message: 'Whether PR merged?', 
                    parameters: [booleanParam(defaultValue: true, description: 'Whether PR merged?', name: 'Merged')]
        return merged
    } catch(e) {
        return false
    }
}
