FROM ubuntu:resolute-20260811.1

ARG TARGETOS
ARG TARGETARCH
ARG ACTIONS_RUNNER_VERSION="2.337.0"
ARG TRIVY_VERSION="0.74.0"
ARG NODE_VERSION="26"
ARG DOTNET_VERSION="10"
ARG JDK_VERSION="25"
ARG POETRY_VERSION="2.4.1"
ARG ARGOCD_VERSION="3.5.2"

RUN apt-get update && \
    apt-get install curl tar sudo -y

RUN useradd -m -s /bin/bash runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /github

RUN if [ "$TARGETARCH" = "amd64" ]; then PLATFORM="x64"; else PLATFORM="${TARGETARCH:-x64}"; fi && \
    if [ -z "$TARGETOS" ]; then OS="linux"; else OS="$TARGETOS"; fi && \
    curl -o actions-runner-$OS-$PLATFORM-$ACTIONS_RUNNER_VERSION.tar.gz -L "https://github.com/actions/runner/releases/download/v${ACTIONS_RUNNER_VERSION}/actions-runner-${OS}-${PLATFORM}-${ACTIONS_RUNNER_VERSION}.tar.gz" && \
    tar xzf actions-runner-$OS-$PLATFORM-$ACTIONS_RUNNER_VERSION.tar.gz && \
    rm actions-runner-$OS-$PLATFORM-$ACTIONS_RUNNER_VERSION.tar.gz && \
    chown -R runner:runner /github

RUN ./bin/installdependencies.sh

RUN awk '{ gsub(/http:\/\/archive\.ubuntu\.com\/ubuntu\//, "http://br.archive.ubuntu.com/ubuntu/"); print }' /etc/apt/sources.list.d/ubuntu.sources > /tmp/ubuntu.sources && mv /tmp/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources

RUN apt-get update

# Install requirements
RUN apt-get install -y curl \
    git \
    jq \
    yq \
    libicu78 \
    rsync \
    wget \
    inetutils-ping \
    bind9-utils \
    dnsutils \
    gnupg \
    ca-certificates \
    lsb-release \
    build-essential \
    software-properties-common \
    apt-transport-https \
    golang-go

# Install trivy
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v$TRIVY_VERSION

# Install ArgoCD CLI

RUN curl -L -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-${TARGETARCH} && \
    chmod +x /usr/local/bin/argocd

# Install nodejs 26 e yarn
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    npm install --global yarn

RUN npm install -g snyk

# Install OpenJDK 25
RUN apt-get install -y openjdk-${JDK_VERSION}-jdk maven

RUN wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update

# Install .NET 10.0 SDK + Runtime e Nuget
RUN apt-get install -y dotnet-sdk-${DOTNET_VERSION}.0 aspnetcore-runtime-${DOTNET_VERSION}.0 mono-complete

# Install Python3
RUN apt-get install -y python3 python3-pip python3-venv python3-dev python3-pytest python3-requests \
    python3-flake8 python3-mypy python3-bandit python3-flask python3-setuptools

# Install Python Poetry
ENV POETRY_HOME="/opt/poetry"
ENV POETRY_VENV_IN_PROJECT=true
RUN curl -sSL https://install.python-poetry.org | python3 - --version ${POETRY_VERSION}
RUN chmod +x /opt/poetry/bin/poetry
RUN mv /opt/poetry/bin/poetry /usr/local/bin/poetry

# Install kubectl
RUN curl -o "/usr/bin/kubectl" -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" && \
    chmod +x /usr/bin/kubectl

RUN curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
RUN apt-get update
RUN apt-get install helm -y

# Clean files
RUN apt-get clean all

WORKDIR /github
COPY --chown=runner:runner entrypoint.sh .
RUN chmod +x entrypoint.sh

USER runner
ENTRYPOINT ["./entrypoint.sh"]