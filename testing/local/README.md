# LiteLLM 本機測試指南

> LiteLLM proxy 迴歸測試與整合測試的本機測試指南
>
> 本目錄包含用於驗證 LiteLLM proxy 行為的自動化測試套件，用於在升級前建立基準線並在升級後驗證修復結果。

← [返回測試](/testing/README.md)

---

- **日期**：2026-02-27
- **用途**：LiteLLM proxy 迴歸測試與整合測試套件

## 概覽

本目錄包含自動化測試，用於驗證不同版本的 LiteLLM proxy 行為。在升級前建立基準線，並在升級後驗證修復結果。

## 快速開始

```bash
# 1. 設定環境
cp .env.example .env  # 填入您的 VERTEX_API_KEY

# 2. 啟動 LiteLLM proxy
cd litellm-v1.80.11 && source .venv/bin/activate
GEMINI_API_KEY=$VERTEX_API_KEY litellm --config ../config.yaml --port 4000

# 3. 執行測試（另開終端機）
uv run python test_regression.py --model gemini-2.5-flash
```

## 測試套件

### 1. 迴歸測試（`test_regression.py`）

涵蓋 proxy 核心功能的完整測試套件，共 28 項測試。

**測試覆蓋範圍**：

| 類別 | 測試項目 |
|------|---------|
| 健康檢查與監控 | `/health`、`/health/liveliness`、`/health/readiness` |
| 模型列表 | `GET /v1/models`、`GET /v1/model/info` |
| 對話補全 | 非串流、串流、使用量統計 |
| 工具呼叫 | 單一工具、多輪對話 |
| 錯誤處理 | 無效模型、無效認證 |
| 工具函式 | Token 計數、路由列表 |

**使用方式**：

```bash
# 預設（連接埠 4000，gemini-2.5-flash）
uv run python test_regression.py

# 自訂連接埠與模型
uv run python test_regression.py --port 4001 --model gemini-2.5-pro
```

**預期輸出**：

```
============================================================
  LiteLLM 迴歸測試基準線
  Proxy: http://localhost:4000
  Model: gemini-2.5-flash
============================================================

============================================================
  健康檢查與監控
============================================================
    GET /health 回傳 200
    健康檢查回報模型狀態良好
    ...

============================================================
  結果摘要
============================================================
  通過：28/28
  失敗：0/28

  整體結果：所有測試通過
```

### 2. Gemini 思考簽章測試（`test_gemini_signature.py`）

驗證多輪工具對話中 thought_signature 修復的整合測試。

**背景說明**：舊版本（v1.79.0）存在一個 bug，Gemini 思考模型在多輪工具呼叫時會回傳 400/503 錯誤。本測試驗證修復是否能正確保留思考簽章。

**測試流程**：

1. 傳送含工具定義的初始請求
2. 驗證工具呼叫 ID 是否包含 `__thought__` 簽章（如適用）
3. 以相同 ID 傳送工具結果
4. 驗證最終回應能正常完成，無錯誤

**使用方式**：

```bash
# 需要已設定 Gemini 模型的 proxy
uv run python test_gemini_signature.py --model gemini-2.5-flash
```

**判讀結果**：

| 結果 | 意義 |
|------|------|
| 通過 | 多輪對話成功完成 |
| 失敗（含 thought_signature 錯誤） | bug 仍存在 |
| ID 中無 `__thought__` | 模型可能未發出簽章（請確認 `enable_preview_features` 設定） |

## 設定

### 環境變數（`.env`）

```bash
VERTEX_API_KEY=your-vertex-api-key-here
```

### Proxy 設定（`config.yaml`）

```yaml
model_list:
  - model_name: gemini-2.5-flash
    litellm_params:
      model: gemini/gemini-2.5-flash
      api_key: os.environ/VERTEX_API_KEY

general_settings:
  master_key: sk-test-key-1234  # 與測試腳本中的 MASTER_KEY 一致

litellm_settings:
  enable_preview_features: true  # 思考簽章的必要設定
```

## 目錄結構

```
testing/local/
├── README.md                    # 本檔案
├── config.yaml                  # LiteLLM proxy 共用設定
├── .env                         # API 金鑰（已列入 gitignore）
├── test_regression.py           # 核心迴歸測試套件（28 項測試）
├── test_gemini_signature.py     # 思考簽章整合測試
├── test_performance.py         # 效能基準測試
├── results/                     # 測試結果報告
│   ├── integration-test.md
│   ├── v1.79.0-code-check.md
│   └── v1.80.11-code-check.md
├── litellm-v1.79.0/            # v1.79.0 原始碼（供比對）
├── litellm-v1.80.11/           # v1.80.11 原始碼（供比對）
└── litellm-v1.81.12/           # v1.81.12 原始碼（供比對）
```

## 測試工作流程

### 升級前基準線

```bash
# 1. 啟動當前版本（如 v1.79.0）
cd litellm-v1.79.0 && source .venv/bin/activate
litellm --config ../config.yaml --port 4000

# 2. 執行迴歸測試
uv run python test_regression.py > results/baseline-v1.79.0.txt

# 3. 停止 proxy，切換至新版本
# 4. 執行相同測試，比對結果
```

### 升級後驗證

```bash
# 1. 啟動新版本（如 v1.81.12）
cd litellm-v1.81.12 && source .venv/bin/activate
litellm --config ../config.yaml --port 4000

# 2. 執行迴歸測試
uv run python test_regression.py > results/regression-v1.81.12.txt

# 3. 執行簽章測試
uv run python test_gemini_signature.py > results/signature-v1.81.12.txt
```

### 功能專項測試

```bash
# 專門測試工具呼叫
uv run python test_regression.py --model gemini-2.5-flash 2>&1 | grep -A2 "Tool\|Multi-turn"

# 僅測試思考簽章修復
uv run python test_gemini_signature.py --model gemini-2.5-flash

# 執行效能基準測試
uv run python test_performance.py --model gemini-2.5-flash
```

## 故障排除

| 問題 | 解決方案 |
|------|---------|
| `ERROR: Cannot reach proxy` | 先在正確連接埠啟動 LiteLLM proxy |
| 模型不在列表中 | 確認 `VERTEX_API_KEY` 和 config.yaml 設定 |
| 工具呼叫失敗 | 確認模型支援函式呼叫 |
| thought_signature 錯誤 | 確認 config 中設定 `enable_preview_features: true` |
| 認證錯誤 | 確認 config 與測試腳本中的 `MASTER_KEY` 一致 |

## 參考資料

- [資料庫遷移指南](../../research/db-schema-migration-v1.79-to-v1.81.md)
- [升級計劃](../../reports/2-upgrade-plan.md)
- [使用 UV 進行 Python 開發](../../guides/python-setup.md)
