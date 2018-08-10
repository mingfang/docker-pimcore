FROM ubuntu:16.04 as base

ENV DEBIAN_FRONTEND=noninteractive TERM=xterm
RUN echo "export > /etc/envvars" >> /root/.bashrc && \
    echo "export PS1='\[\e[1;31m\]\u@\h:\w\\$\[\e[0m\] '" | tee -a /root/.bashrc /etc/skel/.bashrc && \
    echo "alias tcurrent='tail /var/log/*/current -f'" | tee -a /root/.bashrc /etc/skel/.bashrc

RUN apt-get update
RUN apt-get install -y locales && locale-gen en_US.UTF-8 && dpkg-reconfigure locales
ENV LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# Runit
RUN apt-get install -y --no-install-recommends runit
CMD bash -c 'export > /etc/envvars && /usr/sbin/runsvdir-start'

# Utilities
RUN apt-get install -y --no-install-recommends vim less net-tools inetutils-ping wget curl git telnet nmap socat dnsutils netcat tree htop unzip sudo software-properties-common jq psmisc iproute python ssh rsync gettext-base

# PHP 7.1
RUN apt-get install -y python-software-properties && \
    add-apt-repository -y ppa:ondrej/php && \
    apt-get update -y
RUN apt-get install -y php-fpm php-xml php-mbstring php-mysql php-mcrypt php-intl php-zip php-imap php-curl php-gd php-bcmath php-bz2 php-apcu php-imagick php-redis

# Requirements

RUN apt-get install -y build-essential
RUN apt-get install -y cron nginx mysql-client
RUN apt-get install -y libreoffice libreoffice-script-provider-python libreoffice-math xfonts-75dpi poppler-utils inkscape libxrender1 libfontconfig1 ghostscript libimage-exiftool-perl ffmpeg
RUN apt-get install -y html2text 

# ImageMagick v7
RUN wget -O - http://www.imagemagick.org/download/ImageMagick.tar.gz | tar zx && \
    cd ImageMagick-7.* && \
    ./configure && \
    make -j$(nproc) && \
    make install && \
    ldconfig /usr/local/lib && \
    rm -r ../ImageMagick-7.*

# wkhtmltopdf
RUN apt-get install -y libpng16-16 xfonts-base
RUN wget -O - https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz | tar xJ && \
    mv wkhtmltox/bin/wkhtmlto* /usr/bin/ && \
    rm -rf wkhtmltox

# facedetect
RUN apt-get install -y python3-pip opencv-data
RUN pip3 install numpy opencv-python
RUN git clone --depth 1 https://github.com/wavexx/facedetect.git && \
    cp facedetect/facedetect /usr/local/bin && \
    rm -r facedetect

RUN wget https://github.com/imagemin/zopflipng-bin/raw/master/vendor/linux/zopflipng -O /usr/local/bin/zopflipng && \
    chmod 0755 /usr/local/bin/zopflipng
RUN wget https://github.com/imagemin/pngcrush-bin/raw/master/vendor/linux/pngcrush -O /usr/local/bin/pngcrush && \
    chmod 0755 /usr/local/bin/pngcrush
RUN wget https://github.com/imagemin/jpegoptim-bin/raw/master/vendor/linux/jpegoptim -O /usr/local/bin/jpegoptim && \
    chmod 0755 /usr/local/bin/jpegoptim
RUN wget https://github.com/imagemin/pngout-bin/raw/master/vendor/linux/x64/pngout -O /usr/local/bin/pngout && \
    chmod 0755 /usr/local/bin/pngout
RUN wget https://github.com/imagemin/advpng-bin/raw/master/vendor/linux/advpng -O /usr/local/bin/advpng && \
    chmod 0755 /usr/local/bin/advpng
RUN wget https://github.com/imagemin/mozjpeg-bin/raw/master/vendor/linux/cjpeg -O /usr/local/bin/cjpeg && \
    chmod 0755 /usr/local/bin/cjpeg

# Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

# Pimcore

RUN cd /var/www && \
    COMPOSER_MEMORY_LIMIT=3G composer create-project --no-dev pimcore/demo-ecommerce pimcore
    #COMPOSER_MEMORY_LIMIT=3G composer create-project --no-dev pimcore/skeleton pimcore
    #COMPOSER_MEMORY_LIMIT=3G composer create-project --no-dev pimcore/demo-basic pimcore

RUN cd /var/www/pimcore && \
    composer install --no-dev && \
    rm -r /var/www/pimcore/var/cache && \
    rm -r /var/www/pimcore/var/logs && \
    rm -r /var/www/pimcore/var/tmp 

RUN chown -R www-data:www-data /var/www
RUN mv /var/www/pimcore/var /var/www/pimcore/var.original
RUN mv /var/www/pimcore/web/var /var/www/pimcore/web/var.original

RUN chmod +x /var/www/pimcore/bin/*
COPY etc/nginx/default /etc/nginx/sites-enabled/
RUN cp /etc/php/7.2/fpm/php.ini  /etc/php/7.2/fpm/php.ini.original
COPY etc/php/php.ini  /etc/php/7.2/fpm/php.ini
COPY etc/php/www.conf  /etc/php/7.2/fpm/pool.d/www.conf
COPY etc/crontab /crontab

# Add runit services
COPY sv /etc/service 
ARG BUILD_INFO
LABEL BUILD_INFO=$BUILD_INFO

