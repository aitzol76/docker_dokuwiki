# VERSION 0.2
# AUTHOR:         Miroslav Prasil <miroslav@prasil.info>
# DESCRIPTION:    Image with DokuWiki & lighttpd
# TO_BUILD:       docker build -t mprasil/dokuwiki .
# TO_RUN:         docker run -d -p 80:80 --name my_wiki mprasil/dokuwiki


FROM ubuntu:22.04
MAINTAINER Miroslav Prasil <miroslav@prasil.info>

# Set the version you want of dokuwiki
# https://download.dokuwiki.org/archive
ENV DOKUWIKI_VERSION=2022-07-31a
ARG DOKUWIKI_CSUM=4459ea99e3a4ce2b767482f505724dcc
ARG DOKUWIKI_DEBIAN_PACKAGES=""

# Update & install packages & cleanup afterwards
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        wget \
        lighttpd \
        php-cgi \
        php-gd \
        php-ldap \
        php-curl \
        php-xml \
        php-mbstring \
        perl-modules-5.34 \
        ${DOKUWIKI_DEBIAN_PACKAGES} && \
    apt-get clean autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

# Download & check & deploy dokuwiki & cleanup
RUN wget -q -O /dokuwiki.tgz "https://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz" && \
    if [ "$DOKUWIKI_CSUM" != "$(md5sum /dokuwiki.tgz | awk '{print($1)}')" ];then echo "Wrong md5sum of downloaded file!"; exit 1; fi && \
    mkdir /dokuwiki && \
    tar -zxf dokuwiki.tgz -C /dokuwiki --strip-components 1

# Set up ownership
RUN chown -R www-data:www-data /dokuwiki

# Configure lighttpd
ADD dokuwiki.conf /etc/lighttpd/conf-available/20-dokuwiki.conf
RUN lighty-enable-mod dokuwiki fastcgi accesslog
RUN mkdir /var/run/lighttpd && chown www-data.www-data /var/run/lighttpd

COPY docker-startup.sh /startup.sh

EXPOSE 80
VOLUME ["/dokuwiki/data/","/dokuwiki/lib/plugins/","/dokuwiki/conf/","/dokuwiki/lib/tpl/","/var/log/"]

ENTRYPOINT ["/startup.sh"]
CMD ["run"]
