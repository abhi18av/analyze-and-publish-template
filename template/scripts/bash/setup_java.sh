#!/usr/bin/env sh

# scripts/setup_java.sh

# Install SDKMAN if not already installed
#if [ ! -d "$HOME/.sdkman" ]; then
#  curl -s "https://get.sdkman.io" | bash
#  source "$HOME/.sdkman/bin/sdkman-init.sh"
#fi

# Install GraalVM (replace '22.3.1.r17-grl' with preferred version)
sdk install java 24-graal

#LTS
#sdk install java 21.0.7-graal
#sdk install java 21.0.7-zulu
#sdk install java 21.0.7-librca
#sdk install java 21.0.7.fx-librca

# Set GraalVM as the default JDK
sdk default java 24-graal

# Verify installation
java -version
