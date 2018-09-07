FROM ubuntu:16.04

RUN apt-get update && apt-get install -y apache2 lynx less

RUN a2dismod mpm_event && a2enmod alias cache deflate expires headers lbmethod_byrequests mpm_worker proxy proxy_balancer proxy_http proxy_wstunnel reqtimeout rewrite setenvif slotmem_shm status  && \
    echo > /var/www/html/index.html

COPY status.conf /etc/apache2/mods-available/status.conf
COPY mpm_worker.conf /etc/apache2/mods-available/mpm_worker.conf

CMD ["apache2ctl", "-d", "/etc/apache2", "-f", "/etc/apache2/apache2.conf", "-e", "info", "-DFOREGROUND"]
