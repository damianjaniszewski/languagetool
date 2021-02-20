FROM debian:stretch as build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get install -y \
        locales \
        bash \
        libgomp1 \
        openjdk-8-jdk-headless \
        git \
        maven \
        unzip \
    && apt-get clean

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

ARG LANGUAGETOOL_VERSION=5.2.3
RUN git clone https://github.com/languagetool-org/languagetool.git --depth 1 -b v${LANGUAGETOOL_VERSION} --single-branch

WORKDIR /languagetool
RUN ["mvn", "--projects", "languagetool-standalone", "--also-make", "package", "-DskipTests", "--quiet"]

ARG LANGUAGETOOL_VERSION=5.2
RUN unzip /languagetool/languagetool-standalone/target/LanguageTool-${LANGUAGETOOL_VERSION}.zip -d /dist

FROM openjdk:8-jre-alpine

RUN apk update \
    && apk add \
        bash \
        libgomp \
        gcompat

COPY --from=build /dist .

ARG LANGUAGETOOL_VERSION=5.2
WORKDIR /LanguageTool-${LANGUAGETOOL_VERSION}

RUN mkdir /nonexistent && touch /nonexistent/.languagetool.cfg
RUN addgroup -S languagetool && adduser -S languagetool -G languagetool

COPY --chown=languagetool start.sh start.sh
COPY --chown=languagetool config.properties config.properties

USER languagetool

CMD [ "bash", "start.sh" ]
