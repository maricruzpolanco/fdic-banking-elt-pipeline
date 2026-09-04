# Troubleshooting

## Duplicate logging.basicConfig() calls

If app.log is empty or its lines don't match the format %(asctime)s - %(name)s - %(levelname)s - %(message)s, a logging.basicConfig() call is firing at import time in one of the ingestion modules before main() runs, so the handler and format configured in main() never take effect.

## postCreateCommand cannot rely on remoteEnv PATH

devcontainer.json's remoteEnv PATH addition does not reliably apply during postCreateCommand execution. A tool installed earlier in the same postCreateCommand chain cannot be found by name later in that same chain, even if remoteEnv already lists its folder on PATH. This matches a known issue reported against the Dev Containers project.

Fix: call the tool by its full file path instead of relying on PATH resolution. Current devcontainer.json postCreateCommand:

```
curl -LsSf https://astral.sh/uv/install.sh | sh && ~/.local/bin/uv sync
```

This is not specific to uv, it applies to any tool installed and then immediately used within the same postCreateCommand.

## uv init creates an app-style project by default

Plain `uv init`, with no flags, creates an app-style pyproject.toml with no build-system section, meaning the project is not installable as a package, and drops a stub main.py at the repo root.

If a src/ layout already exists before uv init runs, fix by adding build-system and tool.hatch.build.targets.wheel sections to pyproject.toml by hand, using hatchling as the backend, pointed at src/fdic_pipeline.

If starting a project from scratch before any src/ layout exists, `uv init --package` creates the src layout and build-system section together in one step, avoiding this fix entirely.

## Git remote: HTTPS vs SSH

HTTPS remotes prompt for a GitHub username on every push. Switching the remote to SSH removes this.

## GitHub email privacy setting

If GitHub's email privacy setting is on, the real email lands in commit metadata unless user.email is set to the [username]@users.noreply.github.com address, found under GitHub Settings, Emails.

## Bundled commits (historical)

An earlier version of this repo had commits that bundled multiple unrelated logical changes into one, for example a missing return statement fix bundled with an unrelated main guard fix. Root cause was making several changes before committing instead of committing after each individual change. Resolved by rebuilding the repo with atomic commit discipline enforced from the first commit, see the commit history for the current pattern.
