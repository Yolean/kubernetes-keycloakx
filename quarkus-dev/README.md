# Keycloak.x for Quarkus dev mode

The initial [DevServices support for Keycloak](https://github.com/quarkusio/quarkus/pull/17364) uses the default Keycloak distribution,
instead of the leaner Keycloak.x ["Preview"](https://www.keycloak.org/downloads).

While Quarkus dev depends on [hard coded](https://github.com/quarkusio/quarkus/blob/2.1.0.Final/extensions/oidc/deployment/src/main/java/io/quarkus/oidc/deployment/devservices/keycloak/KeycloakDevServicesProcessor.java#L169) [paths](https://github.com/quarkusio/quarkus/blob/2.1.0.Final/extensions/oidc/deployment/src/main/java/io/quarkus/oidc/deployment/devservices/keycloak/KeycloakDevServicesProcessor.java#L342)
this image includes a proxy so that Keycloak.x can be used instead.

In your `application.properties` use our prebuilt image or your local build like so:

```
quarkus.keycloak.devservices.image-name=yolean/keycloakx:dev-quarkus
```

The differences between the [default](https://quay.io/quay.io/keycloak/keycloak) keycloak image and [keycloak-x](quay.io/keycloak/keycloak-x) are captured in our
[envoy proxy path rewrites](./docker-entrypoint-with-proxy.sh#L60).

Access logs are available using `docker exec [container name from docker ps] tail -f /tmp/envoy.log`.

In Kubernetes the proxy can run more elegantly as a sidecar.
