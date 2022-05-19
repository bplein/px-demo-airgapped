FROM ubuntu:22.04

LABEL maintainer="plein@purestorage.com"

ENV HOME=/demo-vol
# Version of K8s for kubectl install
ARG KUBEVERSION=v1.22.6
# Version of s5cmd
ARG  S5CMDVERSION=2.0.0-beta.2
# helps apt run better non-interactively
ARG  DEBIAN_FRONTEND=noninteractive
ARG	 MYTIMEZONE=America/Chicago

WORKDIR /tmp
RUN apt-get update && apt install --no-install-recommends -y pv nano git bash-completion fio \
	unzip tzdata iperf3 iputils-ping vim sysstat tmux less \
	&& apt install -y wget curl openssh-client binutils \
    # takes longer to build, but more  secure if you upgrade....
    && apt-get -y upgrade \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /var/log/* 
# Install kubectl
RUN curl -Lo /usr/local/bin/kubectl https://dl.k8s.io/release/${KUBEVERSION}/bin/linux/amd64/kubectl \
	&& chmod 0755 /usr/local/bin/kubectl \
	&& kubectl completion bash >/etc/bash_completion.d/kubectl \
	&& echo 'alias k=kubectl' >>~/.bashrc \
	&& echo 'complete -F __start_kubectl k' >>~/.bashrc \
    && rm -rf /tmp/* \
# Install OpenShift CLI ("oc")
    ; curl -L https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz | tar xvzf - \
    && mv oc /usr/local/bin/ \
    && oc completion bash > /etc/bash_completion.d/oc_bash_completion \
    && rm -rf /tmp/* \
# Install Helm 3
    ; curl -L https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
# Install s5cmd
    ; curl -Lo /usr/local/bin/s5cmd https://github.com/peak/s5cmd/releases/download/v${S5CMDVERSION}/s5cmd_${S5CMDVERSION}_Linux-64bit.tar.gz | tar xzf - \
# Install awscli
    ; curl -Lo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
	&& rm -rf /tmp/*
RUN mkdir /assets && chmod 777 /assets && mkdir /demo-vol && chmod 777 /demo-vol
WORKDIR /assets
RUN git clone https://github.com/bplein/px-demo-postgres.git \
    && git clone https://github.com/bplein/px-demo-autopilot.git \
    && rm -rf  /assets/px-demo-postgres/.git /assets/px-demo-postgres/.gitattributes \
    && rm -rf  /assets/px-demo-autopilot/.git /assets/px-demo-autopilot/.gitattributes 
# hack to let this run in the background without failing
WORKDIR /
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"   