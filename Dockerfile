FROM ubuntu

RUN apt-get update && \
  apt-get install -y \
  curl \
  git \
  ssh \
  tar \
  gzip \
  ca-certificates \
  python3 \
  python3-pip \
  python3-setuptools \
  groff \
  less \
  && pip3 install --upgrade pip \
  && apt-get clean

RUN pip3 --no-cache-dir install --upgrade awscli

RUN curl -LO "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" && \
    mv jq-linux64 /usr/bin/jq && \
    chmod 777 /usr/bin/jq