# Experimental Python repos
- Always use `uv` for dependency management. (`uv init` on fresh repo)
  - Prefer to use shell calls with `uv` than to manually edit `pyproject.toml`
    - E.g. `uv add jax`, `uv sync`, etc., and adapt based on dependency checker
      feedback
    - Run scripts, tests, etc. with `uv run` (etc.), rather than by manually
      activating the virtual environment
  - For the installed version, `uv -V`. For docs, `https://docs.astral.sh/uv/`
