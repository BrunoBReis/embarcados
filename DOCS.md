# Documentacao do Projeto

Este arquivo explica duas coisas:

- como rodar o projeto
- como o projeto funciona internamente

## Objetivo

Este repositorio existe para desenvolver uma aplicacao simples para ESP32 usando ESP-IDF, editando o codigo no host e executando build, flash e monitor dentro de um container Docker.

O fluxo e este:

1. voce edita o codigo em `app/main/main.c`
2. o Docker sobe um ambiente com ESP-IDF
3. o `idf.py` compila o firmware
4. o firmware e gravado na placa pela porta serial
5. o monitor serial mostra a saida da aplicacao

## Estrutura do projeto

### `app/`

Contem o projeto ESP-IDF de fato.

- `app/CMakeLists.txt`: arquivo principal do projeto CMake
- `app/main/CMakeLists.txt`: registra o componente `main`
- `app/main/main.c`: codigo da aplicacao
- `app/sdkconfig`: configuracao gerada pelo ESP-IDF para o target atual
- `app/build/`: artefatos de compilacao gerados pelo `idf.py build`

### `compose.yml`

Define o container Docker usado para rodar o ESP-IDF.

Esse container:

- usa a imagem `espressif/idf`
- monta `./app` em `/workspace`
- expoe a porta serial definida em `PORT`
- deixa o diretorio de trabalho em `/workspace`

### `Makefile`

Fornece atalhos para os comandos mais comuns.

Em vez de voce digitar o comando completo do Docker toda vez, voce usa:

- `make up`
- `make set-target`
- `make build`
- `make flash`
- `make monitor`

### `.env`

Guarda as configuracoes variaveis do ambiente.

Hoje ele controla:

- `PORT`: porta serial da placa
- `TARGET`: chip usado no `idf.py set-target`
- `IDF_VERSION`: versao da imagem Docker

## Como rodar o projeto

### 1. Conectar a placa

Conecte a ESP32 por USB e descubra a porta serial:

```bash
ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null
```

Se aparecer, por exemplo, `/dev/ttyUSB0`, use esse valor no `.env`.

### 2. Configurar o `.env`

Se ainda nao existir:

```bash
cp .env.example .env
```

Depois ajuste os valores. Exemplo:

```dotenv
PORT=/dev/ttyUSB0
TARGET=esp32
IDF_VERSION=release-v5.2
```

### 3. Subir o container

```bash
make up
```

Esse comando:

- faz o build da imagem definida no `compose.yml`
- cria o container
- deixa o ambiente pronto para executar `idf.py`

### 4. Definir o target da placa

```bash
make set-target
```

Esse comando chama:

```bash
idf.py set-target esp32
```

ou o valor definido em `TARGET`.

Esse passo prepara o projeto para o chip correto e gera ou atualiza arquivos de configuracao do ESP-IDF.

### 5. Compilar

```bash
make build
```

Esse comando gera os binarios do firmware dentro de `app/build/`.

### 6. Gravar na placa

```bash
make flash
```

Esse comando usa a porta definida em `PORT` para enviar o firmware para a ESP32.

### 7. Abrir o monitor serial

```bash
make monitor
```

Ou, se quiser gravar e monitorar em um passo:

```bash
make flash-monitor
```

No estado atual da aplicacao, voce deve ver repetidamente:

```text
Ola, ESP32 via ESP-IDF!
```

### 8. Fluxo do dia a dia

Depois da configuracao inicial, o uso normal e:

1. editar `app/main/main.c`
2. rodar `make build`
3. rodar `make flash`
4. rodar `make monitor`

## Como o projeto funciona

## 1. O codigo da aplicacao

O arquivo principal hoje e `app/main/main.c`.

Ele define a funcao:

```c
void app_main(void)
```

No ESP-IDF, `app_main()` e o ponto de entrada da aplicacao. Quando a ESP32 termina o boot, o sistema chama essa funcao.

No codigo atual:

- existe um `while (1)` infinito
- a cada iteracao ele faz `printf`
- depois espera 1 segundo com `vTaskDelay`

Por isso a mensagem aparece continuamente no monitor serial.

## 2. O papel do CMake

O ESP-IDF usa CMake por baixo do `idf.py`.

### `app/CMakeLists.txt`

Esse arquivo inicializa o projeto:

- define a versao minima do CMake
- inclui a infraestrutura do ESP-IDF
- declara o nome do projeto

### `app/main/CMakeLists.txt`

Esse arquivo registra o componente `main`.

No ESP-IDF, o projeto e organizado em componentes. O componente `main` e o componente padrao onde o arquivo principal da aplicacao costuma ficar.

## 3. O papel do `idf.py`

O `idf.py` e o frontend do ESP-IDF.

Ele encapsula comandos de build, configuracao, flash e monitor.

Os comandos principais usados aqui sao:

- `idf.py set-target`
- `idf.py build`
- `idf.py flash`
- `idf.py monitor`

No `Makefile`, esses comandos sao executados dentro do container com:

```bash
bash -lc '. /opt/esp/idf/export.sh && idf.py ...'
```

Isso e necessario para carregar corretamente o ambiente do ESP-IDF antes de chamar o `idf.py`.

## 4. O papel do Docker

O Docker serve para evitar instalar manualmente todo o ESP-IDF no host.

Em vez disso:

- o host so precisa de Docker
- a imagem `espressif/idf` traz toolchain, Python e ferramentas do ESP-IDF
- o diretorio `app/` do host e montado dentro do container

Isso significa que:

- voce edita no seu editor normal
- o container apenas compila e conversa com a placa

## 5. Como a gravacao acontece

Quando voce roda `make flash`:

1. o `Makefile` executa `docker compose exec`
2. dentro do container, o `idf.py` chama as ferramentas de gravacao
3. essas ferramentas acessam a porta serial definida em `PORT`
4. o firmware compilado e enviado para a memoria flash da ESP32

Para isso funcionar, a serial precisa:

- existir no host
- estar mapeada no `compose.yml`
- bater com o valor de `PORT`

## 6. Como o monitor funciona

Quando voce roda `make monitor`, o container abre a mesma porta serial e mostra tudo o que a placa enviar.

Como o codigo atual usa `printf`, a saida aparece no terminal.

## Explicacao detalhada do processo

Esta secao responde as perguntas mais importantes sobre o fluxo.

## A compilacao e feita no computador ou na ESP32?

A compilacao e feita no seu computador, nao na ESP32.

Mais especificamente:

- voce escreve o codigo no host
- o Docker roda um container no seu computador
- dentro desse container existe o ambiente do ESP-IDF
- o `idf.py build` compila o codigo e gera os binarios

A ESP32 nao compila nada. Ela apenas:

- recebe o firmware ja pronto pelo `flash`
- grava esse firmware na memoria flash
- reinicia
- executa o programa

## Por que e usado `docker compose -f compose.yml`?

Esse comando serve para executar os comandos dentro do ambiente Docker definido pelo projeto.

### `docker compose`

E a ferramenta que sobe e gerencia containers baseados em um arquivo YAML.

### `-f compose.yml`

Indica explicitamente qual arquivo de configuracao deve ser usado.

No seu projeto, isso e util porque:

- deixa o comando explicito
- evita depender de nomes padrao
- garante que o `Makefile` use exatamente o arquivo `compose.yml`

### O que existe nesse `compose.yml`

O arquivo define:

- a imagem Docker usada
- o diretorio do projeto montado dentro do container
- a porta serial passada do host para o container
- o diretorio de trabalho `/workspace`

Em outras palavras, o `compose.yml` descreve o ambiente onde o ESP-IDF vai rodar.

## Para que serve `bash -lc`?

O `bash -lc` e usado para rodar um comando dentro de um shell configurado.

### `bash`

Abre o interpretador de comandos Bash.

### `-c`

Diz ao Bash para executar a string passada logo em seguida.

Exemplo:

```bash
bash -lc 'echo teste'
```

### `-l`

Faz o shell se comportar como login shell, o que ajuda a ter um ambiente mais previsivel.

No seu projeto, isso e usado principalmente para que o comando:

```bash
. /opt/esp/idf/export.sh && idf.py build
```

rode dentro de um shell que carregou corretamente o ambiente.

### Por que isso e necessario?

Porque o `idf.py` depende de variaveis de ambiente e caminhos de ferramentas configurados pelo ESP-IDF.

O script:

```bash
. /opt/esp/idf/export.sh
```

faz exatamente isso:

- ajusta variaveis de ambiente
- adiciona ferramentas ao `PATH`
- prepara o shell para usar o ESP-IDF

Sem esse passo, o container pode existir, mas o `idf.py` nao estar disponivel no PATH do comando executado por `docker compose exec`.

## Para que serve o `idf.py`?

O `idf.py` e a interface principal do ESP-IDF para o desenvolvedor.

Ele organiza o fluxo inteiro do projeto.

Em vez de voce chamar manualmente varias ferramentas separadas, o `idf.py` centraliza tudo.

### Principais funcoes

- configurar o target da placa
- preparar a configuracao do projeto
- chamar o CMake
- chamar o sistema de build
- gravar o firmware na placa
- abrir o monitor serial

### Comandos usados no projeto

- `idf.py set-target esp32`
- `idf.py build`
- `idf.py flash`
- `idf.py monitor`

### O que ele faz por baixo

O `idf.py` chama outras ferramentas para voce.

Por exemplo:

- usa CMake para configurar o projeto
- usa Ninja ou Make para compilar
- usa ferramentas de flash para gravar a ESP32
- usa um monitor serial para mostrar os logs

Ou seja, o `idf.py` e o frontend principal do processo.

## Processo completo de ponta a ponta

Aqui esta o fluxo completo, do codigo ate a execucao na placa.

### 1. Voce escreve o codigo

Voce altera arquivos como:

- `app/main/main.c`
- `app/CMakeLists.txt`
- `app/main/CMakeLists.txt`

Esses arquivos ficam no seu computador, no diretorio do projeto.

### 2. O projeto e montado dentro do container

Quando voce roda:

```bash
make up
```

o Docker sobe o container definido no `compose.yml`.

Esse container monta:

- a pasta `./app` do host

como:

- `/workspace` dentro do container

Isso significa que o container enxerga exatamente os mesmos arquivos que voce esta editando no host.

### 3. O ambiente do ESP-IDF e carregado

Quando voce roda algo como:

```bash
make build
```

o `Makefile` executa algo equivalente a:

```bash
docker compose -f compose.yml exec esp32 bash -lc '. /opt/esp/idf/export.sh && idf.py build'
```

Esse comando:

1. entra no container `esp32`
2. abre um shell Bash
3. carrega o ambiente do ESP-IDF
4. executa o `idf.py build`

### 4. O `idf.py` prepara o build

O `idf.py` olha para os arquivos do projeto:

- `app/CMakeLists.txt`
- `app/main/CMakeLists.txt`
- `app/sdkconfig`

e entao configura o build.

Ele usa o CMake para entender:

- qual e o nome do projeto
- quais componentes existem
- quais arquivos `.c` devem ser compilados
- qual e o target da placa

### 5. O firmware e compilado

Depois da configuracao, o sistema de build compila o codigo para a arquitetura da ESP32.

O resultado nao e um programa para Linux. E um firmware para microcontrolador.

Os arquivos gerados vao para:

- `app/build/`

Ali ficam:

- binarios
- objetos compilados
- arquivos intermediarios
- imagens prontas para gravacao

### 6. O firmware e enviado para a placa

Quando voce roda:

```bash
make flash
```

o `idf.py` usa a porta serial definida em `PORT` para conversar com a ESP32.

O caminho e este:

1. seu computador acessa a USB da placa
2. o Linux expoe isso como `/dev/ttyUSB0` ou `/dev/ttyACM0`
3. o Docker repassa essa porta para o container
4. o `idf.py flash` usa essa porta para enviar os binarios
5. a ESP32 grava o firmware na memoria flash

### 7. A ESP32 reinicia e executa o programa

Depois da gravacao:

- a placa reinicia
- o bootloader inicia
- o firmware gravado passa a ser executado
- a funcao `app_main()` comeca a rodar

No seu projeto atual, isso significa:

- imprimir uma mensagem
- esperar 1 segundo
- repetir isso indefinidamente

### 8. O monitor mostra a saida

Quando voce roda:

```bash
make monitor
```

o computador abre a mesma porta serial para ler a saida da placa.

Como o codigo usa `printf`, as mensagens aparecem no terminal.

## Diagrama textual do fluxo

```text
Voce edita main.c no host
        |
        v
Docker monta ./app em /workspace
        |
        v
Makefile executa docker compose exec
        |
        v
bash -lc carrega export.sh
        |
        v
idf.py configura e compila o projeto
        |
        v
binarios sao gerados em app/build/
        |
        v
idf.py flash envia firmware pela serial
        |
        v
ESP32 grava na flash e reinicia
        |
        v
app_main() executa na placa
        |
        v
idf.py monitor mostra os logs no terminal
```

## Comandos disponiveis

- `make up`: sobe o ambiente Docker
- `make down`: derruba o ambiente Docker
- `make set-target`: define o target do chip
- `make build`: compila o projeto
- `make flash`: grava o firmware
- `make monitor`: abre o monitor serial
- `make flash-monitor`: grava e monitora em seguida
- `make menuconfig`: abre a configuracao interativa do ESP-IDF
- `make bash`: abre um shell dentro do container

## Problemas comuns

### Porta serial nao existe

Se `make up`, `make flash` ou `make monitor` falharem, confirme primeiro:

```bash
ls /dev/ttyUSB* /dev/ttyACM* 2>/dev/null
```

Depois ajuste o `.env`.

### `idf.py` nao encontrado

Esse problema ja foi tratado no `Makefile` carregando:

```bash
. /opt/esp/idf/export.sh
```

### Permissao na serial

Se o usuario nao tiver permissao sobre a serial:

```bash
sudo usermod -aG dialout $USER
```

Depois faca logout/login.

## Resumo rapido

Para usar o projeto:

```bash
cp .env.example .env
make up
make set-target
make build
make flash-monitor
```

Para desenvolver no dia a dia:

```bash
make build
make flash-monitor
```
