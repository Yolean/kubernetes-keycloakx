FROM docker.io/yolean/builder-quarkus:2c6e176109a4cb1850cb7f8fa56411d370e3f705@sha256:9d309b1c352b1334eff63902216dc950a54eaf4433e985ed68ad9f5231750b48 \
  as dev

ARG keycloak_version=2ed8ed2543716e5d51acf2ef1c16c6ffd0f8d80b

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
    -Pdistribution \
    -pl org.keycloak:keycloak-server-spi,org.keycloak:keycloak-server-spi-private,org.keycloak:keycloak-quarkus-server-deployment,org.keycloak:keycloak-client-cli-dist \
    -am

# Instead of the above, use a local keycloak clone + mvn package, see also .dockerignore
#COPY keycloak/distribution/server-x-dist/target/*.gz keycloak/distribution/server-x-dist/target/

RUN sha256sum keycloak/distribution/server-x-dist/target/*.gz

RUN tar xvzf keycloak/distribution/server-x-dist/target/*.gz && mv keycloak.x-* keycloak.x

FROM adoptopenjdk:11.0.9_11-jre-hotspot-focal@sha256:f20df8e98a28a75b69f770be59b8431c2f878c29156fc8453fa0c5978857f3aa \
  as config

WORKDIR /opt/keycloak.x

COPY --from=dev /workspace/keycloak.x .

RUN ./bin/kc.sh config --help
# https://github.com/keycloak/keycloak-community/blob/master/design/keycloak.x/configuration.md#dynamic-properties
# > if the dynamic property is already set to the server image after running the config command, any attempt to override its value will be ignored

FROM adoptopenjdk:11.0.9_11-jre-hotspot-focal@sha256:f20df8e98a28a75b69f770be59b8431c2f878c29156fc8453fa0c5978857f3aa

ENV HOME=/home/nonroot

WORKDIR /opt/keycloak.x

COPY --from=config /opt/keycloak.x .

ENTRYPOINT /opt/keycloak.x/bin/kc.sh

ARG db=mariadb
ARG http_enabled=true
ARG proxy=edge
ARG metrics_enabled=true
ARG cluster=cluster
ARG cluster_stack=kubernetes

RUN ./bin/kc.sh config \
  --db=${db} \
  --http-enabled=${http_enabled} \
  --proxy=${proxy} \
  --metrics-enabled=${metrics_enabled} \
  --cluster=${cluster} \
  --cluster-stack=${cluster_stack}

RUN ./bin/kc.sh show-config

# RUN sed -i 's|exec |echo "Entrypoint would be:"; echo |' ./bin/kc.sh
