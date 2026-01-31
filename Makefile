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

flutter-generate:
	cd src/frontend/aruku_pallarel && fvm dart run build_runner build --delete-conflicting-outputs

flutter-run:
	cd src/frontend/aruku_pallarel && fvm flutter run

flutter-clean:
	cd src/frontend/aruku_pallarel && fvm flutter clean

flutter-pod-install:
	cd src/frontend/aruku_pallarel/ios && pod install

flutter-open:
	open src/frontend/aruku_pallarel/ios/Runner.xcworkspace

OSRM_DATA_DIR ?= $(CURDIR)/tmp/osrm
OSRM_BASENAME ?= tokyo
OSRM_PBF_URL ?= https://download.bbbike.org/osm/bbbike/Tokyo/Tokyo.osm.pbf
OSRM_PBF_FILE ?= $(OSRM_DATA_DIR)/$(OSRM_BASENAME).osm.pbf
OSRM_BASE_IMAGE ?= ghcr.io/project-osrm/osrm-backend:v6.0.0
OSRM_IMAGE ?= osrm-tokyo:latest
OSRM_IMAGE_PLATFORM ?= linux/amd64

osrm-download:
	mkdir -p $(OSRM_DATA_DIR)
	curl -fL --retry 3 -o $(OSRM_PBF_FILE) $(OSRM_PBF_URL)

osrm-extract: osrm-download
	docker run --rm -t -v $(OSRM_DATA_DIR):/data $(OSRM_BASE_IMAGE) \
		osrm-extract -p /opt/car.lua /data/$(OSRM_BASENAME).osm.pbf

osrm-partition: osrm-extract
	docker run --rm -t -v $(OSRM_DATA_DIR):/data $(OSRM_BASE_IMAGE) \
		osrm-partition /data/$(OSRM_BASENAME).osrm

osrm-customize: osrm-partition
	docker run --rm -t -v $(OSRM_DATA_DIR):/data $(OSRM_BASE_IMAGE) \
		osrm-customize /data/$(OSRM_BASENAME).osrm

osrm-build: osrm-customize

osrm-image: osrm-build
	docker buildx build --platform $(OSRM_IMAGE_PLATFORM) \
		--load \
		-f infrastructure/osrm/Dockerfile \
		--build-arg OSRM_BASE_IMAGE=$(OSRM_BASE_IMAGE) \
		--build-arg OSRM_DATA_BASENAME=$(OSRM_BASENAME) \
		-t $(OSRM_IMAGE) .

osrm-push:
	docker push $(OSRM_IMAGE)
