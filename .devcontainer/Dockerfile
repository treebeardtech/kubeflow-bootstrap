# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.148.1/containers/python-3/.devcontainer/base.Dockerfile
ARG VARIANT="3.11"
FROM mcr.microsoft.com/vscode/devcontainers/python:0-${VARIANT} as devcontainer
ARG INSTALL_NODE="true"
ARG NODE_VERSION="lts/*"
RUN if [ "${INSTALL_NODE}" = "true" ]; then su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi
USER vscode
RUN pip3 --disable-pip-version-check --no-cache-dir install -U \
  'poetry==1.6.1' \
  'pre-commit==3.6.0' \
  'pip==23.2.1'
ENV DEBIAN_FRONTEND=noninteractive
RUN sudo apt-get update -y && sudo apt-get install -y \
  iputils-ping \
  traceroute \
  kmod \
  vim
ENV PATH="/home/vscode/.local/bin/:$PATH"
ENV EDITOR=vim
ENV HOMEBREW_NO_AUTO_UPDATE=1
ENV HOMEBREW_NO_INSTALL_UPGRADE=1