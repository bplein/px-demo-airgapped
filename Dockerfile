FROM ubuntu:22.04

LABEL maintainer="plein@purestorage.com"

# Version of K8s for kubectl install
ENV KUBEVERSION=v1.22.6
# Version of s5cmd
ARG  S5CMDVERSION=2.0.0-beta.2
# helps apt run better non-interactively
ARG  DEBIAN_FRONTEND=noninteractive
ARG	 MYTIMEZONE=America/Chicago

WORKDIR /tmp
RUN apt-get update && apt install --no-install-recommends -y pv nano git bash-completion fio \
	unzip tzdata iperf3 iputils-ping vim sysstat tmux \
	&& apt install -y wget curl openssh-client binutils \
    # takes longer to build, but more  secure if you upgrade....
    && apt-get -y upgrade \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /var/log/* 
# Install kubectl
RUN curl -LO https://dl.k8s.io/release/${KUBEVERSION}/bin/linux/amd64/kubectl \
	&& install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
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
    ; curl -L https://github.com/peak/s5cmd/releases/download/v${S5CMDVERSION}/s5cmd_${S5CMDVERSION}_Linux-64bit.tar.gz | tar xzf - \
    && mv s5cmd /usr/local/bin/ \
# Install awscli
    ; curl -Lo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
    && unzip awscliv2.zip \
    && ./aws/install \
	&& rm -rf /tmp/*
RUN mkdir /root/assets
WORKDIR /root/assets
RUN git clone https://github.com/bplein/px-demo-postgres.git \
    && git clone https://github.com/bplein/px-demo-autopilot.git
# hack to let this run in the background without failing
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"   