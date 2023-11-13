apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: validator
spec:
  selector:
    matchLabels:
      app: evmos
  serviceName: "evmos"
  replicas: 1
  template:
    metadata:
      labels:
        app: evmos
    spec:
      #terminationGracePeriodSeconds: 10
      containers:
      # - name: bbsidecar
      #   image: busybox:1.28
      #   command: ['sh', '-c', 'chown -R 1000:1000 /home/evmos & sleep 3600']
      #   volumeMounts:
      #   - name: evmos-vol
      #     mountPath: /home/evmos
      - name: evmosnode
        securityContext:
          runAsUser: 1000
          runAsGroup: 1000
          fsGroup: 1000
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          privileged: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
        image: us-docker.pkg.dev/GOOGLE_CLOUD_PROJECT/evmos/evmosdtestnet:COMMIT_SHA
        resources:
          requests:
            memory: "20Gi"
            cpu: "2"
          limits:
            memory: "25Gi"
            cpu: "4"
        args: ["sh", "-c", "/usr/bin/testnet_node.sh -y -s & sleep 84000s"]  ## sleeps for troubleshooting
        ports:
        - containerPort: 26656
          name: p2p
        - containerPort: 26657
          name: tmtrpc
        - containerPort: 8545
          name: ethrpc
        - containerPort: 8546
          name: websocket
        - containerPort: 1317
          name: telemetry
        - containerPort: 26660
          name: promotheus
        volumeMounts:
        - name: evmos-vol
          mountPath: /home/evmos
  volumeClaimTemplates:
  - metadata:
      name: evmos-vol
      pv.beta.kubernetes.io/gid: "1000"
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 20Gi
      storageClassName: standard-rwo
