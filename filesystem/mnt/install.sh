#!/usr/bin/env bash
: "${GITLAB_RUNNER_REGISTRATION_KEY?}"
: "${DOCKER_REMOTE_ORIGIN?}"
: "${DOCKER_REMOTE_SA_USERNAME?}"
: "${DOCKER_REMOTE_SA_TOKEN?}"

##
echo "Install the base tools"

apt-get update
apt-get install -y \
 curl vim wget htop unzip gnupg2 \
 bash-completion git apt-transport-https ca-certificates \
 software-properties-common

##
echo "Install self-signed CA-s"

self_signed_dir="/usr/share/ca-certificates/self-signed"
for file in "$self_signed_dir"/*.crt; do
    my_crt="self-signed/$(basename "$file")"
    echo "$my_crt" >> /etc/ca-certificates.conf
done
update-ca-certificates --fresh --verbose

##
echo "Install GitLab Runner"

# Add the official GitLab repository
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash

# Disable skel & install
export GITLAB_RUNNER_DISABLE_SKEL=true
apt-get install gitlab-runner -y

echo "Register GitLab Runner"
gitlab-runner register \
    --non-interactive \
    --url https://gitlab.adm.acme.corp/gitlab \
    --registration-token "$GITLAB_RUNNER_REGISTRATION_KEY" \
    --tag-list "docker" \
    --executor shell

## Docker
echo "Add Docker’s official GPG key."
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "Use the following command to set up the stable repository."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
$(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Install Docker Engine."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

## Configuration
echo "Docker login."
docker login \
  --username ${DOCKER_REMOTE_SA_USERNAME} \
  --password ${DOCKER_REMOTE_SA_TOKEN} \
  ${DOCKER_REMOTE_ORIGIN}
