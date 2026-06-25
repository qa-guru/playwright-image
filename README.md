# Playwright image for Selenoid

Docker-образ **browser node** с Playwright для [qa-guru/selenoid](https://github.com/qa-guru/selenoid) — native Playwright через WebSocket `/playwright/{browser}/{version}`.

**Docker Hub:** [`qaguru/playwright`](https://hub.docker.com/r/qaguru/playwright)

> Это **не** образ Selenoid hub. Hub — отдельный бинарник / будущий образ `qaguru/selenoid`.  
> Здесь только контейнер браузера, который hub поднимает на каждую сессию.

**Hub:** Docker Engine **26.1.x** (API **1.45**), Go **1.23.x** — см. [README](../README.md#требования-к-окружению) в корне репозитория.

---

## Что нового по сравнению с Microsoft Playwright

Базовый слой — [`mcr.microsoft.com/playwright`](https://mcr.microsoft.com/en-us/product/playwright/about) (Ubuntu Noble, `pwuser`, бинарники Chromium / Firefox / WebKit, Node.js).

Мы добавляем **тонкую надстройку** (~10 MB + npm-пакет):

| # | Добавление | Зачем |
|---|------------|-------|
| 1 | **`x11vnc`** + **`x11-utils`** | VNC и видеозапись: `enableVNC=true`, `enableVideo=true` в query WebSocket |
| 2 | **`playwright@<version>`** в `/home/pwuser/node_modules` | фиксированный путь и версия для `run-server` — hub всегда знает, что запускать |
| 3 | **`launch-headed-browser.js`** | headed-режим для ручных сессий в Selenoid UI (Capabilities → Create Session) |

Hub при старте контейнера (не в образе, а в [playwright_docker.go](https://github.com/qa-guru/selenoid/blob/main/service/playwright_docker.go)) поднимает `Xvfb`, при необходимости VNC и:

```bash
node /home/pwuser/node_modules/playwright/cli.js run-server --port 3000 --host 0.0.0.0
```

---

## Чего в образе нет — это делает Selenoid hub

| Функция | Где |
|---------|-----|
| WebSocket `ws://host:4444/playwright/chromium/1.61.1` | `./bin/selenoid` (hub) |
| Прокси тест ↔ браузер | hub |
| Запись видео | `selenoid/video-recorder` (отдельный контейнер) |
| Старт Xvfb, VNC, `run-server` | hub генерирует startup-скрипт при `docker run` |

```
┌─────────────────────────────────────────────────────────┐
│  Selenoid HUB  (Go, порт 4444)                          │
│  qa-guru/selenoid                                       │
└──────────────────────┬──────────────────────────────────┘
                       │ docker run ...
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
   twilio/selenoid   qaguru/playwright   selenoid/video-recorder
   :chrome_stable    :v1.61.1-noble     (запись видео)
         │             │
    WebDriver       Playwright
```

---

## Сравнение в одну таблицу

| | `mcr.microsoft.com/playwright` | `qaguru/playwright` |
|--|:------------------------------:|:-------------------:|
| Браузеры Playwright | ✅ | ✅ (тот же слой) |
| `run-server` для remote connect | можно, путь/версия не зафиксированы | ✅ фиксированный CLI |
| VNC (`x11vnc`) | ❌ | ✅ |
| Headed UI-сессии | ❌ | ✅ `launch-headed-browser.js` |
| Интеграция с Selenoid | ❌ | ✅ |
| multi-arch `arm64` + `amd64` | ✅ | ✅ |

**Итого:** наш образ — тонкая обёртка для Selenoid: VNC, видео, ручные сессии в UI и стабильный `run-server`. Сам Playwright и браузеры — те же, что у Microsoft.

---

## Pull

```bash
docker pull qaguru/playwright:v1.61.1-noble
```

| Платформа | Когда подтянется |
|-----------|------------------|
| `linux/arm64` | Mac Apple Silicon, ARM-серверы |
| `linux/amd64` | Linux CI, x86-серверы |

---

## Сборка

```bash
chmod +x scripts/build.sh scripts/push.sh
./scripts/build.sh v1.61.1-noble
```

Локально на Mac — `arm64`, на Linux — `amd64`. Явно: `PLATFORM=linux/amd64 ./scripts/build.sh v1.61.1-noble`.

## Публикация в Docker Hub

```bash
docker login
./scripts/push.sh v1.61.1-noble
```

Тег: `v<playwright-version>-noble` (например `v1.61.1-noble`, `v1.61.0-noble`).

CI: GitHub Actions при push тега `v*-noble` или вручную через **workflow_dispatch** (нужны secrets `DOCKER_USERNAME`, `DOCKER_PASSWORD`).

---

## browsers.json (Selenoid)

```json
{
  "chromium": {
    "default": "1.61.1",
    "versions": {
      "1.61.1": {
        "image": "qaguru/playwright:v1.61.1-noble",
        "port": "3000",
        "path": "/",
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

Версия клиента `@playwright/test` / `playwright` в тестах **должна совпадать** с `playwrightVersion`.

Пример подключения:

```
ws://127.0.0.1:4444/playwright/chromium/1.61.1?enableVideo=true&enableVNC=true
```

---

## Контракт с Selenoid

Пути в образе **не менять** без синхронного обновления [playwright_docker.go](https://github.com/qa-guru/selenoid/blob/main/service/playwright_docker.go):

| Путь в образе | Назначение |
|---------------|------------|
| `/home/pwuser` | рабочая директория, пользователь `pwuser` |
| `/home/pwuser/node_modules/playwright/cli.js` | `playwright run-server` |
| `/home/pwuser/launch-headed-browser.js` | headed-браузер для VNC в UI |

---

## Связанные репозитории

| Репозиторий | Роль |
|-------------|------|
| [qa-guru/playwright-image](https://github.com/qa-guru/playwright-image) | **этот репозиторий** — Dockerfile, сборка образа |
| [qa-guru/selenoid](https://github.com/qa-guru/selenoid) | Hub, WebSocket `/playwright/...`, `browsers.json` |
| [qa-guru/selenoid-ui](https://github.com/qa-guru/selenoid-ui) | UI: Capabilities, VNC, Playwright-сессии |
| [qa-guru/selenoid_selenium_playwright_tests](https://github.com/qa-guru/selenoid_selenium_playwright_tests) | Примеры тестов (Java, JS, TS, Python) |

Локальная копия в монорепо: `selenoid_selenium_playwright_tests/`.

---

## Файлы в репозитории

| Файл | Описание |
|------|----------|
| `Dockerfile` | база MS Playwright + VNC + npm playwright |
| `launch-headed-browser.js` | headed-режим для ручных UI-сессий |
| `scripts/build.sh` | локальная сборка |
| `scripts/push.sh` | multi-arch push в Docker Hub |
