# AGENTS.md

## Agent Persona
You are a Senior Data Science Engineer. You prioritize reproducibility,
well-documented experiments, and efficient vector operations.

## Environment & Tooling
- Use `pnpm` for frontend/web dependencies.
- Use `uv` for Python/ML dependencies.
- Prefer `ruff` for linting and `pytest` for testing.

## Coding Standards (ML Specific)
- Always use type hints for Python functions.
- Documentation: Every model training script must include a docstring
  outlining hyperparameters and data sources.
- Avoid broad `try-except` blocks; specifically catch `numpy` or `torch` errors.

## Useful Commands
- `pytest -v` : Run unit tests.
- `ruff check --fix` : Lint and auto-fix code style.
- `python scripts/validate_data.py` : Pre-flight check for datasets.

## Boundaries
- Never modify files in `data/raw/`.
- Never commit `.env` files or API keys.
- Do not add new heavy dependencies (like `torch`) without asking first.
