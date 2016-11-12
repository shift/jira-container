FROM quay.io/goodguide/oracle-java:alpine-3.4-java8-5

MAINTAINER Vincent Palmer <@shift>

ENV JIRA_VERSION=7.2.4
ENV JIRA_HOME     /var/atlassian/application-data/jira
ENV JIRA_INSTALL  /opt/atlassian/jira
ENV JIRA_DOWNLOAD_URL https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-core-${JIRA_VERSION}.tar.gz

ENV RUN_USER            daemon
ENV RUN_GROUP           daemon

RUN apk add --update gzip curl tar build-base apr-dev openssl-dev \
      && mkdir -p                           "${JIRA_HOME}" \
      && chmod -R 700                       "${JIRA_HOME}" \
      && chown ${RUN_USER}:${RUN_GROUP}     "${JIRA_HOME}" \
      && mkdir -p                           "${JIRA_INSTALL}/conf" \
      && curl -Ls                           "${JIRA_DOWNLOAD_URL}" | tar -xz --directory "${JIRA_INSTALL}" --strip-components=1 --no-same-owner \
      && chmod -R 700                       "${JIRA_INSTALL}/conf" \
      && chmod -R 700                       "${JIRA_INSTALL}/temp" \
      && chmod -R 700                       "${JIRA_INSTALL}/logs" \
      && chmod -R 700                       "${JIRA_INSTALL}/work" \
      && chown -R ${RUN_USER}:${RUN_GROUP}  "${JIRA_INSTALL}/conf" \
      && chown -R ${RUN_USER}:${RUN_GROUP}  "${JIRA_INSTALL}/temp" \
      && chown -R ${RUN_USER}:${RUN_GROUP}  "${JIRA_INSTALL}/logs" \
      && chown -R ${RUN_USER}:${RUN_GROUP}  "${JIRA_INSTALL}/work" \
      && echo -e                            "\njira.home=${JIRA_HOME}" >> "${JIRA_INSTALL}/atlassian-jira/WEB-INF/classes/jira-init.properties" \
      && touch -d "@0"                      "${JIRA_INSTALL}/conf/server.xml" \
      && curl -Ls https://github.com/kelseyhightower/confd/releases/download/v0.11.0/confd-0.11.0-linux-amd64 -o /usr/local/bin/confd \
      && chmod 0755 /usr/local/bin/confd \
      && curl -Ls https://github.com/AcalephStorage/kviator/releases/download/v0.0.7/kviator-0.0.7-linux-amd64.zip -o /usr/local/bin/kviator.zip \
      && cd /usr/local/bin \
      && unzip kviator.zip \
      && cd /tmp && curl -Ls -O http://www-eu.apache.org/dist/tomcat/tomcat-connectors/native/1.2.10/source/tomcat-native-1.2.10-src.tar.gz \
      && ls -lhart | grep tomcat \
      && tar xfvz tomcat-native-1.2.10-src.tar.gz \
      && cd tomcat-native-1.2.10-src/native \
      && ./configure --with-java-home=${JAVA_HOME} --prefix=/opt/atlassian/jira --libdir=/usr/lib \
      && make && make install \
      && cd ../.. && rm -rf tc.tar.gz tomcat-native-1.2.10-src



WORKDIR ${JIRA_INSTALL}

EXPOSE 8080/tcp

ADD entrypoint.sh /entrypoint.sh
ADD confd-conf.d /etc/confd/conf.d
ADD confd-templates /etc/confd/templates

CMD /entrypoint.sh
