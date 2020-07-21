FROM solsson/kafka:graalvm@sha256:28505c768b7f8b44168b9df5bc27dc4735d1be75ea5a12eb94c34af2d661e66a \
  as dev

ARG keycloak_version=316f9f46e2b542b09d67929a60922d981bb8fbd5

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

FROM solsson/kafka:jre@sha256:9374540e6643ac577056e900872793cc4a96687025e3b492e93ad8d10c8e429b \
  as config

WORKDIR /opt/keycloak.x

COPY --from=dev /workspace/keycloak.x .

RUN ./bin/kc.sh config

RUN sed -i 's|exec |echo "Entrypoint would be:"; echo |' ./bin/kc.sh

FROM solsson/kafka:jre-nonroot@sha256:3ac8303d503e2d72ccb8bc9b8fa5e3066eff998fe697094ad16479038e6ba47d

ENV HOME=/home/nonroot

WORKDIR /opt/keycloak.x

COPY --from=config /opt/keycloak.x .

ENTRYPOINT /opt/keycloak.x/bin/kc.sh
