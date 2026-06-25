# Playwright image for Selenoid

Docker-образ браузера Playwright для [qa-guru/selenoid](https://github.com/qa-guru/selenoid) (native Playwright через WebSocket).

**Docker Hub:** [`qaguru/playwright`](https://hub.docker.com/r/qaguru/playwright)

## Что внутри

Базовый слой — [`mcr.microsoft.com/playwright`](https://mcr.microsoft.com/en-us/product/playwright/about). Поверх него:

| Добавление | Зачем |
|------------|-------|
| `x11vnc`, `x11-utils` | VNC и видеозапись (`enableVNC`, `enableVideo`) |
| `playwright@<version>` в `/home/pwuser/node_modules` | фиксированный `run-server` для hub |
| `launch-headed-browser.js` | headed-режим для ручных сессий в Selenoid UI |

Hub Selenoid (`qaguru/selenoid` — отдельный образ) при старте сессии поднимает `Xvfb`, при необходимости VNC и:

```bash
node /home/pwuser/node_modules/playwright/cli.js run-server --port 3000 --host 0.0.0.0
```

## Pull

```bash
docker pull qaguru/playwright:v1.61.1-noble
```

Multi-arch: `linux/amd64`, `linux/arm64` (Mac Apple Silicon).

## Сборка

```bash
chmod +x scripts/build.sh scripts/push.sh
./scripts/build.sh v1.61.1-noble
```

Локально на Mac собирается `arm64`, на Linux — `amd64`. Платформа: `PLATFORM=linux/amd64 ./scripts/build.sh v1.61.1-noble`.

## Публикация в Docker Hub

```bash
docker login
./scripts/push.sh v1.61.1-noble
```

Тег `v<playwright-version>-noble`, например `v1.61.1-noble`, `v1.61.0-noble`.

## browsers.json (Selenoid)

```json
{
  "chromium": {
    "default": "1.61.1",
    "versions": {
      "1.61.1": {
        "image": "qaguru/playwright:v1.61.1-noble",
        "port": "3000",
        "protocol": "playwright",
        "playwrightVersion": "1.61.1",
        "user": "pwuser",
        "workDir": "/home/pwuser",
        "shmSize": 2147483648
      }
    }
  }
}
```

Версия клиента `@playwright/test` должна совпадать с `playwrightVersion`.

## Контракт с Selenoid

Пути в образе не менять без обновления [playwright_docker.go](https://github.com/qa-guru/selenoid/blob/main/service/playwright_docker.go) в fork Selenoid:

| Путь | Назначение |
|------|------------|
| `/home/pwuser` | рабочая директория (`pwuser`) |
| `/home/pwuser/node_modules/playwright/cli.js` | `run-server` |
| `/home/pwuser/launch-headed-browser.js` | headed UI-сессии |

## Связанные репозитории

| Репозиторий | Роль |
|-------------|------|
| [qa-guru/selenoid](https://github.com/qa-guru/selenoid) | Hub, WebSocket `/playwright/...` |
| [qa-guru/selenoid-ui](https://github.com/qa-guru/selenoid-ui) | UI, Capabilities, VNC |
| [qa-guru/selenoid_selenium_playwright](https://github.com/qa-guru/selenoid_selenium_playwright) | Примеры тестов |
