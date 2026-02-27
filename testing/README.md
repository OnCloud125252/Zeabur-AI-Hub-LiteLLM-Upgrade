# 測試

> LiteLLM 升級的測試文件與環境

← [返回文件首頁](../README.md)

---

## 測試環境

| 環境 | 用途 | 文件 |
|------|------|------|
| [本地](local/) | 本地開發與測試 | [local/README.md](local/README.md) |
| [遠端](remote/) | 遠端 Docker 部署測試 | [remote/README.md](remote/README.md) |

---

## 測試類型

### 迴歸測試 (`test_regression.py`)

- **位置**: `local/test_regression.py`
- **用途**: 驗證跨版本的核心代理功能
- **覆蓋範圍**: 28 項測試，涵蓋健康檢查、模型列表、聊天完成、工具呼叫
- **用法**: `uv run python test_regression.py --model gemini-2.5-flash`

### Gemini 簽章測試 (`test_gemini_signature.py`)

- **位置**: `local/test_gemini_signature.py`
- **用途**: 驗證多輪工具對話中的 thought_signature 修復
- **用法**: `uv run python test_gemini_signature.py --model gemini-2.5-flash`

### 效能測試 (`test_performance.py`)

- **位置**: `local/test_performance.py`
- **用途**: 延遲與吞吐量基準測試
- **用法**: `uv run python test_performance.py --model gemini-2.5-flash`

---

## 測試結果

機器產生的測試輸出儲存於 [`../test-outputs/`](../test-outputs/)：

| 檔案 | 說明 |
|------|------|
| `baseline-v1.79.0.txt` | v1.79.0 基準迴歸結果 |
| `regression-v1.81.12.txt` | v1.81.12 升級後迴歸測試 |
| `rollback-v1.79.0.txt` | 回滾驗證結果 |
| `signature-v1.79.0.txt` | v1.79.0 簽章測試（基準） |
| `signature-v1.81.12.txt` | v1.81.12 簽章測試（驗證） |
| `perf-v1.79.0.json` | v1.79.0 效能指標 |
| `perf-v1.81.12.json` | v1.81.12 效能指標 |

---

## 快速開始

### 本地測試

```bash
cd testing/local

# 設定
cp .env.example .env  # 加入您的 VERTEX_API_KEY

# 啟動代理
cd litellm-v1.79.0 && source .venv/bin/activate
GEMINI_API_KEY=$VERTEX_API_KEY litellm --config ../config.yaml --port 4000

# 執行測試（在另一個終端機）
uv run python test_regression.py
```

### 遠端測試

```bash
cd testing/remote

# 部署
docker compose -f docker-compose.v1.81.12.yml up -d

# 驗證
docker compose ps
```

詳細說明請參閱 [remote/README.md](remote/README.md)。

---

*完整的文件導覽請參閱 [SUMMARY.md](../SUMMARY.md)。*
