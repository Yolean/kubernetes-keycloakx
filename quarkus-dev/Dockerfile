FROM envoyproxy/envoy:v1.19.0 as envoy

FROM quay.io/keycloak/keycloak-x:15.0.0

CMD ["start-dev"]
ENV KEYCLOAK_ADMIN=admin KEYCLOAK_ADMIN_PASSWORD=admin

COPY --from=envoy /usr/local/bin/envoy /usr/local/bin/envoy
COPY docker-entrypoint-with-proxy.sh /opt/jboss/tools/docker-entrypoint-with-proxy.sh
ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint-with-proxy.sh" ]
