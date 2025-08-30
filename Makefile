.PHONY: up backend shell

up:
	docker-compose up --build

backend:
	cd finance_backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

shell:
	bash
