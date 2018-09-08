FROM postgres:10

WORKDIR /tmp

COPY init-dvdrental.sh /docker-entrypoint-initdb.d/

RUN apt-get -qq update && apt-get install -y -qq curl zip  > /dev/null 2>&1 && \
  curl -Os http://www.postgresqltutorial.com/wp-content/uploads/2017/10/dvdrental.zip && \
  unzip dvdrental.zip && \
  rm dvdrental.zip && \
  chmod ugo+w dvdrental.tar && \
  chown postgres dvdrental.tar && \
  chmod u+x /docker-entrypoint-initdb.d/init-dvdrental.sh && \
  apt-get remove -y curl zip
