########################################################################
# Dockerfile for Oracle JDK 8 on Ubuntu 14.04
# contains following R versions:
#   - 3.4.1
#   - 3.3.3
#   - installed R versions can be overriden by setting the R_VERSIONS build arg
# contains following Python versions:
#   - 2.7
#   - 3.5
#   - 3.6
#   - installed Python versions can be overriden by setting the PYTHON_VERSIONS build arg
########################################################################

# pull base image
FROM ubuntu:16.04

# maintainer details
MAINTAINER h2oai "h2o.ai"

ARG R_VERSIONS='3.4.1,3.3.3'
ARG PYTHON_VERSIONS='3.6,3.5,2.7'
ARG JENKINS_UID='2117'
ARG JENKINS_GID='2117'
ARG H2O_BRANCH='master'
ENV H2O_DATA_DIR="/data"

# Initialize apt sources
RUN \
  echo 'DPkg::Post-Invoke {"/bin/rm -f /var/cache/apt/archives/*.deb || true";};' | tee /etc/apt/apt.conf.d/no-cache && \
  echo "deb http://ap-northeast-1.ec2.archive.ubuntu.com/ubuntu xenial main universe" >> /etc/apt/sources.list && \
  echo "deb http://cran.mtu.edu/bin/linux/ubuntu xenial/" >> /etc/apt/sources.list.d/cran.list && \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9 && \
  apt-get update -q -y && \
  apt-get dist-upgrade -y && \
  apt-get clean && \
  rm -rf /var/cache/apt/*

# Install packages
RUN \
  DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl s3cmd libffi-dev libxml2-dev libssl-dev \
  libcurl4-openssl-dev libfreetype6 libfreetype6-dev libfontconfig1 libfontconfig1-dev build-essential chrpath \
  libssl-dev libxft-dev git unzip python-pip python-dev python-virtualenv libmysqlclient-dev texlive \
  texlive-fonts-extra texlive-htmlxml python3 python3-dev python3-pip python3-virtualenv software-properties-common \
  python-software-properties texinfo texlive-bibtex-extra texlive-formats-extra texlive-generic-extra nodejs-legacy npm && \
  apt-get -y build-dep r-base

# Add repositories
RUN \
  add-apt-repository -y ppa:deadsnakes && \
  apt-get update -q -y

# Set required env vars and install Java 8
COPY scripts/install_java /usr/sbin
RUN \
  chmod 700 /usr/sbin/install_java && \
  sync && \
  /usr/sbin/install_java
ENV \
  JAVA_HOME=/usr/lib/jvm/java-8-oracle \
  PATH=/usr/lib/jvm/java-8-oracle/bin:${PATH}

# Install from source dependencies
RUN \
  wget https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
  tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 -C /usr/local/share/ && \
  rm phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
  ln -sf /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin && \
  wget https://github.com/jgm/pandoc/releases/download/2.3/pandoc-2.3-linux.tar.gz && \
  tar -xvzf pandoc-2.3-linux.tar.gz --strip-components 1 -C /usr/local/ && \
  which pandoc && \
  rm -rf pandoc-2.3-linux.tar.gz && \
  apt-get clean && \
  apt-get autoremove && \
  apt-get autoclean

# Copy required scripts
COPY scripts/install_python_versions /usr/sbin/
RUN \
  chmod 700 /usr/sbin/install_python_versions

# Install Python
RUN \
  /usr/sbin/install_python_versions

# Copy latest h2o.jar
USER root
RUN \
  mkdir -p /opt/h2o-3/logs && \
  cd /opt/h2o-3 && \
  wget http://h2o-release.s3.amazonaws.com/h2o/rel-wright/7/h2o-3.20.0.7.zip && \
  unzip /opt/h2o-3/h2o-3.20.0.7.zip && \
  mv /opt/h2o-3/h2o-3.20.0.7/h2o.jar /opt/h2o-3/ && \
  rm /opt/h2o-3/h2o-3.20.0.7.zip && \
  chmod -R 777 /opt/h2o-3
