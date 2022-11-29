FROM ubuntu:22.04

LABEL maintainer='Aytuğ HAN <me@aytughan.com>'

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

ENV RENV_PATHS_CACHE /renv_cache
ENV RENV_PATHS_PREFIX_AUTO true

# Install Git, Basic SSH Server and Dependencies for Rhino
RUN apt update && \
    apt install -y \
    git \
    openssh-server \
    gpg \
    make \
    libicu-dev \
    pandoc \
    libxml2-dev \
    libnss3-dev \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    libasound2 \
    zlib1g-dev \
    build-essential \
    nodejs \
    default-jdk \
    npm 

RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | gpg --dearmor -o /usr/share/keyrings/r-project.gpg && \
    echo 'deb [signed-by=/usr/share/keyrings/r-project.gpg] https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/' | tee -a /etc/apt/sources.list.d/r-project.list

RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && \
    # Add user jenkins to the image
    adduser --quiet jenkins && \
    # Set password for the jenkins user
    echo 'jenkins:jenkins' | chpasswd

# Copy Authorized Keys
COPY .ssh/authorized_keys /home/jenkins/.ssh/authorized_keys

# Set .ssh folder ownership to jenkins user
RUN chown -R jenkins:jenkins /home/jenkins/.ssh/

# Install R-base 
RUN apt update && \
    apt install --no-install-recommends -y \
    r-base 

WORKDIR /home/jenkins/
COPY renv.lock .

# Install Renv
RUN R -e 'install.packages("renv")'

# Restore all renv packages
RUN R -e 'renv::restore()'

# Cleanup Packages
RUN apt autoremove

# Standard SSH port
EXPOSE 22

CMD ['/usr/sbin/sshd', '-D']
