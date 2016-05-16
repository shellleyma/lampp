FROM debian:jessie
MAINTAINER Tomas Jasek<tomsik68 (at) gmail (dot) com> 

ENV DEBIAN_FRONTEND noninteractive
# curl is needed to download the xampp installer, net-tools provides netstat command for xampp
RUN \
       apt-get update \
    && apt-get -y install curl net-tools \
    && curl -o xampp-linux-installer.run "https://downloadsapachefriends.global.ssl.fastly.net/xampp-files/5.6.8/xampp-linux-x64-5.6.8-0-installer.run?from_af=true" \
    && chmod +x xampp-linux-installer.run \
    && bash -c './xampp-linux-installer.run' \
    && ln -sf /opt/lampp/lampp /usr/bin/lampp \
    && apt-get clean

# Enable XAMPP web interface(remove security checks)
RUN \
       bash -c 'head --lines=-7 /opt/lampp/etc/extra/httpd-xampp.conf | tee /opt/lampp/etc/extra/httpd-xampp.conf.new ' \
    && mv /opt/lampp/etc/extra/httpd-xampp.conf.new /opt/lampp/etc/extra/httpd-xampp.conf

# Create a /www folder and a symbolic link to it in /opt/lampp/htdocs. It'll be accessible via http://localhost:[port]/www/
# This is convenient because it doesn't interfere with xampp, phpmyadmin or other tools in /opt/lampp/htdocs
RUN \
    mkdir /www \
    && ln -s /www /opt/lampp/htdocs/

# SSH server
RUN \
    apt-get update \
    && apt-get install -y -q supervisor openssh-server \
    && mkdir -p /var/run/sshd \
    && apt-get clean

# Output supervisor config file to start openssh-server
RUN echo "[program:openssh-server]" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf
RUN echo "command=/usr/sbin/sshd -D" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf
RUN echo "numprocs=1" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf
RUN echo "autostart=true" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf
RUN echo "autorestart=true" >> /etc/supervisor/conf.d/supervisord-openssh-server.conf

# Allow root login via password
# root password is: root
RUN sed -ri 's/PermitRootLogin without-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/22/2222/g' /etc/ssh/sshd_config 

# Set root password
# password hash generated using this command: openssl passwd -1 -salt xampp root
RUN sed -ri 's/root\:\*/root\:\$1\$xampp\$5\/7SXMYAMmS68bAy94B5f\./g' /etc/shadow

# Few handy utilities which are nice to have
RUN \
       apt-get update \
    && apt-get -y install nano vim less --no-install-recommends \
    && apt-get clean

VOLUME [ "/var/log/mysql/", "/var/log/apache2/" ]

EXPOSE 3306
EXPOSE 2222
EXPOSE 80

# write a startup script
RUN echo '/opt/lampp/lampp start' >> /startup.sh
RUN echo '/usr/bin/supervisord -n' >> /startup.sh

CMD ["sh", "/startup.sh"]
