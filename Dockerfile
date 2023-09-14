FROM ruby:3.0.2

WORKDIR /root

RUN mkdir /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 18.14.1
RUN curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN apt-get update \
    && apt-get -y install tzdata git build-essential patch ruby-dev zlib1g-dev liblzma-dev default-jre sudo vim nano tmux

RUN npm install --global yarn

# Container user and group
ARG USERNAME=timetracker
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create a user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

# Install and cache gems
RUN sudo gem update --system
WORKDIR /
COPY Gemfile* /tmp/
RUN sudo chown -R $USERNAME:$USERNAME /tmp
WORKDIR /tmp
RUN bundle install

# To be able to create a .bash_history
WORKDIR /home/timetracker/hist
RUN sudo chown -R $USERNAME:$USERNAME /home/timetracker/hist

# Code mounted as a volume
WORKDIR /app

# Just to keep the containder running
CMD (while true; do sleep 1; done;)
