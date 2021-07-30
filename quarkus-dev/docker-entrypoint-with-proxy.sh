#!/bin/bash
set -eou pipefail

echo "Starting envoy proxy in background ..."
exec /usr/local/bin/envoy --log-level info --config-yaml '
admin:
  address:
    socket_address:
      protocol: TCP
      address: 0.0.0.0
      port_value: 9901
static_resources:
  listeners:
  - name: listener_0
    address:
      socket_address:
        protocol: TCP
        address: 0.0.0.0
        port_value: 8080
    filter_chains:
    - filters:
      - name: envoy.filters.network.http_connection_manager
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
          stat_prefix: ingress_http
          access_log:
          - name: envoy.access_loggers.file
            filter:
              not_health_check_filter: {}
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
              path: "/dev/stdout"
              log_format:
                json_format:
                  start_time: "%START_TIME%"
                  req_method: "%REQ(:METHOD)%"
                  req_path: "%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%"
                  resp_code: "%RESPONSE_CODE%"
                  resp_flags: "%RESPONSE_FLAGS%"
                  bytes_recv: "%BYTES_RECEIVED%"
                  bytes_sent: "%BYTES_SENT%"
                  duration: "%DURATION%"
                  agent: "%REQ(USER-AGENT)%"
                  req_id: "%REQ(X-REQUEST-ID)%"
                  upstream_host: "%UPSTREAM_HOST%"
                  upstream_cluster: "%UPSTREAM_CLUSTER%"
                  resp_upstream_service_time: "%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%"
                  resp_redirect: "%RESP(LOCATION)%"
                  req_host: "%REQ(:AUTHORITY)%"
          route_config:
            name: local_route
            virtual_hosts:
            - name: local_service
              domains: ["*"]
              routes:
              - match:
                  path: "/auth"
                redirect:
                  path_redirect: "/admin"
              - match:
                  prefix: "/auth/realms"
                route:
                  prefix_rewrite: "/realms"
                  cluster: keycloak
              # - match:
              #     prefix: "/auth"
              #   route:
              #     prefix_rewrite: "/admin"
              #     cluster: keycloak
              # - match:
              #     prefix: "/realms"
              #   route:
              #     prefix_rewrite: "/admin"
              #     cluster: keycloak
              - match:
                  prefix: "/"
                route:
                  cluster: keycloak
          http_filters:
          - name: envoy.filters.http.router
  clusters:
  - name: keycloak
    connect_timeout: 30s
    type: LOGICAL_DNS
    dns_lookup_family: V4_ONLY
    lb_policy: ROUND_ROBIN
    load_assignment:
      cluster_name: keycloak
      endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: 127.0.0.1
                port_value: 8081
' >/tmp/envoy.log 2>/tmp/envoy.log &
echo "Starting keycloak ..."
exec /opt/jboss/tools/docker-entrypoint.sh $@ --http-port=8081
