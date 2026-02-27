# LiteLLM PR 相容性報告

> PR 相容性矩陣，用於思考簽章修復

← [Back to Research](README.md)

---

- **日期**：2026-02-26
- **儲存庫**：[BerriAI/litellm](https://github.com/BerriAI/litellm)

---

## 摘要

本文件追蹤兩個 Gemini 思考簽章相關 PR 在 LiteLLM 穩定版本中的收錄狀況。

| PR | 標題 | 合併日期 | Commit |
|----|------|----------|--------|
| [#16895](https://github.com/BerriAI/litellm/pull/16895) | [stripe] gemini 3 thought signatures in tool call id | 2025-11-21 | `f9d8eeaf8e38173973b149d50acba10f102a2be6` |
| [#18374](https://github.com/BerriAI/litellm/pull/18374) | Add gemini thought signature support via tool call id | 2025-12-23 | `a57c4d0aa1926e802375f02ece1e873376cc4eb8` |

---

## 版本相容性矩陣

### 未收錄（合併前發布）

| 版本 | 發布日期 | PR #16895 | PR #18374 |
|------|----------|-----------|-----------|
| v1.79.1-stable | 2025-11-08 | ❌ | ❌ |
| v1.80.5-stable | 2025-12-03 | ❌ | ❌ |
| v1.80.8-stable | 2025-12-14 | ✅ | ❌ |

### 已收錄（兩個 PR 均合併後發布）

| 版本 | 發布日期 | PR #16895 | PR #18374 | 備註 |
|------|----------|-----------|-----------|------|
| **v1.80.11-stable** | 2026-01-10 | ✅ | ✅ | **最早同時包含兩者的穩定版** |
| v1.80.15-stable | 2026-01-17 | ✅ | ✅ | |
| v1.81.0-stable | 2026-01-24 | ✅ | ✅ | |
| v1.81.3-stable | 2026-02-08 | ✅ | ✅ | |
| v1.81.9-stable | 2026-02-15 | ✅ | ✅ | |
| **v1.81.12-stable.1** | 2026-02-24 | ✅ | ✅ | **最新穩定版** |

---

## 建議

### 最低必要版本

若要同時使用**兩個** PR 的功能，請升級至：

```
v1.80.11-stable
```

### 建議升級路徑

- **保守方案**：`v1.80.11-stable` — 最早同時包含兩項修復的穩定版
- **推薦方案**：`v1.81.12-stable.1` — 包含額外改進的最新穩定版

---

## 功能說明

### Gemini 思考簽章

兩個 PR 均透過工具呼叫 ID 實作 Gemini「思考」簽章支援：

- **PR #16895**：初始實作，包含 Stripe 整合考量
- **PR #18374**：擴展 Gemini 思考簽章支援

這些功能使 LiteLLM 能夠正確處理 Gemini 的推理／思考 token，這些 token 透過工具呼叫識別符暴露出來。

---

## 時間軸

```
2025-11-08  v1.79.1-stable 發布
2025-11-21  PR #16895 合併 ────────┐
2025-12-03  v1.80.5-stable 發布   │（不含 #16895）
2025-12-14  v1.80.8-stable 發布   │（含 #16895，不含 #18374）
2025-12-23  PR #18374 合併 ────────┤
                                    │
2026-01-10  v1.80.11-stable 發布 ◄──┘（首個同時包含兩者的穩定版）
```

---

## 參考資料

- [LiteLLM 版本發布](https://github.com/BerriAI/litellm/releases)
- [PR #16895 — 在 GitHub 上查看](https://github.com/BerriAI/litellm/pull/16895)
- [PR #18374 — 在 GitHub 上查看](https://github.com/BerriAI/litellm/pull/18374)
