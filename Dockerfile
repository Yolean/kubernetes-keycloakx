FROM yolean/builder-quarkus:927c0c196729e8409062991eb62ec77b7223f375@sha256:91a3460de58d483cc37706a97c1323f2594217af3f31f16ec614d470a9e0c7a2 \
  as dev

ARG keycloak_version=68e2ac3692435879ccacfab02ccca6e8c83b2a75

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
    -Pquarkus,distribution

RUN sha256sum keycloak/distribution/server-x/target/*.gz

RUN tar xvzf keycloak/distribution/server-x/target/*.gz && mv keycloak.x-* keycloak.x

FROM solsson/kafka:jre@sha256:aa624f7861a994a9144daa0758dfba4ae7e2cb695af0b7036f246678765e71f7 \
  as config

WORKDIR /opt/keycloak.x

COPY --from=dev /workspace/keycloak.x .

RUN ./bin/kc.sh config

RUN sed -i 's|exec |echo "Entrypoint would be:"; echo |' ./bin/kc.sh

FROM solsson/kafka:jre-nonroot@sha256:7250ca3f0a9a71d324bda11dfe7f7659bda79d9bd53eb29f19a6cd6088d64e62

ENV HOME=/home/nonroot

WORKDIR /opt/keycloak.x

COPY --from=config /opt/keycloak.x .

ENTRYPOINT /opt/keycloak.x/bin/kc.sh
