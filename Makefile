up:
	docker compose -f infrastructure/docker-compose.yml up -d

down:
	docker compose -f infrastructure/docker-compose.yml down

docker-build:
	docker compose -f infrastructure/docker-compose.yml build

stop:
	docker compose -f infrastructure/docker-compose.yml stop

init-emulator-data:
	. ./infrastructure/scripts/seed_emulators.sh

flutter-pub-get:
	cd src/frontend/aruku_pallarel && fvm flutter pub get

flutter-analyze:
	cd src/frontend/aruku_pallarel && fvm flutter analyze

flutter-run:
	cd src/frontend/aruku_pallarel && fvm flutter run

backend-run:
	cd src/backend/main-backend-server && uv run -- python app.py

adk-run:
	cd src/backend/sanpo-agent && uv run -- python app.py
