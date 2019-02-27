// params defined in Jenkins pipeline setting
def DOCKER_REGISTRY = "${params.docker_registry}"
def DOCKER_PROJECT = "${params.docker_project}"
def DOCKER_REGISTRY_CREDENTIAL_ID = "${params.docker_credential_id}"
def BASE_BRANCH = "${params.base_branch}"
def GIT_EMAIL = "${params.git_email}"
def GITHUB_CREDENTIAL_ID = "${params.github_credential_id}"
def RELEASE_CARGO_LOGIN = "${params.release_cargo_login}"
def INSTALL_CLUSTER_LOGIN = "${params.install_cluster_login}"
def SOURCE_REGISTRY = "${params.source_registry}"
def SOURCE_PROJECT = "${params.source_project}"
def SOURCE_REGISTRY_CREDENTIAL_ID = "${params.source_registry_credential_id}"
def TARGET_REGISTRY = "${params.target_registry}"
def TARGET_PROJECT = "${params.target_project}"
def TARGET_REGISTRY_CREDENTIAL_ID = "${params.target_registry_credential_id}"
def RELEASE_REGISTRY = "${params.release_registry}"
def RELEASE_REGISTRY_CREDENTIAL_ID = "${params.release_registry_credential_id}"
def RELEASE_VERSION = "${params.release_version}"
def PRODUCT_NAME = "${params.product_name}"
def CARGO_DIR = "${params.cargo_dir}"
def SYNC_DIR = "${params.sync_dir}"
def PACKAGE_PATH = "${params.package_path}"
def KUBECONFIG = "${params.kubeconfig}"
def COMPASS_COMPONENT_URL = "${params.compass_component_url}"
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
    - name: PRODUCT_NAME
      value: "${PRODUCT_NAME}"
    - name: CARGO_DIR
      value: "${CARGO_DIR}"
    - name: SYNC_DIR
      value: "${SYNC_DIR}"
    - name: PACKAGE_PATH
      value: "${PACKAGE_PATH}"
    - name: COMPASS_COMPONENT_URL
      value: "${COMPASS_COMPONENT_URL}"
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
                if (params.oem && params.increment_release) {
                        CHARTS_LIST_FILE = "oem_charts_list.yaml"
                        RELEASE_CAHRTS_FILE = "oem_release_charts.yaml"
                        ADDONS_PATH = "oem-addons"
                        TARGET_IMGAE_FILE = "oem-images-lists/images_oem.list"
                        GITHUB_MENTION_GROUP = "@caicloud/platform-release"
                        TAG_NAME = "${PRODUCT_NAME}-${RELEASE_VERSION}"
                        IMGAE_LIST_DIR = "oem-images-lists"
                    } else {
                        CHARTS_LIST_FILE = "charts_list.yaml"
                        RELEASE_CAHRTS_FILE = "release_charts.yaml"
                        ADDONS_PATH = "addons"
                        TARGET_IMGAE_FILE = "images-lists/images_platform.list"
                        GITHUB_MENTION_GROUP = "@caicloud/platform-t2"
                        TAG_NAME = "${RELEASE_VERSION}"
                        IMGAE_LIST_DIR = "images-lists"
                }
                if (params.auto_build){
                        TAG_NAME="auto-`date +%Y%m%d`"
                        RELEASE_VERSION="auto-`date +%Y%m%d`"
                    }
                if (params.collect || params.release) {
                    stage("Init Repo") {
                        withCredentials([usernamePassword(credentialsId: "${GITHUB_CREDENTIAL_ID}", passwordVariable: "GITHUB_TOKEN", usernameVariable: "GITHUB_USERNAME")]) {
                            sh """
                                # Prepare GitHub OAuth Token
                                echo ${GITHUB_TOKEN} > ./token

                                # Init repo
                                git remote remove origin
                                git remote add upstream https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/caicloud/product-release
                                git remote add origin https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/product-release
                            """
                        }
                    }
                }
                withCredentials([usernamePassword(credentialsId: "${GITHUB_CREDENTIAL_ID}", passwordVariable: "GITHUB_TOKEN", usernameVariable: "GITHUB_USERNAME")]) {
                    if (params.collect) {
                        stage("Update Tag") {
                            // bool params defined in Jenkins pipeline setting.
                            sh """
                                git fetch upstream
                                git reset --hard upstream/${BASE_BRANCH}

                                # Prepare git email for CLA.
                                git config --global user.email ${GIT_EMAIL}

                                # Collect & Update tags
                                make update-tag CHART_LIST_PATH=./${CHARTS_LIST_FILE} GITHUB_TOKEN_PATH=./token TARGET_COLLECT_TAG_PATH=./${RELEASE_CAHRTS_FILE}
                            """
                        }
                    }
                    if (params.collect && !params.auto_build) {
                        stage("PR for Tag") {
                            sh """
                                # Make commit.
                                git checkout -B ${RELEASE_VERSION}
                                git add ${RELEASE_CAHRTS_FILE}
                                git commit -m "chore(*): update ${RELEASE_CAHRTS_FILE}"
                                git push --set-upstream origin ${RELEASE_VERSION} --force

                                # Make PR with curl.
                                curl -X POST \
                                https://api.github.com/repos/caicloud/product-release/pulls \
                                -H 'Authorization: Bearer ${GITHUB_TOKEN}' \
                                -d '{
                                "title": "[Auto pushed by Jenkins] Updating new tags",
                                "body": "**What this PR does / why we need it**:\\n\\nUpdating new tags\\n\\n**Special notes for your reviewer**:\\n\\ncc ${GITHUB_MENTION_GROUP}\\n\\n```release-note\\nNONE\\n```",
                                "head": "${GITHUB_USERNAME}:${RELEASE_VERSION}",
                                "base": "${BASE_BRANCH}"
                                }'
                            """
                        }
                    }
                    if (params.collect) {
                        stage("Collect Charts") {
                            if (!params.auto_build){
                                def collectTags = whetherPRMerged()
                            } else {
                                collectTags = true
                            }
                            if (collectTags) {
                                if (!params.auto_build) {
                                    sh """
                                        # Prepare git
                                        git checkout ${BASE_BRANCH}
                                        git fetch upstream
                                        git reset --hard upstream/${BASE_BRANCH}
                                        git checkout -B ${RELEASE_VERSION}
                                    """
                                }

                                sh """
                                    # Collect Charts
                                    make collect-charts ADDONS_PATH=./${ADDONS_PATH} GITHUB_TOKEN_PATH=./token TARGET_COLLECT_TAG_PATH=./${RELEASE_CAHRTS_FILE}
                                    # Update images
                                    make convert-images ADDONS_PATH=./${ADDONS_PATH} TARGET_IMGAES_LIST_PATH=./${TARGET_IMGAE_FILE}
                                """
                            } else {
                                echo 'Why choose no?'
                            }
                        }
                    }
                    if (params.collect && !params.auto_build) {
                        stage("PR for Charts") {
                            sh """
                                # Make commit.
                                git add ${ADDONS_PATH} ${TARGET_IMGAE_FILE}
                                git commit -m "chore(*): update addons"
                                git push --set-upstream origin ${RELEASE_VERSION} --force

                                # Make PR with curl.
                                curl -X POST \
                                https://api.github.com/repos/caicloud/product-release/pulls \
                                -H 'Authorization: Bearer ${GITHUB_TOKEN}' \
                                -d '{
                                "title": "[Auto pushed by Jenkins] Updating charts",
                                "body": "**What this PR does / why we need it**:\\n\\nUpdating charts\\n\\n**Special notes for your reviewer**:\\n\\ncc ${GITHUB_MENTION_GROUP}\\n\\n```release-note\\nNONE\\n```",
                                "head": "${GITHUB_USERNAME}:${RELEASE_VERSION}",
                                "base": "${BASE_BRANCH}"
                                }'
                            """
                        }
                    }
                }
                if (params.release) {
                    stage("Make Release-Image") {
                        if (!params.auto_build){
                            def collectCharts = whetherPRMerged()
                        } else {
                            collectCharts = true
                        }
                        if (collectCharts) {
                            docker.withRegistry("https://${DOCKER_REGISTRY}", "${DOCKER_REGISTRY_CREDENTIAL_ID}") {
                                if (!params.auto_build) {
                                    sh """
                                        # Reset to upstream/master
                                        git checkout -B ${RELEASE_VERSION}
                                        git fetch upstream
                                        git reset --hard upstream/${BASE_BRANCH}

                                        # Git tag
                                        git tag ${TAG_NAME}
                                        git push upstream --tags
                                    """
                                }
                                sh """
                                    # Env will replace params in Makefile.
                                    make release-image RELEASE_VERSION=${TAG_NAME} OEM_PRODUCT_NAME=${PRODUCT_NAME}
                                """
                            }
                        } else {
                            echo 'Why choose no?'
                        }
                    }
                }
                if (params.package) {
                    withCredentials([usernamePassword(credentialsId: "${RELEASE_CARGO_LOGIN}", passwordVariable: "RELEASE_CARGO_PASSWORD", usernameVariable: "RELEASE_CARGO_IP")]) {
                        stage("Sync images") {
                            withCredentials([
                                [$class: "UsernamePasswordMultiBinding", credentialsId: "${SOURCE_REGISTRY_CREDENTIAL_ID}", passwordVariable: "SOURCE_REGISTRY_PASSWORD", usernameVariable: "SOURCE_REGISTRY_USER"],
                                [$class: "UsernamePasswordMultiBinding", credentialsId: "${TARGET_REGISTRY_CREDENTIAL_ID}", passwordVariable: "TARGET_REGISTRY_PASSWORD", usernameVariable: "TARGET_REGISTRY_USER"],
                                [$class: "UsernamePasswordMultiBinding", credentialsId: "${RELEASE_REGISTRY_CREDENTIAL_ID}", passwordVariable: "RELEASE_REGISTRY_PASSWORD", usernameVariable: "RELEASE_REGISTRY_USER"],
                            ]) {
                                sh """
                                    cp /jenkins/ansible/inventory.sample /jenkins/ansible/inventory
                                    sed -i 's/CARGO_IP/${RELEASE_CARGO_IP}/g' /jenkins/ansible/inventory
                                    sed -i 's/CARGO_PASSWORD/${RELEASE_CARGO_PASSWORD}/g' /jenkins/ansible/inventory
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "docker login ${SOURCE_REGISTRY} -u ${SOURCE_REGISTRY_USER} -p ${SOURCE_REGISTRY_PASSWORD}"
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "docker login ${TARGET_REGISTRY} -u ${TARGET_REGISTRY_USER} -p ${TARGET_REGISTRY_PASSWORD}"
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "docker login ${RELEASE_REGISTRY} -u ${RELEASE_REGISTRY_USER} -p ${RELEASE_REGISTRY_PASSWORD}"
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "rm -rf ${SYNC_DIR} && mkdir -p ${SYNC_DIR}"
                                    ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/sync_images_scripts/sync.sh dest=${SYNC_DIR}/ mode=0755"
                                    ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=${IMGAE_LIST_DIR}/ dest=${SYNC_DIR}/images-lists/ mode=0644"
                                    ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/auto_package/package.sh dest=/root/ mode=0755"
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/source_registry/${SOURCE_REGISTRY}/g' /root/package.sh"
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/target_registry/${TARGET_REGISTRY}/g' /root/package.sh"
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/release_registry/${RELEASE_REGISTRY}/g' /root/package.sh"
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "bash /root/package.sh sync ${RELEASE_VERSION} ${CARGO_DIR} ${PRODUCT_NAME} ${SYNC_DIR}"
                                """
                            }
                        }
                        stage("Packaging") {
                            def packaging = packaging()
                            if (packaging) {
                                sh """
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "bash /root/package.sh package ${RELEASE_VERSION} ${CARGO_DIR} ${PRODUCT_NAME} ${PACKAGE_PATH}"
                                    ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/install.sh dest=${PACKAGE_PATH}/${PRODUCT_NAME}-component-${RELEASE_VERSION}/ mode=0755"
                                    ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=config.sample dest=${PACKAGE_PATH}/${PRODUCT_NAME}-component-${RELEASE_VERSION}/ mode=0644"
                                    ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=release.tar.gz dest=${PACKAGE_PATH}/${PRODUCT_NAME}-component-${RELEASE_VERSION}/image/ mode=0644"
                                """
                            } else {
                                sh """
                                    echo "got missed images"
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a 'echo -e "missed_images: \n`cat ${SYNC_DIR}/images-lists/miss_image.txt`"
                                    exit 1'
                                """
                            }
                            if (params.oem && params.increment_release) {
                                sh """
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/compass.yaml/oem.yaml/g;s/addons/oem-addons/g' ${PACKAGE_PATH}/${PRODUCT_NAME}-component-${RELEASE_VERSION}/config.sample"
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
                                        ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=bin/cadm dest=${PACKAGE_PATH}/${PRODUCT_NAME}-component-${RELEASE_VERSION}/ mode=0755"
                                    """
                                    }
                                } else {
                                    sh """
                                        echo "cadm exists, will copy"
                                        ansible -i /jenkins/ansible/inventory cargo -m shell -a "cp /root/cadm ${PACKAGE_PATH}/${PRODUCT_NAME}-component-${RELEASE_VERSION}/"
                                    """
                                }
                            }
                        }
                        stage("Upload") {
                            def upload = upload()
                            if (upload) {
                                sh """
                                    ansible -i /jenkins/ansible/inventory cargo -m shell -a "bash /root/package.sh upload ${RELEASE_VERSION} ${CARGO_DIR} ${PRODUCT_NAME} ${RELEASE_OSS_PATH} ${PACKAGE_PATH}"
                                """
                            } else {
                                echo 'Why choose no?'
                            }
                        }
                    }
                }
                if (params.install_option && params.install_option != "---" ) {
                    withCredentials([
                            [$class: "UsernamePasswordMultiBinding", credentialsId: "${INSTALL_CLUSTER_LOGIN}", passwordVariable: "INSTALL_CARGO_PASSWORD", usernameVariable: "INSTALL_CARGO_IP"],
                            [$class: "UsernamePasswordMultiBinding", credentialsId: "${RELEASE_CARGO_LOGIN}", passwordVariable: "RELEASE_CARGO_PASSWORD", usernameVariable: "RELEASE_CARGO_IP"],
                            [$class: "UsernamePasswordMultiBinding", credentialsId: "${SOURCE_REGISTRY_CREDENTIAL_ID}", passwordVariable: "SOURCE_REGISTRY_PASSWORD", usernameVariable: "SOURCE_REGISTRY_USER"],
                            [$class: "UsernamePasswordMultiBinding", credentialsId: "${TARGET_REGISTRY_CREDENTIAL_ID}", passwordVariable: "TARGET_REGISTRY_PASSWORD", usernameVariable: "TARGET_REGISTRY_USER"],
                    ]) {
                        withCredentials([file(credentialsId: "${KUBECONFIG}", variable: "KUBECONFIG_FILE")]) {
                            sh """
                                cp /jenkins/ansible/inventory.sample /jenkins/ansible/inventory_cluster
                                sed -i 's/CARGO_IP/${INSTALL_CARGO_IP}/g' /jenkins/ansible/inventory_cluster
                                sed -i 's/CARGO_PASSWORD/${INSTALL_CARGO_PASSWORD}/g' /jenkins/ansible/inventory_cluster
                                docker login ${SOURCE_REGISTRY} -u ${SOURCE_REGISTRY_USER} -p ${SOURCE_REGISTRY_PASSWORD}
                                docker login ${TARGET_REGISTRY} -u ${TARGET_REGISTRY_USER} -p ${TARGET_REGISTRY_PASSWORD}
                            """
                            if (params.install_option == "docker image") {
                                sh """
                                ansible -i /jenkins/ansible/inventory_cluster cargo -m copy -a "src=${KUBECONFIG_FILE} dest=/root/kubeconfig mode=0644"
                                ansible -i /jenkins/ansible/inventory_cluster cargo -m copy -a "src=/hack/auto_installation/cluster_setting.sh dest=/root/cluster_setting.sh mode=0644"
                                ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "docker login ${SOURCE_REGISTRY} -u ${SOURCE_REGISTRY_USER} -p ${SOURCE_REGISTRY_PASSWORD}"
                                ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "docker login ${TARGET_REGISTRY} -u ${TARGET_REGISTRY_USER} -p ${TARGET_REGISTRY_PASSWORD}"
                                ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "docker run --rm --name pangolin -e SOURCE_REGISTRY=${SOURCE_REGISTRY} \
                                                                                                    -e SOURCE_REGISTRY_USER=${SOURCE_REGISTRY_USER} -e SOURCE_PROJECT=${SOURCE_PROJECT} \
                                                                                                    -e SOURCE_REGISTRY_PASSWORD=${SOURCE_REGISTRY_PASSWORD} \
                                                                                                    -v /root/kubeconfig:/root/.kube/config/ -v /root/cluster_setting.sh:/pangolin/cluster_setting.sh \
                                                                                                    ${SOURCE_REGISTRY}/${SOURCE_PROJECT}/release:${TAG_NAME} \
                                                                                                    bash cluster_setting.sh"
                                """
                            } else if (params.install_option == "gzip package") {
                                sh """
                                    mkdir /compass -p
                                    rm -rf /compass/compass-component*
                                    if [ \${COMPASS_COMPONENT_URL%%:*} == "http" -o \${COMPASS_COMPONENT_URL%%:*} == "https" ]; then \
                                        wget \${COMPASS_COMPONENT_URL} -O /compass/${PRODUCT_NAME}-component.tar.gz; \
                                        ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "wget \${COMPASS_COMPONENT_URL} -O /root/${PRODUCT_NAME}-component.tar.gz"
                                    elif [ \${COMPASS_COMPONENT_URL%%:*} == "oss" ]; then \
                                        ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "wget http://192.168.128.136:3142/oss_config/ossutil -O /root/ossutil"
                                        ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "wget http://192.168.128.136:3142/oss_config/ossutilconfig -O /root/.ossutilconfig"
                                        ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "cd /root/ && chmod 777 ossutil && ./ossutil cp -ru \${COMPASS_COMPONENT_URL} /compass/"
                                    else \
                                        echo "package_url error"; \
                                    fi

                                    cp /jenkins/ansible/inventory.sample /jenkins/ansible/inventory
                                    sed -i 's/CARGO_IP/${RELEASE_CARGO_IP}/g' /jenkins/ansible/inventory
                                    sed -i 's/CARGO_PASSWORD/${RELEASE_CARGO_PASSWORD}/g' /jenkins/ansible/inventory
                                    ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "cd ${CARGO_DIR}/ && rm -rf compass-component*"
                                    ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "for file in \\`find /compass -name "*.tar.gz"\\`; do cp \$"{file}" ${CARGO_DIR}/compass-component.tar.gz; done"
                                    ansible -i /jenkins/ansible/inventory_cluster cargo -m copy -a "src=${KUBECONFIG_FILE} dest=${CARGO_DIR}/.kubectl.kubeconfig mode=0644"
                                    ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "cd ${CARGO_DIR}/ && tar xvf compass-component.tar.gz"
                                    ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "cd ${CARGO_DIR}/${PRODUCT_NAME}-component*/ && cp config.sample config"
                                    ansible -i /jenkins/ansible/inventory_cluster cargo -m copy -a "src=/hack/auto_installation/clean_components.sh dest=${CARGO_DIR}/${PRODUCT_NAME}-component*/"
                                    ansible -i /jenkins/ansible/inventory_cluster cargo -m copy -a "src=/hack/auto_installation/reinstall.sh dest=${CARGO_DIR}/${PRODUCT_NAME}-component*/"
                                    ansible -i /jenkins/ansible/inventory_cluster cargo -m shell -a "cd ${CARGO_DIR}/${PRODUCT_NAME}-component*/ && bash reinstall.sh"
                                """
                            } else {
                                echo "do not install cluster"
                            }
                        }
                    }
                }
                if (params.hotfix) {
                    stage("Make Hotfix") {
                        if (params.oem) {
                            HOTFIX_YAML_DIR = "oem-hotfixes"
                        } else {
                            HOTFIX_YAML_DIR = "release-hotfixes"
                        }
                        // bool params defined in Jenkins pipeline setting.
                        withCredentials([
                            [$class: "UsernamePasswordMultiBinding", credentialsId: "${RELEASE_CARGO_LOGIN}", passwordVariable: "RELEASE_CARGO_PASSWORD", usernameVariable: "RELEASE_CARGO_IP"],
                            [$class: "UsernamePasswordMultiBinding", credentialsId: "${SOURCE_REGISTRY_CREDENTIAL_ID}", passwordVariable: "SOURCE_REGISTRY_PASSWORD", usernameVariable: "SOURCE_REGISTRY_USER"],
                            [$class: "UsernamePasswordMultiBinding", credentialsId: "${TARGET_REGISTRY_CREDENTIAL_ID}", passwordVariable: "TARGET_REGISTRY_PASSWORD", usernameVariable: "TARGET_REGISTRY_USER"],
                        ]) {
                            sh """
                                cp /jenkins/ansible/inventory.sample /jenkins/ansible/inventory
                                sed -i 's/CARGO_IP/${RELEASE_CARGO_IP}/g' /jenkins/ansible/inventory
                                sed -i 's/CARGO_PASSWORD/${RELEASE_CARGO_PASSWORD}/g' /jenkins/ansible/inventory
                                ansible -i /jenkins/ansible/inventory cargo -m shell -a "docker login ${SOURCE_REGISTRY} -u ${SOURCE_REGISTRY_USER} -p ${SOURCE_REGISTRY_PASSWORD}"
                                ansible -i /jenkins/ansible/inventory cargo -m shell -a "docker login ${TARGET_REGISTRY} -u ${TARGET_REGISTRY_USER} -p ${TARGET_REGISTRY_PASSWORD}"
                                ansible -i /jenkins/ansible/inventory cargo -m shell -a "rm -rf ${HOTFIX_DIR} && mkdir -p ${HOTFIX_DIR}"
                                ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=${HOTFIX_YAML_DIR} dest=${HOTFIX_DIR} mode=0755"
                                ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/auto_hotfix/hotfix.sh dest=${HOTFIX_DIR} mode=0755"
                                ansible -i /jenkins/ansible/inventory cargo -m copy -a "src=hack/auto_hotfix/env.sh dest=${HOTFIX_DIR} mode=0755"
                                ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/source_registry/${SOURCE_REGISTRY}/g;s/source_project/${SOURCE_PROJECT}/g' ${HOTFIX_DIR}/env.sh"
                                ansible -i /jenkins/ansible/inventory cargo -m shell -a "sed -i 's/target_registry/${TARGET_REGISTRY}/g;s/target_project/${TARGET_PROJECT}/g' ${HOTFIX_DIR}/env.sh"
                                ansible -i /jenkins/ansible/inventory cargo -m shell -a "cd ${HOTFIX_DIR} && bash hotfix.sh hotfix ${HOTFIX_YAML_DIR}/${HOTFIX_YAML_PATH} ${PRODUCT_NAME}"
                            """
                        }
                    }
                    stage("Upload") {
                        def upload = upload()
                        if (upload) {
                            sh """
                                ansible -i /jenkins/ansible/inventory cargo -m shell -a "cd ${HOTFIX_DIR} && bash ${HOTFIX_DIR}/hotfix.sh upload ${HOTFIX_OSS_PATH} ${PRODUCT_NAME}"
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
            ansible -i /jenkins/ansible/inventory cargo -m shell -a "bash /root/package.sh judge ${RELEASE_VERSION} ${CARGO_DIR} ${PRODUCT_NAME} ${SYNC_DIR}"
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
