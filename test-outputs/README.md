# 測試輸出

> 機器生成的測試結果封存檔
>
> 本目錄收錄 LiteLLM 升級驗證過程中產出的測試輸出，包括迴歸測試、簽名測試和效能基準測試的結果。

← [返回文件首頁](/README.md)

---

## 測試結果

此目錄包含 LiteLLM 升級驗證過程中機器生成的測試輸出。

### 迴歸測試

| 檔案 | 版本 | 結果 | 說明 |
|------|------|------|------|
| `baseline-v1.79.0.txt` | v1.79.0 | 28/28 通過 | 基準迴歸結果 |
| `regression-v1.81.12.txt` | v1.81.12 | 28/28 通過 | 升級後迴歸測試 |
| `rollback-v1.79.0.txt` | v1.79.0 | 28/28 通過 | 回滾驗證 |

### Gemini 簽名測試

| 檔案 | 版本 | 結果 | 說明 |
|------|------|------|------|
| `signature-v1.79.0.txt` | v1.79.0 | 存在錯誤 | 基準測試（bug 重現） |
| `signature-v1.81.12.txt` | v1.81.12 | 通過 | 修復驗證 |

### 效能基準測試

| 檔案 | 版本 | 說明 |
|------|------|------|
| `perf-v1.79.0.json` | v1.79.0 | 效能基準 |
| `perf-v1.81.12.json` | v1.81.12 | 升級後效能 |

---

## 測試覆蓋範圍

### 迴歸測試（28 項測試）

| 類別 | 測試項目 |
|------|----------|
| 健康狀態與監控 | `/health`、`/health/liveliness`、`/health/readiness` |
| 模型列表 | `GET /v1/models`、`GET /v1/model/info` |
| 聊天補全 | 非串流、串流、使用統計 |
| 工具呼叫 | 單一工具、多輪對話 |
| 錯誤處理 | 無效模型、無效認證 |
| 工具函數 | Token 計數、路由列表 |

### Gemini 簽名測試

驗證多輪工具對話的 `thought_signature` 修復：

1. 初始請求包含工具定義
2. 驗證工具呼叫 ID 包含 `__thought__` 簽名（如適用）
3. 使用相同 ID 發送工具結果
4. 驗證最終回應無錯誤完成

### 效能基準測試

5 項基準測試 × 每項 10 輪：

| 測試項目 | 說明 |
|----------|------|
| 簡單聊天補全（非串流） | 基礎對話功能 |
| 簡單聊天補全（串流） | 即時串流回應 |
| 工具呼叫 | 函式呼叫能力 |
| 多輪對話 | 上下文維持 |
| Token 計數 | 準確度驗證 |

---

## 生成方式

### 迴歸測試

```bash
cd testing/local
uv run python test_regression.py --model gemini-2.5-flash > ../../test-outputs/baseline-v1.79.0.txt
```

### 簽名測試

```bash
cd testing/local
uv run python test_gemini_signature.py --model gemini-2.5-flash > ../../test-outputs/signature-v1.81.12.txt
```

### 效能測試

```bash
cd testing/local
uv run python test_performance.py --model gemini-2.5-flash
# 結果儲存至 results/ 目錄，複製到 test-outputs/
```

---

## 驗證摘要

| 指標 | 結果 |
|------|------|
| 迴歸測試 | 28/28 × 3 個版本通過 |
| thought_signature 修復 | ✅ 於 v1.81.12 驗證通過 |
| 效能影響 | 在 ±5% 範圍內（無效能衰退） |

完整分析請參閱 [reports/4g-test-report.md](../reports/4g-test-report.md)。

---

*完整文件導覽請參閱 [SUMMARY.md](../SUMMARY.md)。*
