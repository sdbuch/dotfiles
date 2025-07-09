# Experimental Python repos
- ALWAYS use `uv` for dependency management. (`uv init` on fresh repo)
  - Prefer to use shell calls with `uv` than to manually edit `pyproject.toml`
    - E.g. `uv add jax`, `uv sync`, etc., and adapt based on dependency checker
      feedback
  - Run scripts, tests, etc. with `uv run` (etc.), rather than by manually
    activating the virtual environment
  - For the installed version, `uv -V`. For docs, `https://docs.astral.sh/uv/`
- In clean experimental python repositories, ALWAYS install the following
  packages, and use them freely in code written as relevant (see detailed
  explanations for use cases below)
  - jax
  - matplotlib
  - treescope
  - matplotlib-backend-sixel
  - einops
  - pynvim
  - jupyter_client
  - ipykernel
  - debugpy
  - pytest
  - Explanations for the above:
    - Numerical code should use jax and einops. Visualizations with matplotlib
      and treescope (treescope gives interactive visualizations of tensors)
    - matplotlib-backend-sixel allows figures to be output to my terminal/tmux.
      You can view these in your "repl" loop for debugging
    - Use pytest for managing and running tests
    - pynvim, jupyter_client, ipykernel are for my own use with jupyter
      notebook-like editing in nvim
    - debugpy is for my "repl" framework in nvim
- ALWAYS style code with `ruff` formatter
  - E.g. with `uv`, `uvx ruff`
  - Do this whenever edits to code are made
- ALWAYS lint code and typecheck with `pyright` static typechecker cli
  - E.g. with `uv`, `uv add pyright` in the active project, then `uv run
    pyright`
  - Do this whenever edits to code are made
