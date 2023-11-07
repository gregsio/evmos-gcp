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
      - name: evmosnode
        securityContext:
          fsGroup: 0
          runAsUser: 0
          runAsGroup: 0
          allowPrivilegeEscalation: true
          capabilities:
            drop:
            - ALL
          privileged: true
          readOnlyRootFilesystem: false # to be changed in prod
          runAsNonRoot: false
        image: us-docker.pkg.dev/GOOGLE_CLOUD_PROJECT/evmos/evmosdtestnet:COMMIT_SHA
        resources:
          requests:
            memory: "20Gi"
            cpu: "2"
          limits:
            memory: "25Gi"
            cpu: "4"
        args: ["sh", "-c", "/usr/bin/testnet_node.sh -y & sleep 84000s"]
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
        volumeMounts:
        - name: evmos-vol
          mountPath: /evmos
  volumeClaimTemplates:
  - metadata:
      name: evmos-vol
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 20Gi