FROM openjdk:8-jre

# Add the flyway user and step in the directory
RUN adduser --system --home /flyway --disabled-password --group flyway
WORKDIR /flyway

# Change to the flyway user
USER flyway

ENV FLYWAY_VERSION 6.0.0-beta

RUN curl -L https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}.tar.gz -o flyway-commandline-${FLYWAY_VERSION}.tar.gz \
  && tar -xzf flyway-commandline-${FLYWAY_VERSION}.tar.gz --strip-components=1 \
  && rm flyway-commandline-${FLYWAY_VERSION}.tar.gz

COPY  migrations/ /flyway/sql/
RUN ls -lart /flyway/sql

COPY flyway /flyway/flyway
#COPY postgresql-42.2.5.jar /flyway/drivers/postgresql-42.2.5.jar
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["sh","/docker-entrypoint.sh"]

#COPY conf/*  /flyway/conf
CMD ["-?"]
