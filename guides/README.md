# Guides

> How-to guides for the LiteLLM Upgrade project

← [Back to Documentation Home](../README.md)

---

## Available Guides

| Guide | Description | Audience |
|-------|-------------|----------|
| [Documentation Guide](documentation-guide.md) | Standards for creating documents in this project | Contributors |
| [Python Setup](python-setup.md) | UV-based Python development setup | Developers |
| [Remote Docker Server](remote-docker-server.md) | Remote Docker environment (10.0.1.9) usage | Operations |

---

## Quick Links

### For Contributors

- **Writing Standards**: See [documentation-guide.md](documentation-guide.md) for templates, naming conventions, and style guidelines
- **Document Types**: Research notes go to `../research/`, deliverables go to `../reports/`

### For Developers

- **Python Environment**: Use UV (not pip/poetry) — see [python-setup.md](python-setup.md)
- **Testing**: Follow the local testing guide at [`../testing/local/README.md`](../testing/local/README.md)

### For Operations

- **Remote Server**: Proxmox VE at `10.0.1.9` — see [remote-docker-server.md](remote-docker-server.md)
- **Deployment**: Reference the upgrade steps in [`../reports/4d-upgrade-steps.md`](../reports/4d-upgrade-steps.md)

---

## Guide Descriptions

### Documentation Guide

Guidelines for creating and organizing documents in this project, including:

- Document locations (research vs reports)
- Naming conventions (`pr-12345.md`, `upgrade-changelog-vX.Y.md`)
- Document templates (Research, Version Analysis, Report, Phase Plan)
- Writing style (Traditional Chinese for descriptions, English for technical terms)

### Python Setup

Instructions for Python development using UV:

- Installing dependencies with `uv sync`
- Running scripts with `uv run python`
- What NOT to do (no pip, pipenv, or poetry)

### Remote Docker Server

Connection details and usage examples for the remote Docker server:

- System specifications (Proxmox VE, x86_64)
- SSH commands
- Docker Compose deployment
- Log viewing

---

*See [SUMMARY.md](../SUMMARY.md) for complete documentation navigation.*
