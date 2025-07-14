# OWASP Note CI/CD Docker Image
# Based on Flutter official image with additional CI/CD tools

FROM ghcr.io/cirruslabs/flutter:stable

# Metadata
LABEL maintainer="OWASP Note Team"
LABEL description="CI/CD environment for OWASP Note Flutter application"
LABEL version="1.0"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_SDK_ROOT=$ANDROID_HOME
ENV PATH=$PATH:$ANDROID_SDK_ROOT/emulator
ENV PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
ENV PATH=$PATH:/opt/sonar-scanner/bin
ENV PATH=$PATH:/usr/local/bin

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget \
    jq \
    python3 \
    python3-pip \
    nodejs \
    npm \
    docker.io \
    build-essential \
    ruby \
    ruby-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Firebase CLI
RUN npm install -g firebase-tools

# Install fastlane for mobile deployment
RUN gem install fastlane -NV

# Install SonarScanner
RUN wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip \
    && unzip -q sonar-scanner-cli-4.8.0.2856-linux.zip -d /opt \
    && mv /opt/sonar-scanner-4.8.0.2856-linux /opt/sonar-scanner \
    && rm sonar-scanner-cli-4.8.0.2856-linux.zip

# Install JFrog CLI
RUN curl -fL https://getcli.jfrog.io/v2/jfrog | sh \
    && chmod +x jfrog \
    && mv jfrog /usr/local/bin/

# Install additional Flutter packages
RUN flutter pub global activate coverage
RUN flutter pub global activate very_good_cli
RUN flutter pub global activate flutter_launcher_icons

# Install security scanning tools
RUN pip3 install safety bandit

# Create working directory
WORKDIR /workspace

# Pre-download Flutter dependencies
RUN flutter precache --android --web --linux

# Android SDK licenses
RUN mkdir -p $ANDROID_SDK_ROOT/licenses \
    && echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > $ANDROID_SDK_ROOT/licenses/android-sdk-license \
    && echo "84831b9409646a918e30573bab4c9c91346d8abd" > $ANDROID_SDK_ROOT/licenses/android-sdk-preview-license

# Clean up
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD flutter doctor || exit 1

# Set up non-root user for security
RUN useradd -m -s /bin/bash flutter
RUN chown -R flutter:flutter /workspace
USER flutter

# Entry point
ENTRYPOINT ["/bin/bash"]