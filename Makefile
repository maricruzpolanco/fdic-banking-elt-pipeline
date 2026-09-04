.PHONY: lint test test-integration typecheck fmt all

fmt:
	uv run ruff format .

lint:
	uv run ruff check . --fix

typecheck:
	uv run mypy src/

test:
	uv run pytest -m "not integration"

test-integration:
	uv run pytest -m integration

all: fmt lint typecheck test
