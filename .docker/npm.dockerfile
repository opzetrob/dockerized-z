FROM debian:latest
ARG NPM_TOKEN
ENV NPM_TOKEN=$NPM_TOKEN

# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# update the repository sources list
# and install dependencies
RUN apt-get update \
    && apt-get install -y curl \
    && apt-get install -y git \
    && apt-get install -y openssh-client \
    && apt-get -y autoclean

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 18.14.2

# install nvm
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash

# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

ENV GIT_SSH_COMMAND='ssh -Tv'
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh
RUN echo "@opzetter:registry=https://registry.npmjs.org" >> /root/.npmrc
RUN echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" >> /root/.npmrc

WORKDIR /var/www/html
COPY . .
CMD npm start

EXPOSE 3000
EXPOSE 3001
EXPOSE 5173
