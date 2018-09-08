# Docker image definition file for postgres v10 with dvdrental database pre-installed

FROM postgres:10

WORKDIR /tmp

# Copy the script that installs and initializes the dvdrental database in the container when it starts up
# Note that any script copied to /docker-entrypoint-initdb.d/ is run in the container once postgres starts but before
#  the container is available and listening

COPY init-dvdrental.sh /docker-entrypoint-initdb.d/

RUN apt-get -qq update && \
  # install curl and zip (needed to download and unzip dvdrental)
  apt-get install -y -qq curl zip  > /dev/null 2>&1 && \
  # download the dvdrental database dump from the tutorial site
  curl -Os http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip && \
  # unzip the database dump and cleanup
  unzip dvdrental.zip && \
  rm dvdrental.zip && \
  # change ownership and permissions on the db dump file so we can use it
  chmod ugo+w dvdrental.tar && \
  chown postgres dvdrental.tar && \
  # change permissions on the initialization script so the container can execute it
  chmod u+x /docker-entrypoint-initdb.d/init-dvdrental.sh && \
  # clean up the ubuntu package db
  apt-get remove -y curl zip
