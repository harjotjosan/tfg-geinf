FROM postgres:16

ENV POSTGRES_DB=carparts \
    POSTGRES_USER=carparts_user \
    POSTGRES_PASSWORD=carparts_pass

COPY init.sql /docker-entrypoint-initdb.d/01-init.sql
