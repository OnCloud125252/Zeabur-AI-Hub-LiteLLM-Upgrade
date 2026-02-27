# Kubernetes 部署指南

> Phase 4h - Kubernetes deployment guide for LiteLLM upgrade

← [Back to Reports](README.md)

---

- **日期**：2026-02-28
- **階段**：Phase 4 Delivery
- **用途**：Kubernetes 環境的 ConfigMap 和 Secret 管理
- **升級路徑**：v1.79.0-stable → v1.81.12-stable.1
- **狀態**：完成

---

## ConfigMap 管理

### 版本化 ConfigMap

建議使用帶版本號的 ConfigMap 名稱，避免新舊版本衝突：

```yaml
# configmap-v1.79.0.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: litellm-config-v1-79-0
data:
  config.yaml: |
    # v1.79.0 設定內容

---
# configmap-v1.81.12.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: litellm-config-v1-81-12
data:
  config.yaml: |
    # v1.81.12 設定內容
```

### Deployment 參考

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: litellm
spec:
  template:
    spec:
      containers:
      - name: litellm
        image: docker.litellm.ai/berriai/litellm:v1.81.12-stable.1
        volumeMounts:
        - name: config
          mountPath: /app/config.yaml
          subPath: config.yaml
      volumes:
      - name: config
        configMap:
          name: litellm-config-v1-81-12  # 升級時修改此行
```

## Secret 管理

### 環境變數來源

```yaml
env:
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: litellm-secrets
      key: database-url
- name: LITELLM_MASTER_KEY
  valueFrom:
    secretKeyRef:
      name: litellm-secrets
      key: master-key
```

### 使用 Helm 管理

如有使用 Helm，建議使用 values.yaml 區分環境：

```yaml
# values-production.yaml
image:
  repository: docker.litellm.ai/berriai/litellm
  tag: v1.81.12-stable.1

config:
  enable_preview_features: true
  database_connection_pool_limit: 50
```

---

## References

- 升級步驟：[4d-upgrade-steps.md](4d-upgrade-steps.md)
- 設定對照：[4c-config-comparison.md](4c-config-comparison.md)
