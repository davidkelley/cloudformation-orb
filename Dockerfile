FROM circleci/node:12

USER root

RUN apt-get update && \
  apt-get install -y \
  python3 \
  python3-pip \
  python3-setuptools && \
  pip3 install --upgrade pip && \
  apt-get clean

RUN pip3 --no-cache-dir install --upgrade awscli