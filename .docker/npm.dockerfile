ARG NODE_VERSION=20.20.0
FROM node:${NODE_VERSION}

ARG NPM_TOKEN
ARG NPM_VERSION=10.9.2
ENV NPM_TOKEN=$NPM_TOKEN

RUN npm install -g npm@${NPM_VERSION}

RUN apt-get update \
    && apt-get install -y git openssh-client \
    && apt-get -y autoclean

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
