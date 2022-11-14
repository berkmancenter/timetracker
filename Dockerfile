FROM ruby:3.0.2

WORKDIR /root

RUN apt-get update \
    && apt-get -y install tzdata git build-essential patch ruby-dev zlib1g-dev liblzma-dev default-jre sudo vim nano tmux nodejs npm

RUN sudo npm install --global yarn

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
