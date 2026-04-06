# ESP32 Lab com ESP-IDF + Docker

Repositório mínimo para editar no host e compilar, gravar e monitorar uma ESP32 com a imagem oficial `espressif/idf`.

Guia detalhado de uso e funcionamento: `DOCS.md`.

## Estrutura

- `app/`: projeto ESP-IDF
- `compose.yml`: serviço Docker para build e acesso serial
- `Makefile`: atalhos para `idf.py`
- `.env.example`: valores padrão para porta serial, alvo e versão do ESP-IDF

## Pré-requisitos

- Docker e Docker Compose
- Uma placa compatível com `TARGET=esp32`
- Acesso à porta serial no host

Para descobrir a porta serial:

```bash
ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null
```

Se necessário, adicione seu usuário ao grupo da serial:

```bash
sudo usermod -aG dialout $USER
```

Depois faça logout/login.

## Configuração

Crie um arquivo `.env` a partir do exemplo:

```bash
cp .env.example .env
```

Ajuste os valores se necessário:

```dotenv
PORT=/dev/ttyACM0
TARGET=esp32
IDF_VERSION=release-v5.2
```

## Como rodar

Primeira vez:

```bash
make up
make set-target
make build
make flash
make monitor
```

Fluxo do dia a dia:

```bash
make build
make flash
make monitor
```

Você também pode sobrescrever variáveis sem editar arquivos:

```bash
make flash PORT=/dev/ttyUSB0
make set-target TARGET=esp32s3
```

## Comandos disponíveis

- `make up`: sobe o container e faz build da imagem
- `make down`: para e remove o container
- `make set-target`: executa `idf.py set-target $(TARGET)`
- `make build`: compila o firmware
- `make flash`: grava na placa usando `$(PORT)`
- `make monitor`: abre o monitor serial
- `make flash-monitor`: grava e abre o monitor em um passo
- `make menuconfig`: abre o menuconfig
- `make bash`: abre shell dentro do container

## Notas importantes

- O arquivo `app/sdkconfig` nao e versionado. Ele sera gerado pelo `idf.py set-target` ou `idf.py build`.
- O `compose.yml` usa a mesma porta definida em `PORT`, evitando divergencia com o `Makefile`.
- A imagem Docker usa uma tag configuravel por `IDF_VERSION` para reduzir variacao de ambiente.

## Troubleshooting

Se `flash` ou `monitor` falharem:

- confirme a porta com `ls /dev/ttyUSB* /dev/ttyACM*`
- confira se `PORT` no `.env` bate com a placa conectada
- verifique se o container enxerga a serial com `make bash` e `ls -l $(printf %s "$PORT")`
- confirme permissao de acesso no host
