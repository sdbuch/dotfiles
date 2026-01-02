# Python code

- ALWAYS use `uv` for dependency management. (`uv init` on fresh repo)
  - Prefer to use shell calls with `uv` than to manually edit `pyproject.toml`
    - E.g. `uv add jax`, `uv sync`, etc., and adapt based on dependency checker
      feedback
- Run scripts, tests, etc. with `uv run` (etc.), rather than by manually
  activating the virtual environment
- For the installed version, `uv -V`. For docs, `https://docs.astral.sh/uv/`

# Experimental Python repos

- ALWAYS lint code and typecheck with `ty` static typechecker cli whenever edits
  to code are made
  - With `uv`, `uvx ty check`
