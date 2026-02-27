# Python Development with UV

> UV-based Python development instructions

← [Back to Guides](README.md)

---

- **Date**: 2026-02-26
- **Purpose**: Instructions for AI agents to use UV for Python development in this project

## AI Instructions

When working on Python code in this project, **always use UV** instead of pip, pipenv, or poetry.

## Required Commands

### Installing Dependencies

```bash
# Sync dependencies from pyproject.toml
uv sync

# Add a new dependency
uv add <package-name>

# Add a dev dependency
uv add --dev <package-name>
```

### Running Python Scripts

```bash
# Run a Python script
uv run python script.py

# Run a script with arguments
uv run python script.py --arg1 value
```

### Running Tests

```bash
# Run pytest
uv run pytest

# Run with specific options
uv run pytest -v --cov
```

### Locking Dependencies

```bash
# Update lock file after adding/removing dependencies
uv lock
uv sync
```

## What NOT to Do

- Do NOT use `pip install`
- Do NOT use `pipenv`
- Do NOT use `poetry`
- Do NOT create virtual environments manually with `python -m venv`

## References

- [UV Documentation](https://docs.astral.sh/uv/)
