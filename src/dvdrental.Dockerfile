FROM postgres:9.4

WORKDIR /tmp

RUN apt-get -qq update && \
  apt-get install -y -qq curl zip  > /dev/null 2>&1 && \
  curl -Os http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip && \
  unzip dvdrental.zip && \
  rm dvdrental.zip && \
  chmod ugo+w dvdrental.tar && \
  chown postgres dvdrental.tar && \
  echo '#!/bin/bash' > /docker-entrypoint-initdb.d/dvdrental.sh && \
  echo 'psql -U postgres -c "CREATE DATABASE dvdrental;"' >> /docker-entrypoint-initdb.d/dvdrental.sh && \
  echo 'pg_restore -v -U postgres -d dvdrental /tmp/dvdrental.tar' >> /docker-entrypoint-initdb.d/dvdrental.sh && \
  echo 'rm -f /tmp/dvdrental.tar' >> /docker-entrypoint-initdb.d/dvdrental.sh && \
  chmod u+x /docker-entrypoint-initdb.d/dvdrental.sh && \
  apt-get remove -y curl zip
