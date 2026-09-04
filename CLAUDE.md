# CLAUDE.md

Standing instructions for Claude Code sessions in this repository. Read this before doing any work in this session.

## Role and boundaries

Claude Code performs exactly five tasks in this project, only when explicitly requested, never autonomously:

1. **Code review.** Check code against this project's conventions, enforced through pyproject.toml, .pre-commit-config.yaml, and the Makefile. Output is prose describing what is wrong and why, not a corrected code block.
2. **Debugging.** Help interpret errors, tracebacks, and unexpected behavior on request. Explain the likely cause. Do not rewrite the failing code.
3. **Documentation.** Docstrings, README sections, code comments, when requested.
4. **Commit messages.** Generate a commit message from a diff of changes already made and tested. One commit at a time, immediately after each verified change. Do not batch multiple unrelated changes into one message.
5. **Pull request descriptions.** Generate a PR description from the commits on a branch, when requested.

Do not write, complete, or autofill implementation code unless explicitly asked to in that specific session. Do not take any git action (commit, push, open a PR) without explicit go ahead for that specific action. Do not suggest refactors or changes outside the scope of the current request.

This scope is applied consistently across every project in this portfolio, not invented for this repo alone.

## Project context

- `docs/architecture.md`: stack, dev and production split, orchestration design, and the reasoning behind each choice
- `docs/adr/0001-business-case.md`: the business framing behind the dbt layer and why it was chosen over alternatives
- `docs/adr/0002-mart-design.md`: mart grain, layering, threshold methodology, snapshot design, and the one open item, risk tier mapping
- `docs/api-reference.md`: FDIC API endpoints, fields, pagination, response structure, needed to review or debug fdic_client.py correctly
- `docs/pipeline.md`: what each ingestion script does, S3 and Snowflake setup
- `TROUBLESHOOTING.md`: environment quirks and known one time mistakes, relevant to debugging

Pending refactor work is tracked as GitHub Issues, not a docs file. Check the repo's Issues tab before starting any refactoring work.

Other project context files can be added to `docs/` as needed. Check that folder if a review or debugging task needs background this file doesn't cover.

## Note on portfolio framing

This project intentionally documents AI usage boundaries rather than hiding them. Final review and every decision that ships to main is made by the engineer working on this project, not by Claude Code.
