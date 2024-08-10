ARG PGVERSION=16
ARG VERSION=v2.1-16

FROM registry.cn-hangzhou.aliyuncs.com/ym01/pg_auto_failover:$VERSION as build

ARG PGVERSION
ARG VERSION

USER root

COPY extension/pgvector-0.5.1.tar.gz /tmp/
COPY extension/pg_partman-5.0.1.tar.gz /tmp/
COPY extension/pg_embedding-0.3.6.tar.gz /tmp/
COPY extension/postgresql_anonymizer-1.3.2.tar.gz /tmp/

# RUN set -e;
# RUN install_packages ca-certificates curl libbsd0 libbz2-1.0 libedit2 libffi8 libgcc-s1 libgmp10 libgnutls30 libhogweed6 libicu72 libidn2-0 libldap-2.5-0 liblz4-1 liblzma5 libmd0 libnettle8 libp11-kit0 libpcre3 libreadline8 libsasl2-2 libsqlite3-0 libssl3 libstdc++6 libtasn1-6 libtinfo6 libunistring2 libuuid1 libxml2 libxslt1.1 libzstd1 locales procps zlib1g

RUN apt-get update;
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \ 
    build-essential ;

# pgvector
RUN cd /tmp/; \
    tar -zxvf pgvector-0.5.1.tar.gz; \
    cd pgvector-0.5.1 ; \
    make OPTFLAGS="" ; \
    make install ; 

# pgembedding can't coexist with pgvector
# RUN cd /tmp/; \
#     tar -zxvf pg_embedding-0.3.6.tar.gz; \
#     cd pg_embedding-0.3.6 ; \
#     make ; \
#     make install ; \
#     ls -ahl;

# pg_partman
RUN cd /tmp/; \
    tar -zxvf pg_partman-5.0.1.tar.gz; \
    cd pg_partman-5.0.1 ; \
    make OPTFLAGS="" ; \
    make NO_BGW=1 install ; 

# Anonymizer
# https://postgresql-anonymizer.readthedocs.io/en/stable/INSTALL/#install-from-source
RUN cd /tmp/; \
    tar -zxvf postgresql_anonymizer-1.3.2.tar.gz; \
    cd postgresql_anonymizer-1.3.2 ; \
    make extension ; \
    make install ; 


FROM registry.cn-hangzhou.aliyuncs.com/ym01/pg_auto_failover:$VERSION

ARG PGVERSION

# copy pgvector
COPY --from=build /usr/lib/postgresql/${PGVERSION}/lib/vector*.so /usr/lib/postgresql/${PGVERSION}/lib
COPY --from=build /usr/share/postgresql/${PGVERSION}/extension/vector* /usr/share/postgresql/${PGVERSION}/extension/


# copy pg_embedding
# COPY --from=build /opt/bitnami/postgresql/lib/ /opt/bitnami/postgresql/lib/
# COPY --from=build /opt/bitnami/postgresql/share/ /opt/bitnami/postgresql/share/

# copy pg_partman
COPY --from=build /usr/lib/postgresql/${PGVERSION}/lib/pg_partman*.so /usr/lib/postgresql/${PGVERSION}/lib
COPY --from=build /usr/share/postgresql/${PGVERSION}/extension/pg_partman* /usr/share/postgresql/${PGVERSION}/extension/


# anno
COPY --from=build /usr/lib/postgresql/${PGVERSION}/lib/anon*.so /usr/lib/postgresql/${PGVERSION}/lib
COPY --from=build /usr/share/postgresql/${PGVERSION}/extension/anon* /usr/share/postgresql/${PGVERSION}/extension/


# for inspecting
#COPY --from=build /opt/bitnami/postgresql/lib/ /tmp/lib/
#COPY --from=build /opt/bitnami/postgresql/share/ /tmp/share/
#COPY --from=build /opt/bitnami/postgresql/bin/ /tmp/bin/
