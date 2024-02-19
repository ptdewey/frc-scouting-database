# Base image
FROM rocker/tidyverse:latest

WORKDIR /stats-app

# Copy R libraries file
COPY requirements.R /requirements.R

RUN mkdir -p /output

# Install additional required R libraries
RUN Rscript /requirements.R

# install necessary packages
RUN  sudo apt-get update && sudo apt-get install -y \
    supervisor \
    cron \
    curl

# Copy all files to working directory
COPY . .
RUN chmod +x /stats-app/main.R

# Create cron job
COPY event-stats-job /etc/cron.d/event-stats-job
RUN chmod 0644 /etc/cron.d/event-stats-job
RUN crontab /etc/cron.d/event-stats-job

# launch into supervisord
ENTRYPOINT [ "/usr/bin/supervisord" ]
