-include .env
export PORT TARGET IDF_VERSION

PORT ?= /dev/ttyACM0
TARGET ?= esp32
COMPOSE ?= docker compose -f compose.yml
SERVICE ?= esp32
IDF_EXPORT ?= . /opt/esp/idf/export.sh
IDF_PY ?= $(IDF_EXPORT) && idf.py

.PHONY: help up rebuild down build set-target flash erase-flash monitor flash-monitor menuconfig bash

help:
	@printf 'Targets disponiveis:\n'
	@printf '  make up             Sobe o container usando a imagem existente\n'
	@printf '  make rebuild        Sobe o container reconstruindo a imagem\n'
	@printf '  make down           Para e remove o container\n'
	@printf '  make set-target     Configura o target do ESP-IDF usando TARGET=%s\n' '$(TARGET)'
	@printf '  make build          Compila o firmware\n'
	@printf '  make flash          Grava o firmware usando PORT=%s\n' '$(PORT)'
	@printf '  make erase-flash    Apaga a flash da placa usando PORT=%s\n' '$(PORT)'
	@printf '  make monitor        Abre o monitor serial usando PORT=%s\n' '$(PORT)'
	@printf '  make flash-monitor  Grava o firmware e abre o monitor serial\n'
	@printf '  make menuconfig     Abre a configuracao interativa do ESP-IDF\n'
	@printf '  make bash           Abre um shell dentro do container\n'
	@printf '\nVariaveis:\n'
	@printf '  PORT=%s\n' '$(PORT)'
	@printf '  TARGET=%s\n' '$(TARGET)'
	@printf '  IDF_VERSION=%s\n' '$(IDF_VERSION)'
	@printf '\nExemplos:\n'
	@printf '  make flash PORT=/dev/ttyUSB0\n'
	@printf '  make set-target TARGET=esp32s3\n'

up:
	$(COMPOSE) up -d

rebuild:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

build:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) build'

set-target:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) set-target $(TARGET)'

flash:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) -p $(PORT) flash'

erase-flash:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) -p $(PORT) erase-flash'

monitor:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) -p $(PORT) monitor'

flash-monitor:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) -p $(PORT) flash monitor'

menuconfig:
	$(COMPOSE) exec $(SERVICE) bash -lc '$(IDF_PY) menuconfig'

bash:
	$(COMPOSE) exec $(SERVICE) bash
