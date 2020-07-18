FROM solsson/kafka:graalvm@sha256:a49c81fcbeb96fa27eaa5b695d26b498ff466f116a5147047c78a085abd6f672 \
  as dev

ARG keycloak_version=967449f5c651cc8e18cc86e9420dc1432a7540f5

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

FROM solsson/kafka:2.5.0-jre as config

WORKDIR /opt/keycloak.x

COPY --from=dev /workspace/keycloak.x .

RUN ./bin/kc.sh config

RUN sed -i 's|exec |echo "Entrypoint would be:"; echo |' ./bin/kc.sh

# https://github.com/solsson/dockerfiles/tree/master/jre-nonroot
FROM adoptopenjdk:11.0.8_10-jre-hotspot-bionic@sha256:24864d2d79437f775c70fd368c0272a1579a45a81c965e5fdcf0de699c15a054

# Note that there's also a nouser 65534 user which has no writable home
RUN echo 'nonroot:x:65532:65534:nonroot:/home/nonroot:/usr/sbin/nologin' >> /etc/passwd && \
  mkdir -p /home/nonroot && touch /home/nonroot/.bash_history && chown -R 65532:65534 /home/nonroot
USER nonroot:nogroup

ENV HOME=/home/nonroot

WORKDIR /opt/keycloak.x

COPY --from=config /opt/keycloak.x .

ENTRYPOINT /opt/keycloak.x/bin/kc.sh
