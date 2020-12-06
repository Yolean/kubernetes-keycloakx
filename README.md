# Keycloak.X on Kubernetes


- https://issues.redhat.com/issues/?jql=project+%3D+KEYCLOAK+AND+component+%3D+%22Distribution+-+Quarkus%22
- https://issues.redhat.com/issues/?jql=project+%3D+KEYCLOAK+AND+fixVersion+%3D+12.0.0
- https://github.com/keycloak/keycloak-web/commits/1d0c4c427b3c617fae382dbe129088c1652a7f6d/blog/2020/first-keycloak-x-release.adoc
- https://github.com/keycloak/keycloak-community/blob/master/design/keycloak.x/configuration.md
- https://github.com/keycloak/keycloak-operator

### Configuration, JGroups

Current default startup:

```
2020-07-18 03:27:02,330 INFO  [org.inf.fac.GlobalComponentRegistry] (main) ISPN000128: Infinispan version: Infinispan 'Infinity Minus ONE +2' 9.4.18.Final
2020-07-18 03:27:02,536 INFO  [org.inf.rem.tra.jgr.JGroupsTransport] (main) ISPN000078: Starting JGroups channel ISPN
2020-07-18 03:27:02,536 INFO  [org.inf.rem.tra.jgr.JGroupsTransport] (main) ISPN000088: Unable to use any JGroups configuration mechanisms provided in properties {}. Using default JGroups configuration!
```

Status:
- https://github.com/infinispan/infinispan/blob/master/core/src/main/resources/default-configs/default-jgroups-tcp.xml
- https://github.com/keycloak/keycloak/blob/f15821fe69c4f7e9c22c63dd7191c69e77702b58/quarkus/runtime/src/main/java/org/keycloak/provider/quarkus/QuarkusCacheManagerProvider.java#L48
- https://infinispan.org/docs/9.4.x/server_guide/server_guide.html
- https://infinispan.org/docs/9.4.x/server_guide/server_guide.html#server_config_jgroups
- https://github.com/keycloak/keycloak/commit/1db1deb0668b01eafa5dd03b222f51699be48008
- https://github.com/keycloak/keycloak/commit/b04932ede56993d36de70768c41d4c946c4c79e0#diff-d6997f5a4578cd9576ae6f1fdb5739db
- https://github.com/keycloak/keycloak/tree/master/quarkus/runtime/src/main/resources
- https://github.com/keycloak/keycloak/blob/master/quarkus/server/src/main/resources/META-INF/keycloak.properties

### Development

As soon as you have SPIs the dev loop, including docker build, will matter

```
export KUBECONFIG=$(pwd)/kubeconfig
k3d cluster create
skaffold run
```

### Testing the image (WIP)

```
docker build -t keycloakx .
docker run --rm --entrypoint java keycloakx -Dquarkus.datasource.url='jdbc:h2:file:/home/nonroot/data/keycloakdb;;AUTO_SERVER=TRUE' <args from docker run --rm keycloakx>
```
