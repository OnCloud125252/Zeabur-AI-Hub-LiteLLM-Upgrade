# 指南

> LiteLLM 升級專案的 AI Agent 操作指南

← [返回文件首頁](../README.md)

---

## 可用指南

| 指南 | 說明 | 適用對象 |
|-------|-------------|----------|
| [文件指南](documentation-guide.md) | 本專案文件建立標準 | AI Agent |
| [Python 設定](python-setup.md) | 使用 UV 的 Python 開發環境設定 | AI Agent |
| [遠端 Docker 伺服器](remote-docker-server.md) | 遠端 Docker 環境（10.0.1.9）使用方式 | AI Agent |

---

## 快速連結

### AI Agent 適用：撰寫標準

- **撰寫標準**：請參閱 [documentation-guide.md](documentation-guide.md) 了解範本、命名慣例和風格指南
- **文件類型**：研究筆記存放於 `../research/`，交付文件存放於 `../reports/`

### AI Agent 適用：Python 環境

- **Python 環境**：使用 UV（而非 pip/poetry）——請參閱 [python-setup.md](python-setup.md)
- **測試**：請遵循 [`../testing/local/README.md`](../testing/local/README.md) 的本機測試指南

### AI Agent 適用：遠端伺服器

- **遠端伺服器**：Proxmox VE 位於 `10.0.1.9` ——請參閱 [remote-docker-server.md](remote-docker-server.md)
- **部署**：請參考 [`../reports/4d-upgrade-steps.md`](../reports/4d-upgrade-steps.md) 的升級步驟

---

## 指南說明

### 文件指南

本專案文件建立和組織指南，包含：

- 文件位置（research 與 reports 的區別）
- 命名慣例（`pr-12345.md`、`upgrade-changelog-vX.Y.md`）
- 文件範本（研究、版本分析、報告、階段計畫）
- 撰寫風格（描述使用繁體中文，技術術語使用英文）

### Python 設定

使用 UV 進行 Python 開發的說明：

- 使用 `uv sync` 安裝相依套件
- 使用 `uv run python` 執行腳本
- 注意事項（請勿使用 pip、pipenv 或 poetry）

### 遠端 Docker 伺服器

遠端 Docker 伺服器的連線詳細資訊和使用範例：

- 系統規格（Proxmox VE、x86_64）
- SSH 指令
- Docker Compose 部署
- 日誌檢視

---

*請參閱 [SUMMARY.md](../SUMMARY.md) 以取得完整的文件導覽。*
