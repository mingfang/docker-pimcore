# docker-pimcore
Run Pimcore Inside Docker

sample deploy
```
    services:
    - name: pimcore
      ports:
      - {name: http, port: 80}
      annotations:
        nginx:
        - http:
          - server: pimcore.*
            paths:
            - path: /
      stateful: true
      pod:
        replicas: 1
        containers:
        - name: pimcore
          image: registry.rebelsoft.com/pimcore
          env:
          - {name: PIMCORE_INSTALL_ADMIN_USERNAME, value: "admin"}
          - {name: PIMCORE_INSTALL_ADMIN_PASSWORD, value: "admin"}
          - {name: PIMCORE_INSTALL_MYSQL_HOST_SOCKET, value: "pimcore-db"}
          - {name: PIMCORE_INSTALL_MYSQL_USERNAME, value: "pimcore"}
          - {name: PIMCORE_INSTALL_MYSQL_PASSWORD, value: "pimcore"}
          - {name: PIMCORE_INSTALL_MYSQL_DATABASE, value: "pimcore"}
          - {name: PIMCORE_INSTALL_MYSQL_PORT, value: "3306"}
          - {name: POD_NAME, valueFrom: {fieldRef: {fieldPath: metadata.name}}}
          lifecycle:
            postStart:
              exec:
                command:
                - bash
                - -ce
                - |
                  until curl -s -o /dev/null localhost/; do echo "Waiting for Nginx..."; sleep 10; done;
                  if [ -e /var/www/pimcore/var/config/system.php ]; then
                    echo "/var/www/pimcore/var/config/system.php was found...skipping installation"
                    exit
                  fi
                  cd /var/www/pimcore
                  ./vendor/bin/pimcore-install --no-interaction
                  chown -R www-data:www-data /var/www
          volumeMounts:
          - {name: data, mountPath: /var/www/pimcore/var, subPath: pimcore/data/var}
          - {name: data, mountPath: /var/www/pimcore/web/var, subPath: pimcore/data/web/var}
        volumes:
        - {name: data, persistentVolumeClaim: {claimName: cluster-data}}

```
