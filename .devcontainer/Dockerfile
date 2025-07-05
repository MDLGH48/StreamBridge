FROM swift:6.0

# Install Ruby, build essentials, and then CocoaPods
RUN apt-get update && apt-get install -y ruby-dev build-essential && \
    gem install cocoapods && \
    # Clean up apt caches to reduce final image size
    rm -rf /var/lib/apt/lists/*