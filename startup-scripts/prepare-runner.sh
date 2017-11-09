#! /bin/bash
PROJECT_ID=$(curl -s http://metadata/computeMetadata/v1/project/project-id -H "Metadata-Flavor: Google")
RAW_ZONE=$(curl -s http://metadata/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google")
REGISTER_TOKEN=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/register_token -H "Metadata-Flavor: Google")
CONFIG_BUCKET=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/config_bucket -H "Metadata-Flavor: Google")
GITLAB_CI_URI=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/gitlab_uri -H "Metadata-Flavor: Google")
RUNNER_NAME=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/runner_name -H "Metadata-Flavor: Google")
RUNNER_TAGS=$(curl -s http://metadata/computeMetadata/v1/instance/attributes/runner_tags -H "Metadata-Flavor: Google")
DOCKER_MACHINE_DL_URL="https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-$(uname -s)-$(uname -m)"

export DEBIAN_FRONTEND=noninteractive

DEBUG="1"

function downloadConfigurationFilesFromStorage() {
  if [ "$DEBUG" = "1" ]; then
    echo "exec: rm -fR /tmp/configs"
    echo "exec: /usr/bin/gsutil cp -r gs://$CONFIG_BUCKET /tmp/configs"
  fi
  rm -fR /tmp/configs
  /usr/bin/gsutil cp -r gs://$CONFIG_BUCKET /tmp/configs
}

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
mkdir -p /etc/gitlab-runner/certs
cat << EOF > /etc/gitlab-runner/certs/server.crt
-----BEGIN CERTIFICATE-----
MIIFgDCCA2igAwIBAgIJAItb74zSHEGkMA0GCSqGSIb3DQEBCwUAME4xCzAJBgNV
BAYTAlVBMQ0wCwYDVQQIDARLSUVWMQ0wCwYDVQQHDARLSUVWMSEwHwYDVQQKDBhJ
bnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwHhcNMTcxMTA5MTExMjM2WhcNMjcxMTA3
MTExMjM2WjBOMQswCQYDVQQGEwJVQTENMAsGA1UECAwES0lFVjENMAsGA1UEBwwE
S0lFVjEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIICIjANBgkq
hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAw47PJdVqt70O9bAMFeuUHkheaSPqlzXq
HciWQKR1dc/aP/KJWZJV8S3w2YMsaS84pmDyKz3Ix8CYHdfOqJzDvZV2xfjdkpQm
mqK9xQrg4v6X2fyyqHdOyjVCO0LQ5ClWtlQUwTN+ATU/2I9Lmi5tFX2xHWtVztn1
7qT9LfAuWRLnPWAolzNR1ah3F4aCNl4N234BjXO7RouXoJBSJYAQIDUojdPEu5/1
1vgvpZHdELUrCEIYWEt9qWHQIj71sjydupgJKYQYkMTpTMnQwyIWkNPLfi5v7/bR
tl5bmYPFV8YK0tD6mX2ZqEecmQ32DnLDxM4eX5ui9MDBbbNZfJxjh/Fvp8TDWBM1
drqcOS9fCGrIjxhgUDyPYblzDZT5Yu6/ml0WDRj2qahQaHFqvBO8QjcLgUymTa9Z
csXzYi1eglsxuFfnbi4kOO8XhkqWmVQRS3AoiztEcvAjwNH87t+45tSaJwuwZHq6
n+UDNhf9+3hYN8sF+EUfkuAtepP85T93TFJyalr/XnhCrCLb6QPGdjDUIYuhYNn+
GrfqRHbtGy2XN9cL5URfHCyPGxmxMLq9u6yYMeeDwvoJSiEeCZmME3YHaxIub8Bo
6x4hXTerJWMG8ns/ArXgpGCRUQE8/SSiDvtiipPjwJ6B1jGn/Liw73KLbbqbb82c
Qfi6G9X19HECAwEAAaNhMF8wDwYDVR0RBAgwBocEI731UzAdBgNVHQ4EFgQUpnSD
++NoQ8LBUh3QmGLxUE4s2oIwHwYDVR0jBBgwFoAUpnSD++NoQ8LBUh3QmGLxUE4s
2oIwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAgEAuvKw67bkFVI/my1/
B0i44CCNbPpIyCS0QI496eTRT+XiLSSEixweTSd9W3ll/7/l85srXQZ7cOKdUAv1
vosieip7QQI8/otOYUcVS2yODUwFOMk7tO0YoldznsCrOuYjnHxv2YHDSS6A+3qJ
SO7uF4GP8NdaAUZRBDjli0wWiGzhzFRK93qGqpKCpozJGjWx6ecLs931Tlw5/Kor
QY7hkLtG+FSQjQP0vYE5Pq3SlhXV4gPoU4A16TdVZUA9LA8VnmD4wgx7TMpvp9bl
w7WdKiaq4RBXVSuFY1Rd6oVx375/5cY3eiF2oS7dmhEgnIfOvgxGvnXmwy3R/Tw/
J9R37cZ8znBPhNjiE7udFsTgNZwsOXskdd1+xycQBap7qZS+AOBDdct0cEcdZGtN
omOXBtd/TJn7mni876SAH7aDcihMo9bzDjZFnmAr3gaAYADML7mG2/RJnHZ5U3mK
oQj64XQ9+CILwbsRSHrAeoGv/Yxzmry65WxZ4fznjT8ttvPIi6+qevkgpQsvURdE
d+py7RLablxBdTec3EpufH9GJqGORcE9Lum1gCMW828iPRH9TiKFRQlOtxODgJfL
NkZX+9xUMcf1xSScoOWt4JgLxwGdG1qa1v3yzG0nl7qhok2X0cg3tdbMzrnmodfq
mUqFqt3712DflIWwlIqcNy8+slA=
-----END CERTIFICATE-----
EOF

  if [ "$DEBUG" = "1" ]; then
    echo "exec: gitlab-ci-multi-runner register --config /etc/gitlab-runner/config.toml --non-interactive \
  --url $GITLAB_CI_URI --registration-token $REGISTER_TOKEN --tag-list $RUNNER_TAGS \
  --name $RUNNER_NAME --executor docker+machine --tls-ca-file /etc/gitlab-runner/certs/server.crt \
   --docker-image alpine/git:latest"
  fi
  gitlab-ci-multi-runner register --config /etc/gitlab-runner/config.toml --non-interactive --docker-image alpine/git:latest \
  --url ${GITLAB_CI_URI} --registration-token ${REGISTER_TOKEN} --tag-list "$RUNNER_TAGS" \
  --name ${RUNNER_NAME} --executor docker+machine --tls-ca-file /etc/gitlab-runner/certs/server.crt

  local TOKEN=$(sed -n 's/.*token = "\(.*\)".*/\1/p' /etc/gitlab-runner/config.toml)
  echo "Runner registered with token $TOKEN"
  cp /tmp/configs/shared-as.toml /etc/gitlab-runner/config.toml

  local ZONE=${RAW_ZONE##*/}
  sed -i 's/PROJECT_ID/'${PROJECT_ID}'/' /etc/gitlab-runner/config.toml
  sed -i 's/ZONE/'${ZONE}'/' /etc/gitlab-runner/config.toml
  sed -i 's/RUNNER_NAME/'${RUNNER_NAME}'/' /etc/gitlab-runner/config.toml
  sed -i 's/GITLAB_CI_URI/'${GITLAB_CI_URI}'/' /etc/gitlab-runner/config.toml
  sed -i 's/RUNNER_TOKEN/'${TOKEN}'/' /etc/gitlab-runner/config.toml
}

function startRunner() {
  if [ "$DEBUG" = "1" ]; then
    echo "exec: gitlab-ci-multi-runner start"
  fi
  gitlab-ci-multi-runner start
}

echo "Downloading configuration files..."
downloadConfigurationFilesFromStorage

echo "Installing Docker machine..."
installDockerMachine

echo "Installing Gitlab runner..."
installRunner

echo "Registering Gitlab runner..."
registerRunner

echo "Starting Gitlab runner..."
startRunner
