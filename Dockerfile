FROM postgres:13.1

LABEL BioHubBC Postgres

# set variables
ENV POSTGISV 3
ENV TZ America/Vancouver
ENV PORT 5432

ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    PGUSER=postgres \
    POSTGRES_USER=postgres

COPY fix-permissions /usr/libexec/fix-permissions

RUN adduser 26

ARG PGHOME=/var/lib/postgresql

RUN export DEBIAN_FRONTEND=noninteractive \
    && set -x 
RUN mkdir -p /opt/apps
RUN apt-get -qq update -y
RUN apt-get -qq install -y --no-install-recommends git build-essential
RUN apt-get -qq install -y --no-install-recommends postgresql-$PG_MAJOR-postgis-$POSTGISV
RUN apt-get -qq install -y --no-install-recommends postgresql-$PG_MAJOR-postgis-$POSTGISV-scripts
RUN apt-get -qq install -y --no-install-recommends postgresql-$PG_MAJOR-pgrouting
RUN apt-get -qq install -y --no-install-recommends postgresql-$PG_MAJOR-pgrouting-scripts
RUN apt-get -qq install -y --no-install-recommends postgresql-server-dev-$PG_MAJOR
RUN apt-get -qq install -y --no-install-recommends pgbadger pg-activity
RUN apt-get -qq purge -y --auto-remove postgresql-server-dev-$PG_MAJOR
RUN apt-get -qq autoremove -y
RUN apt-get -qq clean

# set time zone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN echo 'Make sure we have a en_US.UTF-8 locale available' \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN test "$(id postgres)" = "uid=26(postgres) gid=26(postgres) groups=26(postgres)"
RUN /usr/libexec/fix-permissions /var/lib/postgresql
RUN /usr/libexec/fix-permissions /var/run/postgresql

RUN echo 'Cleaning up' \
    && apt-get remove -y git build-essential \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /root/.cache

COPY contrib/root /
# copy postgis init script to docker init directory
RUN mkdir -p /docker-entrypoint-initdb.d
COPY create_postgis.sql /docker-entrypoint-initdb.d/postgis.sql

VOLUME ["/var/lib/postgresql/data", "/var/run/postgresql"]
USER 26

EXPOSE ${PORT}

CMD ["postgres"]

