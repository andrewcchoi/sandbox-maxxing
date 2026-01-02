# ============================================================================
# Java Language Partial
# ============================================================================
# Appended to base.dockerfile when user selects Java project type.
# Adds OpenJDK 21, Maven, and Gradle.
# ============================================================================

USER root

# Install OpenJDK 21
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-21-jdk \
    maven \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Gradle with retry logic
ARG GRADLE_VERSION=8.5
RUN for i in 1 2 3 4 5; do \
      wget --tries=3 --timeout=30 --waitretry=5 \
           "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" && break || sleep 10; \
    done && \
    unzip "gradle-${GRADLE_VERSION}-bin.zip" && \
    mv "gradle-${GRADLE_VERSION}" /opt/gradle && \
    rm "gradle-${GRADLE_VERSION}-bin.zip"

# Java and Gradle environment (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) && \
    mkdir -p /etc/profile.d && \
    echo "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-${ARCH}" > /etc/profile.d/java.sh && \
    chmod +x /etc/profile.d/java.sh
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV GRADLE_HOME=/opt/gradle
ENV PATH=$PATH:$GRADLE_HOME/bin

USER node

# Create Maven local repository
RUN mkdir -p /home/node/.m2
