FROM ubuntu:20.04

SHELL ["/bin/bash", "-c"]

RUN mkdir /app
WORKDIR /app
COPY . .

ARG DEBIAN_FRONTEND=noninteractive

RUN echo "deb http://security.ubuntu.com/ubuntu bionic-security main" >> /etc/apt/sources.list
RUN apt update && apt-cache policy libssl1.0-dev

RUN apt-get update && apt-get install -qy procps curl ca-certificates gnupg build-essential libssl1.0-dev libpq-dev --no-install-recommends && apt-get clean
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
RUN curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
RUN curl -sSL https://get.rvm.io | bash -s
RUN source /etc/profile.d/rvm.sh && rvm install ruby-1.8.7 && gem update --system 1.8.25

RUN gem install bundler -v 1.16.4 && \
    bundle install

# Keep the container running
CMD (while true; do sleep 1; done;)
