## this is meant to be a slightly more flexible container
## for running Hail in a Docker
## it is built based on Ubuntu and uses the latest Hail code
## cloned directly from github
## assumes that default open-jdk uses java8

FROM ubuntu:bionic
MAINTAINER Francesco Lescai lescai@biomed.au.dk


RUN apt-get update --fix-missing && apt-get install -y \
	default-jre \
	default-jdk \
	python-pip \
	ca-certificates \
    cmake \
    g++ \
    git \
    libc6-dev \
    wget \
    curl
    
ENV SPARK_HOME=/usr/spark/spark-2.1.0-bin-hadoop2.7 \
    HAIL_HOME=/usr/hail \
    PATH=/opt/conda/bin:$PATH:/usr/spark/spark-2.1.0-bin-hadoop2.7/bin:/usr/hail/build/install/hail/bin/ \
    GRADLE_USER_HOME=/usr/home

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda2-4.1.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

RUN mkdir -p /usr/spark && \
    curl -sL --retry 3 \
    "https://archive.apache.org/dist/spark/spark-2.1.0/spark-2.1.0-bin-hadoop2.7.tgz" \
    | gzip -d \
    | tar x -C /usr/spark && \
    chown -R root:root $SPARK_HOME

RUN pip install decorator && \
	pip install --upgrade pip && \
	pip install py4j && \
	pip install seaborn

RUN cd /usr && \
	git clone --branch 0.1 https://github.com/broadinstitute/hail.git && \
    cd ${HAIL_HOME} && \
    ./gradlew -Dspark.version=2.1.0 shadowJar && \
    echo 'alias pyhail="PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.3-src.zip:$HAIL_HOME/python SPARK_CLASSPATH=$HAIL_HOME/build/libs/hail-all-spark.jar python"' >> ~/.bashrc

ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.3-src.zip:$HAIL_HOME/python \
    SPARK_CLASSPATH=$HAIL_HOME/build/libs/hail-all-spark.jar

ENTRYPOINT ["python"]
