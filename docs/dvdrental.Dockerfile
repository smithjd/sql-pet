# Docker image definition file for postgres v10 with dvdrental database pre-installed
#
# See: https://docs.docker.com/engine/reference/builder/
# Notation: ' \' means "continue on next line""; ' && ' means "also do the next step"

# Base image is Postgres v10
FROM postgres:10

WORKDIR /tmp

# Copy the script that installs and initializes the dvdrental database in the
#   container when it starts up.
#
# Note that any script copied to /docker-entrypoint-initdb.d/ is run in the
#   container once postgres starts but before the container is available
#   and listening.

COPY init-dvdrental.sh /docker-entrypoint-initdb.d/

# RUN frequently starts by updating apt-get installer.
RUN apt-get -qq update && \
  # Install curl and zip (needed to download and unzip dvdrental).
  apt-get install -y -qq curl zip  > /dev/null 2>&1 && \
  # Download the dvdrental database dump from the tutorial site.
  curl -Os http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip && \
  # Unzip the database dump and remove the zip file.
  unzip dvdrental.zip && \
  rm dvdrental.zip && \
  # Change ownership and permissions on the db dump file so we can use it.
  chmod ugo+w dvdrental.tar && \
  chown postgres dvdrental.tar && \
  # Change permissions on the initialization script so the container can execute it.
  chmod u+x /docker-entrypoint-initdb.d/init-dvdrental.sh && \
  # Remove the packages that have been installed.
  apt-get remove -y curl zip
