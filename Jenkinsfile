// params defined in Jenkins pipeline setting
// string params
def DOCKER_REGISTRY = "${params.docker_registry}"
def DOCKER_PROJECT = "${params.docker_project}"
def DOCKER_REGISTRY_CREDENTIAL_ID = "${params.docker_credential_id}"
def BASE_BRANCH = "${params.base_branch}"
def GIT_EMAIL = "${params.git_email}"
def GITHUB_CREDENTIAL_ID = "${params.github_credential_id}"
def RELEASE_CARGO_LOGIN = "${params.release_cargo_login}"
def SOURCE_REGISTRY = "${params.source_registry}"
def SOURCE_PROJECT = "${params.source_project}"
def SOURCE_REGISTRY_CREDENTIAL_ID = "${params.source_registry_credential_id}"
def TARGET_REGISTRY = "${params.target_registry}"
def TARGET_PROJECT = "${params.target_project}"
def TARGET_REGISTRY_CREDENTIAL_ID = "${params.target_registry_credential_id}"
def RELEASE_REGISTRY = "${params.release_registry}"
def RELEASE_REGISTRY_CREDENTIAL_ID = "${params.release_registry_credential_id}"
def RELEASE_VERSION = "${params.release_version}"
def CARGO_DIR = "${params.cargo_dir}"
def SYNC_DIR = "${params.sync_dir}"
def RELEASE_OSS_PATH = "${params.release_oss_path}"
def HOTFIX_DIR = "${params.hotfix_dir}"
def HOTFIX_YAML_PATH = "${params.hotfix_yaml_path}"
def HOTFIX_OSS_PATH = "${params.hotfix_oss_path}"

// docker registry prefix
def DOCKER_REGISTRY_PREFIX = "cargo.caicloudprivatetest.com/caicloud"
// this guarantees the node will use this template
def POD_NAME = "product-release-${UUID.randomUUID().toString()}"

// Kubernetes pod template to run.
podTemplate(
    cloud: "dev-cluster",
    namespace: "kube-system",
    name: POD_NAME,
    label: POD_NAME,
    yaml: """
apiVersion: v1
kind: Pod
spec:
  containers:
  - env:
    - name: DOCKER_HOST
      value: unix:///home/jenkins/docker.sock
    - name: REGISTRY
      value: "${DOCKER_REGISTRY}"
    - name: PROJECT
      value: "${DOCKER_PROJECT}"
    - name: BASE_BRANCH
      value: "${BASE_BRANCH}"
    - name: GIT_EMAIL
      value: "${GIT_EMAIL}"
    - name: SOURCE_REGISTRY
      value: "${SOURCE_REGISTRY}"
    - name: SOURCE_PROJECT
      value: "${SOURCE_PROJECT}"
    - name: TARGET_REGISTRY
      value: "${TARGET_REGISTRY}"
    - name: TARGET_PROJECT
      value: "${TARGET_PROJECT}"
    - name: RELEASE_REGISTRY
      value: "${RELEASE_REGISTRY}"
    - name: RELEASE_VERSION
      value: "${RELEASE_VERSION}"
    - name: CARGO_DIR
      value: "${CARGO_DIR}"
    - name: SYNC_DIR
      value: "${SYNC_DIR}"
    - name: RELEASE_OSS_PATH
      value: "${RELEASE_OSS_PATH}"
    - name: HOTFIX_DIR
      value: "${HOTFIX_DIR}"
    - name: HOTFIX_YAML_PATH
      value: "${HOTFIX_YAML_PATH}"
    - name: HOTFIX_OSS_PATH
      value: "${HOTFIX_OSS_PATH}"
    name: golang-docker
    image: "${DOCKER_REGISTRY_PREFIX}/golang-jenkins:v0.0.1"
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
    node(POD_NAME) {
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
                if (params.release) {
                    stage("Make Release") {
                    // bool params defined in Jenkins pipeline setting.
                        withCredentials([usernamePassword(credentialsId: "${GITHUB_CREDENTIAL_ID}", passwordVariable: "GITHUB_TOKEN", usernameVariable: "GITHUB_USERNAME")]) {
                            sh """
                                # Prepare GitHub OAuth Token
                                echo ${GITHUB_TOKEN} > ./token

                                # Init repo
                                git remote remove origin
                                git remote add upstream https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/caicloud/product-release
                                git remote add origin https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/product-release
                                git fetch upstream
                                git reset --hard upstream/${BASE_BRANCH}

                                # Prepare git email for CLA.
                                git config --global user.email ${GIT_EMAIL}

                                # Collect & Update tags
                                make update-tag CHART_LIST_PATH=./charts_list.yaml GITHUB_TOKEN_PATH=./token TARGET_COLLECT_TAG_PATH=./release_charts.yaml

                                # Make commit.
                                git checkout -B ${RELEASE_VERSION}
                                git add release_charts.yaml
                                git commit -m "chore(*): update release_charts.yaml"
                                git push --set-upstream origin ${RELEASE_VERSION} --force

                                # Make PR with curl.
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

                                    # Make commit.
                                    git add addons images-lists/images_platform.list
                                    git commit -m "chore(*): update addons"
                                    git push --set-upstream origin ${RELEASE_VERSION} --force

                                    # Make PR with curl.
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
                                        git push upstream --tags

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
                if (params.package) {
                    withCredentials([usernamePassword(credentialsId: "${RELEASE_CARGO_LOGIN}", passwordVariable: "RELEASE_CARGO_PASSWORD", usernameVariable: "RELEASE_CARGO_IP")]) {
                        stage("Sync images") {
                            withCredentials([usernamePassword(credentialsId: "${SOURCE_REGISTRY_CREDENTIAL_ID}", passwordVariable: "SOURCE_REGISTRY_PASSWORD", usernameVariable: "SOURCE_REGISTRY_USER")]) {
                                withCredentials([usernamePassword(credentialsId: "${TARGET_REGISTRY_CREDENTIAL_ID}", passwordVariable: "TARGET_REGISTRY_PASSWORD", usernameVariable: "TARGET_REGISTRY_USER")]) {
                                    withCredentials([usernamePassword(credentialsId: "${RELEASE_REGISTRY_CREDENTIAL_ID}", passwordVariable: "RELEASE_REGISTRY_PASSWORD", usernameVariable: "RELEASE_REGISTRY_USER")]) {
                                        sh """
                                            cp /jenkins/ansible/inventory.sample /jenkins/ansible/inventory
                                            sed -i 's/CARGO_IP/${RELEASE_CARGO_IP}/g' /jenkins/ansible/inventory
                                            sed -i 's/CARGO_PASSWORD/${RELEASE_CARGO_PASSWORD}/g' /jenkins/ansible/inventory
                                            ansible -i /jenkins/ansible/inventory cargo -m shell -a "docker login ${SOURCE_REGISTRY} -u ${SOURCE_REGISTRY_USER} -p ${SOURCE_REGISTRY_PASSWORD}"
                                            ansible -i /jenkins/ansible/inventory cargo -m shell -a "docker login ${TARGET_REGISTRY} -u ${TARGET_REGISTRY_USER} -p ${TARGET_REGISTRY_PASSWORD}"
                                            ansible -i /jenkins/ansible/inventory cargo -m shell -a "docker login ${RELEASE_REGISTRY} -u ${RELEASE_REGISTRY_USER} -p ${RELEASE_REGISTRY_PASSWORD}"
                                            ansible -i /jenkins/ansible/inventory cargo -m shell -a "rm -rf ${SYNC_DIR} && mkdir -p ${SYNC_DIR}"
                                            ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/sync_images_scripts/sync.sh dest=${SYNC_DIR}/ mode=0755"
                                            ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=images-lists/ dest=${SYNC_DIR}/images-lists/ mode=0644"
                                            ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/auto_package/package.sh dest=/root/ mode=0755"
                                            ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/source_registry/${SOURCE_REGISTRY}/g' /root/package.sh"
                                            ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/target_registry/${TARGET_REGISTRY}/g' /root/package.sh"
                                            ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/release_registry/${RELEASE_REGISTRY}/g' /root/package.sh"
                                            ansible -i /jenkins/ansible/inventory cargo -m shell -a "bash /root/package.sh sync ${RELEASE_VERSION} ${CARGO_DIR} ${SYNC_DIR}"
                                            """
                                    }
                                }
                            }
                        }
                        stage("Packaging") {
                            def packaging = packaging()
                            if (packaging) {
                                sh """
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "bash /root/package.sh package ${RELEASE_VERSION} ${CARGO_DIR}"
                                    ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/install.sh dest=${CARGO_DIR}/compass-component-${RELEASE_VERSION}/ mode=0755"
                                    ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/config.sample dest=${CARGO_DIR}/compass-component-${RELEASE_VERSION}/ mode=0644"
                                    ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=release.tar.gz dest=${CARGO_DIR}/compass-component-${RELEASE_VERSION}/image/ mode=0644"
                                """
                            } else {
                                sh """
                                    echo "got missed images"
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a 'echo -e "missed_images: \n`cat ${SYNC_DIR}/images-lists/miss_image.txt`"
                                    exit 1'
                                """
                            }
                        }
                        stage("Cadm"){
                            docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_REGISTRY_CREDENTIAL_ID}") {
                                def cadm = cadm()
                                if (cadm) {
                                    withCredentials([usernamePassword(credentialsId: "${GITHUB_CREDENTIAL_ID}", passwordVariable: "GITHUB_TOKEN", usernameVariable: "GITHUB_USERNAME")]) {
                                    sh """
                                        git clone https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/caicloud/compass-admin
                                        cd compass-admin && make build-linux
                                        ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=bin/cadm dest=${CARGO_DIR}/compass-component-${RELEASE_VERSION}/ mode=0755"
                                    """
                                    }
                                } else {
                                    sh """
                                        echo "cadm exists, will copy"
                                        ansible -i /jenkins/ansible/inventory cargo -m shell -a "cp /root/cadm ${CARGO_DIR}/compass-component-${RELEASE_VERSION}/"
                                    """
                                }
                            }
                        }
                        stage("Upload") {
                            def upload = upload()
                            if (upload) {
                                sh """
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "bash /root/package.sh upload ${RELEASE_VERSION} ${CARGO_DIR} ${SYNC_DIR} ${RELEASE_OSS_PATH}"
                                """
                            } else {
                                echo 'Why choose no?'
                            }
                        }
                    }
                }
                if (params.hotfix) {
                    stage("Make Hotfix") {
                    // bool params defined in Jenkins pipeline setting.
                        withCredentials([usernamePassword(credentialsId: "${RELEASE_CARGO_LOGIN}", passwordVariable: "RELEASE_CARGO_PASSWORD", usernameVariable: "RELEASE_CARGO_IP")]) {
                            withCredentials([usernamePassword(credentialsId: "${SOURCE_REGISTRY_CREDENTIAL_ID}", passwordVariable: "SOURCE_REGISTRY_PASSWORD", usernameVariable: "SOURCE_REGISTRY_USER")]) {
                                withCredentials([usernamePassword(credentialsId: "${TARGET_REGISTRY_CREDENTIAL_ID}", passwordVariable: "TARGET_REGISTRY_PASSWORD", usernameVariable: "TARGET_REGISTRY_USER")]) {
                                    sh """
                                        cp /jenkins/ansible/inventory.sample /jenkins/ansible/inventory
                                        sed -i 's/CARGO_IP/${RELEASE_CARGO_IP}/g' /jenkins/ansible/inventory
                                        sed -i 's/CARGO_PASSWORD/${RELEASE_CARGO_PASSWORD}/g' /jenkins/ansible/inventory
                                        ansible -i /jenkins/ansible/inventory cargo -m shell -a "docker login ${SOURCE_REGISTRY} -u ${SOURCE_REGISTRY_USER} -p ${SOURCE_REGISTRY_PASSWORD}"
                                        ansible -i /jenkins/ansible/inventory cargo -m shell -a "docker login ${TARGET_REGISTRY} -u ${TARGET_REGISTRY_USER} -p ${TARGET_REGISTRY_PASSWORD}"
                                        ansible -i /jenkins/ansible/inventory cargo -m shell -a "rm -rf ${HOTFIX_DIR} && mkdir -p ${HOTFIX_DIR}"
                                        ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=release-hotfixes dest=${HOTFIX_DIR} mode=0755"
                                        ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/auto_hotfix/hotfix.sh dest=${HOTFIX_DIR} mode=0755"
                                        ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/auto_hotfix/env.sh dest=${HOTFIX_DIR} mode=0755"
                                        ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/source_registry/${SOURCE_REGISTRY}/g;s/source_project/${SOURCE_PROJECT}/g' ${HOTFIX_DIR}/env.sh"
                                        ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/target_registry/${TARGET_REGISTRY}/g;s/target_project/${TARGET_PROJECT}/g' ${HOTFIX_DIR}/env.sh"
                                        ansible -i /jenkins/ansible/inventory cargo -m shell -a "cd ${HOTFIX_DIR} && bash hotfix.sh hotfix release-hotfixes/${HOTFIX_YAML_PATH}"
                                    """
                                }
                            }
                        }
                    }
                    stage("Upload") {
                        def upload = upload()
                        if (upload) {
                            sh """
                                ansible -i /jenkins/ansible/inventory cargo -m shell -a "cd ${HOTFIX_DIR} && bash ${HOTFIX_DIR}/hotfix.sh upload ${HOTFIX_OSS_PATH}"
                            """
                        } else {
                            echo 'Why choose no?'
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

def packaging() {
    try {
        sh """
            ansible -i /jenkins/ansible/inventory cargo -m shell -a "bash /root/package.sh judge ${RELEASE_VERSION} ${CARGO_DIR} ${SYNC_DIR}"
        """
        return true
    } catch(e) {
        return false
    }
}

def cadm() {
    try {
        sh """
            ansible -i /jenkins/ansible/inventory cargo -m shell -a "test -e /root/cadm"
        """
        return false
    } catch(e) {
        return true
    }
}

def upload() {
    try {
        def upload = input message: 'Ready to start uploading?',
                    parameters: [booleanParam(defaultValue: true, description: 'Ready to start uploading?', name: 'upload')]
        return upload
    } catch(e) {
        return false
    }
}
