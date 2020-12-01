FROM yolean/builder-quarkus:927c0c196729e8409062991eb62ec77b7223f375@sha256:91a3460de58d483cc37706a97c1323f2594217af3f31f16ec614d470a9e0c7a2 \
  as dev

ARG keycloak_version=833bf9864356abe6f2c9f672edf1438b8635f48c

WORKDIR /workspace

RUN curl -sLS -o keycloak.tgz https://github.com/keycloak/keycloak/archive/$keycloak_version.tar.gz

RUN tar xzf keycloak.tgz && mv keycloak-$keycloak_version keycloak

# https://github.com/keycloak/keycloak/tree/master/quarkus#building-the-distribution
RUN cd keycloak/quarkus && \
  mvn --batch-mode -f ../pom.xml \
    clean install \
    -DskipTestsuite \
    -DskipExamples \
    -DskipTests \
    -Pdistribution

# Instead of the above, use a local keycloak clone + mvn package, see also .dockerignore
#COPY keycloak/distribution/server-x-dist/target/*.gz keycloak/distribution/server-x-dist/target/

RUN sha256sum keycloak/distribution/server-x-dist/target/*.gz

RUN tar xvzf keycloak/distribution/server-x-dist/target/*.gz && mv keycloak.x-* keycloak.x

FROM solsson/kafka:jre@sha256:a4626ab57cb4d4fcfca7faa097210a96561ef31765e8f0db6b6d259eef2a5628 \
  as config

WORKDIR /opt/keycloak.x

COPY --from=dev /workspace/keycloak.x .

ARG db=mariadb
ARG db_host=mysql:3306
ARG db_database=keycloak
ARG db_username=keycloak
ARG db_password=keycloak
ARG db_properties="characterEncoding=UTF-8"
ARG db_orm_dialect="org.hibernate.dialect.MariaDB102Dialect"

ARG http_enabled=true
# Or maybe =passthrough
ARG proxy=edge

ARG metrics_enabled=true

ARG cluster=cluster
ARG cluster_stack=kubernetes

RUN ./bin/kc.sh config --help
RUN ./bin/kc.sh config \
  --db=${db} \
  --db-username=${db_username} \
  --db-password=${db_password} \
  --http-enabled=${http_enabled} \
  --proxy=${proxy} \
  --metrics-enabled=${metrics_enabled} \
  --cluster=${cluster} \
  --cluster-stack=${cluster_stack} \
  # \
  # --datasource-driver=${db} \
  # --datasource-url=jdbc:${db}://${db_host}/${db_database}?${db_properties} \
  # --hibernate-orm-dialect=${db_orm_dialect} \
  # --datasource-db-kind=${db} \
  \
  -Dkc.db.url.host=${db_host} \
  -Dkc.db.url.database=${db_database} \
  -Dkc.db.url.properties=${db_properties}

RUN ./bin/kc.sh show-config

# RUN sed -i 's|exec |echo "Entrypoint would be:"; echo |' ./bin/kc.sh

FROM solsson/kafka:jre-nonroot@sha256:a03ccf56b18291c3676320d2040bf9942c4260f441d71ee9fa4703a7cdd4f28b

ENV HOME=/home/nonroot

WORKDIR /opt/keycloak.x

COPY --from=config /opt/keycloak.x .

ENTRYPOINT /opt/keycloak.x/bin/kc.sh
