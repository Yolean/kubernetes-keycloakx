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

FROM solsson/kafka:jre@sha256:cf733bd15bd9e5037573433e976a4454ba48bf19838c158f4d764971d1e2b719 \
  as config

WORKDIR /opt/keycloak.x

COPY --from=dev /workspace/keycloak.x .

RUN ./bin/kc.sh config

RUN sed -i 's|exec |echo "Entrypoint would be:"; echo |' ./bin/kc.sh

FROM solsson/kafka:jre-nonroot@sha256:c33c6170438e047f4cfe18801baffb28bddd7b8ac7d73ab69037ae99f9a81271

ENV HOME=/home/nonroot

WORKDIR /opt/keycloak.x

COPY --from=config /opt/keycloak.x .

ENTRYPOINT /opt/keycloak.x/bin/kc.sh
