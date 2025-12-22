# === JAVA LANGUAGE ADDITIONS ===
# REQUIRED: Add to base multi-stage sources section:
#   FROM eclipse-temurin:21-jdk-jammy AS java-source
#   FROM maven:3.9-eclipse-temurin-21 AS maven-source
#   FROM gradle:8.5-jdk21 AS gradle-source
# ============================================================================

USER root

# Copy Java from Eclipse Temurin image (proxy-friendly)
# NOTE: Requires 'java-source' stage in base Dockerfile
COPY --from=java-source /opt/java/openjdk /opt/java/openjdk

# Copy Maven from official image (proxy-friendly)
# NOTE: Requires 'maven-source' stage in base Dockerfile
COPY --from=maven-source /usr/share/maven /opt/maven

# Copy Gradle from official image (proxy-friendly)
# NOTE: Requires 'gradle-source' stage in base Dockerfile
COPY --from=gradle-source /opt/gradle /opt/gradle

# Set Java environment variables
ENV JAVA_HOME=/opt/java/openjdk \
    MAVEN_HOME=/opt/maven \
    GRADLE_HOME=/opt/gradle \
    PATH=/opt/java/openjdk/bin:/opt/maven/bin:/opt/gradle/bin:$PATH

# Create symlinks for convenience
RUN ln -sf /opt/maven/bin/mvn /usr/local/bin/mvn && \
    ln -sf /opt/gradle/bin/gradle /usr/local/bin/gradle

USER node

# === END JAVA LANGUAGE ADDITIONS ===
