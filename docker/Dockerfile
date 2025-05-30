# This Dockerfile supports multiple environments

ARG RUBY_VERSION=3.3.7

FROM ruby:${RUBY_VERSION}

ARG APP_ENV=production
ARG APP_VERSION=2.3.9
ARG BUILD_IMAGE
ARG USERNAME=timetracker
ARG USER_UID=1000
ARG USER_GID=$USER_UID

WORKDIR /root

# Install NVM and Node.js
ARG NODE_VERSION=22.9.0
ENV NVM_DIR=/usr/local/nvm
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
RUN mkdir $NVM_DIR
RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# Install system dependencies
RUN apt-get update && apt-get install -y \
    tzdata git build-essential patch ruby-dev zlib1g-dev liblzma-dev default-jre \
    sudo vim nano tmux wget

# Install Chrome
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb;

WORKDIR /app

# Retrieve application code
COPY . .
RUN if [ "$BUILD_IMAGE" = "true" ]; then \
      rm -rf ./{*,.*} \
      && wget https://github.com/berkmancenter/timetracker/archive/refs/tags/${APP_VERSION}.tar.gz \
      && tar -xzf ${APP_VERSION}.tar.gz --strip-components=1 \
      && rm ${APP_VERSION}.tar.gz; \
    fi

# Create a user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

RUN sudo chown -R $USERNAME:$USERNAME /app

# Install node modules
RUN npm install --global yarn
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# Install and cache gems
RUN sudo gem update --system
RUN bundle install
RUN sudo gem install mailcatcher

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# To be able to create a .bash_history
WORKDIR /home/timetracker/hist
RUN sudo chown -R $USERNAME:$USERNAME /home/timetracker/hist

# Code mounted as a volume
WORKDIR /app
COPY docker/entrypoint.sh /usr/bin/timetracker-entrypoint

# Start the server by default, this can be overwritten at runtime
ENTRYPOINT ["timetracker-entrypoint"]
CMD ["sh", "-c", "./bin/rails server"]
