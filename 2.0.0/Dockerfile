# docker build -t conjecto/blazegraph:2.0.0 .
FROM openjdk:8-alpine
LABEL maintainer="Conjecto <contact@conjecto.com>"
ENV BLAZEGRAPH_HOME=/var/lib/blazegraph

RUN apk update && apk add --no-cache bash

# install blazegraph
ADD https://github.com/blazegraph/database/releases/download/BLAZEGRAPH_RELEASE_2_0_0/blazegraph.jar /usr/bin/blazegraph.jar
RUN mkdir $BLAZEGRAPH_HOME

# Config files
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 9999
VOLUME $BLAZEGRAPH_HOME

WORKDIR $BLAZEGRAPH_HOME
CMD ["blazegraph"]