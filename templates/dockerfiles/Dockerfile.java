# Java 21 Development Environment
FROM openjdk:21-slim-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    vim \
    curl \
    wget \
    sudo \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user with sudo access
RUN groupadd -g 1000 node && \
    useradd -m -u 1000 -g 1000 -s /bin/bash node && \
    echo "node ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Maven
ARG MAVEN_VERSION=3.9.6
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | \
    tar xz -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven && \
    ln -s /opt/maven/bin/mvn /usr/local/bin/mvn

# Install Gradle
ARG GRADLE_VERSION=8.5
RUN curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt && \
    ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle && \
    ln -s /opt/gradle/bin/gradle /usr/local/bin/gradle && \
    rm /tmp/gradle.zip

# Install Claude Code CLI
RUN curl -fsSL https://claude.ai/install.sh | sh

# Set Java environment variables
ENV JAVA_HOME=/usr/local/openjdk-21 \
    MAVEN_HOME=/opt/maven \
    GRADLE_HOME=/opt/gradle \
    PATH=$PATH:$MAVEN_HOME/bin:$GRADLE_HOME/bin

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER node

# Default command
CMD ["/bin/bash"]
