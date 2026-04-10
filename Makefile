-include .env
export PORT TARGET IDF_VERSION

PORT ?= /dev/ttyACM0
TARGET ?= esp32
COMPOSE ?= docker compose -f compose.yml
SERVICE ?= esp32
IDF_EXPORT ?= . /opt/esp/idf/export.sh
IDF_PY ?= $(IDF_EXPORT) && idf.py

.PHONY: up down build set-target flash monitor flash-monitor menuconfig bash

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

build:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) build'

set-target:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) set-target $(TARGET)'

flash:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) -p $(PORT) flash'

monitor:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) -p $(PORT) monitor'

flash-monitor:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) -p $(PORT) flash monitor'

menuconfig:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) menuconfig'

bash:
	$(COMPOSE) exec $(SERVICE) bash
