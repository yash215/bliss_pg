FROM openjdk:8-jre-alpine

RUN apk --no-cache add --update bash openssl
ADD https://github.com/remind101/ssm-env/releases/download/v0.0.2/ssm-env /usr/bin/ssm-env
RUN chmod +x /usr/bin/ssm-env

# Add the flyway user and step in the directory
RUN adduser -S -h /flyway -D flyway
WORKDIR /flyway

# Change to the flyway user
USER flyway

ENV FLYWAY_VERSION 5.1.1
#ENV FLYWAY_VERSION 6.0.0-beta

RUN wget https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}.tar.gz \
  && tar -xzf flyway-commandline-${FLYWAY_VERSION}.tar.gz \
  && mv flyway-${FLYWAY_VERSION}/* . \
  && rm flyway-commandline-${FLYWAY_VERSION}.tar.gz

RUN echo -e 'flyway.baselineOnMigrate=true\nflyway.baselineVersion=0' > /flyway/conf/flyway.conf

COPY postgresql-42.2.6.jar /flyway/drivers/postgresql-42.2.6.jar
#COPY migrations/SCHEMA /flyway/sql
#COPY migrations/ADMIN /flyway/sql
RUN mkdir -p /flyway/sql/ADMIN  /flyway/sql/SCHEMA  /flyway/sql/HK  /flyway/sql/SG  /flyway/sql/MY
COPY migrations/ADMIN/* /flyway/sql/ADMIN/
COPY migrations/HK/* /flyway/sql/HK/
COPY migrations/SG/* /flyway/sql/SG/
COPY migrations/MY/* /flyway/sql/MY/
COPY migrations/SCHEMA/* /flyway/sql/SCHEMA/
#COPY ojdbc8.jar /flyway/drivers/ojdbc8.jar
RUN ls -larth /flyway/sql
#COPY flyway /flyway/flyway

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/usr/bin/ssm-env", "-with-decryption", "sh", "/docker-entrypoint.sh"]
