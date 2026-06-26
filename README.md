# Playwright browser images for Selenoid

Per-browser Docker images for [qa-guru/selenoid](https://github.com/qa-guru/selenoid) — native Playwright via WebSocket `/playwright/{browser}/{version}`.

**Docker Hub:** [`qaguru/playwright-chromium`](https://hub.docker.com/r/qaguru/playwright-chromium), [`playwright-firefox`](https://hub.docker.com/r/qaguru/playwright-firefox), [`playwright-webkit`](https://hub.docker.com/r/qaguru/playwright-webkit), [`playwright-chrome`](https://hub.docker.com/r/qaguru/playwright-chrome), [`playwright-msedge`](https://hub.docker.com/r/qaguru/playwright-msedge)

> Hub — отдельный бинарник [`qaguru/selenoid`](https://hub.docker.com/r/qaguru/selenoid). Здесь только browser nodes.

---

## Образы

| Docker image | Playwright browser | URL-пример |
|---|---|---|
| `qaguru/playwright-chromium` | Chromium | `/playwright/playwright-chromium/1.61.1` |
| `qaguru/playwright-firefox` | Firefox | `/playwright/firefox/1.61.1` |
| `qaguru/playwright-webkit` | WebKit | `/playwright/playwright-webkit/1.61.1` |
| `qaguru/playwright-chrome` | Google Chrome | `/playwright/chrome/1.61.1` |
| `qaguru/playwright-msedge` | Microsoft Edge | `/playwright/playwright-msedge/1.61.1` |

Каждый образ — self-contained node: Xvfb, VNC, `launchServer` через `/opt/playwright/entrypoint.sh`. Hub передаёт env (`ENABLE_VNC`, `ENABLE_VIDEO`, `PW_HEADLESS`, …) и использует `ENTRYPOINT` образа.

---

## Структура репозитория

```
playwright-image/
├── shared/                  # entrypoint, server.cjs, VNC helpers
├── playwright-chromium/
├── playwright-firefox/
├── playwright-webkit/
├── playwright-chrome/
└── playwright-msedge/
```

---

## Pull

```bash
docker pull qaguru/playwright-chromium:1.61.1
docker pull qaguru/playwright-firefox:1.61.1
docker pull qaguru/playwright-webkit:1.61.1
docker pull qaguru/playwright-chrome:1.61.1    # linux/amd64 only
docker pull qaguru/playwright-msedge:1.61.1    # linux/amd64 only
```

| Browser | linux/arm64 | linux/amd64 |
|---|---|---|
| chromium, firefox, webkit | ✅ | ✅ |
| chrome, msedge | ❌ | ✅ |

---

## Сборка

```bash
chmod +x scripts/build.sh scripts/push.sh

# один браузер
./scripts/build.sh chromium 1.61.1

# все браузеры
./scripts/build.sh all 1.61.1
```

## Публикация

```bash
docker login
./scripts/push.sh all 1.61.1
```

Тег: `<playwright-version>` (например `1.61.1`).

---

## browsers.json

```json
{
  "playwright-chromium": {
    "default": "1.61.1",
    "versions": {
      "1.61.1": {
        "image": "qaguru/playwright-chromium:1.61.1",
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

WebDriver `chrome` / `firefox` и Playwright `chrome` / `firefox` — разные ключи в каталоге:

- WebDriver: `chrome`, `firefox`
- Playwright: `playwright-chromium`, `playwright-firefox`, `playwright-webkit`, `playwright-chrome` (alias URL `/playwright/chrome/…`), `playwright-msedge`

---

## Контракт hub ↔ образ

Hub передаёт env (см. `playwright_docker.go`):

| Env | Назначение |
|---|---|
| `ENABLE_VNC` | x11vnc на :5900 |
| `ENABLE_VIDEO` | Xvfb для video-recorder sidecar |
| `SCREEN_RESOLUTION` | разрешение Xvfb |
| `PW_PORT` | порт run-server (обычно 3000) |
| `PW_HEADLESS` | headless для run-server |
| `MANUAL_SESSION` | headed launcher для UI |

Пути в образе:

| Путь | Назначение |
|---|---|
| `/opt/playwright/entrypoint.sh` | старт Xvfb / VNC / server |
| `/opt/playwright/server.cjs` | `browserType.launchServer()` |
| `/opt/playwright/launch-headed-browser.js` | ручные VNC-сессии в UI |

---

## Связанные репозитории

| Репозиторий | Роль |
|---|---|
| [qa-guru/playwright-image](https://github.com/qa-guru/playwright-image) | **этот репозиторий** |
| [qa-guru/selenoid](https://github.com/qa-guru/selenoid) | Hub, WebSocket `/playwright/...` |
| [qa-guru/selenoid-ui](https://github.com/qa-guru/selenoid-ui) | UI |
| [qa-guru/selenoid_selenium_playwright_tests](https://github.com/qa-guru/selenoid_selenium_playwright_tests) | Примеры тестов |
