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

## Organização do código

O ESP-IDF organiza o projeto em componentes. O componente principal deste projeto é `app/main/`, onde fica a função `app_main()`, que é o ponto de entrada da aplicação.

Para projetos pequenos, você pode manter vários arquivos no próprio componente `main`:

```text
app/main/
  CMakeLists.txt
  main.c
  led.c
  led.h
  sensor.c
  sensor.h
```

Nesse caso, liste os arquivos `.c` em `app/main/CMakeLists.txt` e exponha a pasta atual para os headers:

```cmake
idf_component_register(SRCS "main.c" "led.c" "sensor.c"
                       INCLUDE_DIRS ".")
```

Arquivos `.c` entram em `SRCS`, porque precisam ser compilados. Arquivos `.h` ficam em diretórios listados em `INCLUDE_DIRS`, porque são incluídos por outros arquivos com `#include`.

Para projetos maiores, é melhor separar responsabilidades em componentes próprios:

```text
app/
  main/
    CMakeLists.txt
    main.c
  components/
    led/
      CMakeLists.txt
      led.c
      include/
        led.h
    sensor/
      CMakeLists.txt
      sensor.c
      include/
        sensor.h
```

Um componente `led` poderia ter:

```cmake
idf_component_register(SRCS "led.c"
                       INCLUDE_DIRS "include")
```

E o componente `main` poderia declarar que depende dele:

```cmake
idf_component_register(SRCS "main.c"
                       INCLUDE_DIRS "."
                       REQUIRES led)
```

Essa separação é uma boa prática quando um módulo tem responsabilidade clara, como driver de LED, sensor, display, Wi-Fi ou armazenamento. Ela deixa as dependências explícitas e facilita reutilizar código em outros projetos.

Na hora de gravar na placa, o ESP-IDF não envia cada arquivo `.c` separadamente. Ele compila todos os `.c` registrados nos componentes, junta tudo com as bibliotecas do ESP-IDF e gera um firmware final, como `app/build/hello_esp32.bin`. O `make flash` grava esse binário final na memória flash da ESP32.

## Comandos disponíveis

- `make help`: lista os comandos disponíveis
- `make up`: sobe o container usando a imagem existente
- `make rebuild`: sobe o container reconstruindo a imagem
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
