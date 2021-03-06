#! /bin/bash
PROJECT_ID=$(curl -s http://metadata/computeMetadata/v1/project/project-id -H "Metadata-Flavor: Google")
RAW_ZONE=$(curl -s http://metadata/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google")
REGISTER_TOKEN=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/register_token -H "Metadata-Flavor: Google")
CONFIG_FILE=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/runner_config -H "Metadata-Flavor: Google")
CRT_FILE=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/crt_file -H "Metadata-Flavor: Google")
GITLAB_CI_URI=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/gitlab_uri -H "Metadata-Flavor: Google")
RUNNER_NAME=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/runner_name -H "Metadata-Flavor: Google")
RUNNER_TAGS=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/runner_tags -H "Metadata-Flavor: Google")
DOCKER_MACHINE_DL_URL="https://github.com/docker/machine/releases/download/v0.12.0/docker-machine-$(uname -s)-$(uname -m)"

export DEBIAN_FRONTEND=noninteractive

DEBUG="1"

function installDockerMachine() {
  if [ "$DEBUG" = "1" ]; then
    echo "exec: curl -s -L $DOCKER_MACHINE_DL_URL -o /usr/local/bin/docker-machine"
    echo "exec: chmod +x /usr/local/bin/docker-machine"
  fi
  curl -s -L $DOCKER_MACHINE_DL_URL -o /usr/local/bin/docker-machine
  chmod +x /usr/local/bin/docker-machine
}

function installRunner() {
  if [ "$DEBUG" = "1" ]; then
    echo "exec: curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | bash"
    echo "exec: apt-get install -y gitlab-ci-multi-runner"
  fi
  curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | bash
  apt-get install -y gitlab-ci-multi-runner
}

function registerRunner() {
  echo "$CRT_FILE"
  mkdir -p /etc/gitlab-runner/certs
  echo "$CRT_FILE" > /etc/gitlab-runner/certs/server.crt

  if [ "$DEBUG" = "1" ]; then
    echo "GOOGLE_APPLICATION_CREDENTIALS"
    echo $GOOGLE_APPLICATION_CREDENTIALS
    echo "exec: gitlab-ci-multi-runner register --config /etc/gitlab-runner/config.toml --non-interactive \
  --url $GITLAB_CI_URI --registration-token $REGISTER_TOKEN --tag-list $RUNNER_TAGS \
  --name $RUNNER_NAME --executor docker+machine --tls-ca-file /etc/gitlab-runner/certs/server.crt \
  --docker-image alpine/git:latest --docker-privileged"
  fi
  gitlab-ci-multi-runner register --config /etc/gitlab-runner/config.toml --non-interactive --docker-image alpine/git:latest \
  --url ${GITLAB_CI_URI} --registration-token ${REGISTER_TOKEN} --tag-list "$RUNNER_TAGS" \
  --name ${RUNNER_NAME} --executor docker --tls-ca-file /etc/gitlab-runner/certs/server.crt --docker-privileged

  local TOKEN=$(sed -n 's/.*token = "\(.*\)".*/\1/p' /etc/gitlab-runner/config.toml)
  echo "Runner registered with token $TOKEN"
  echo "$CONFIG_FILE"
  echo "$CONFIG_FILE" > "/etc/gitlab-runner/config.toml"

  local ZONE=${RAW_ZONE##*/}
  sed -i 's/PROJECT_ID/'${PROJECT_ID}'/' /etc/gitlab-runner/config.toml
  sed -i 's/ZONE/'${ZONE}'/' /etc/gitlab-runner/config.toml
  sed -i 's#GITLAB_CI_URI#'${GITLAB_CI_URI}'#' /etc/gitlab-runner/config.toml
  sed -i 's/RUNNER_NAME/'${RUNNER_NAME}'/' /etc/gitlab-runner/config.toml
  sed -i 's/RUNNER_TOKEN/'${TOKEN}'/' /etc/gitlab-runner/config.toml
}

function startRunner() {
  if [ "$DEBUG" = "1" ]; then
    echo "exec: gitlab-ci-multi-runner start"
  fi
  gitlab-ci-multi-runner start
}

echo "Installing Docker machine..."
installDockerMachine

echo "Installing Gitlab runner..."
installRunner

echo "Registering Gitlab runner..."
registerRunner

echo "Starting Gitlab runner..."
startRunner
