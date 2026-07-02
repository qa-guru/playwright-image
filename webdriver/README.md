# WebDriver browser images

Часть репозитория [`browser-image`](../README.md) (`webdriver/`). Playwright-образы — в [`playwright/`](../playwright/).

Warm WebDriver browser nodes for [warm-pool-orchestrator](../warm-pool-orchestrator/README.md).

Long-lived Chrome slots with HTTP warm API (`/warm/goto`, `/warm/reset`, `/warm/video/*`) and always-on chromedriver.

## Images

| Image | Base | Ports | Use case |
|-------|------|-------|----------|
| `qaguru/webdriver-chrome:148` | `twilio/selenoid:chrome_stable_148` | `4444` WebDriver, `8080` warm API, `5900` VNC | warm pool |
| `qaguru/webdriver-chrome:149-min` | CfT `149.0.7827.55` on `ubuntu:noble` | `4444` WebDriver | headless CI (≈ PW `1.61.1-min`), linux/amd64 |
| `qaguru/webdriver-chrome:148-min` | CfT `148.0.7778.96` on `ubuntu:noble` | `4444` WebDriver | headless CI (≈ PW `1.60.0-min`), linux/amd64 |

`chrome-min` — только chromedriver, без VNC / warm API / Xvfb. Версии CfT совпадают с Chromium в `qaguru/playwright-chromium:<pw>-min`.

## Build

```bash
chmod +x scripts/build.sh scripts/push.sh

# warm pool (VNC + warm API)
./scripts/build.sh chrome 148

# chrome-min (headless CI)
./scripts/build.sh chrome 1.61.1 min   # -> qaguru/webdriver-chrome:149-min
./scripts/build.sh chrome 1.60.0 min   # -> qaguru/webdriver-chrome:148-min
./scripts/build.sh chrome all min      # обе min-версии

# можно передать major или полный CfT-тег
./scripts/build.sh chrome 149 min
```

Warm-сборка копирует shared `warm-api` из `warm-pool-orchestrator/warm-api` перед build.

`Dockerfile.min.scratch` — канон для min (как `playwright-chromium/Dockerfile.min.scratch`).  
`Dockerfile.min` — запасной вариант на `twilio/selenoid:chrome_stable_<major>`.

## Publish

```bash
docker login
./scripts/push.sh chrome 148              # warm
./scripts/push.sh chrome 1.61.1 min     # 149-min
./scripts/push.sh chrome 1.60.0 min     # 148-min
./scripts/push.sh all 148               # warm + обе min
```

CI: `.github/workflows/publish-webdriver.yml` — тег `chrome-<major>` (warm), `workflow_dispatch` для min.

## Run (single slot)

```bash
docker run -d --name warm-chrome-1 \
  --network warm-pool \
  -p 4444:4444 \
  -p 8080:8080 \
  -e WARM_SLOT_ID=pool-chrome-1 \
  -e WARM_SESSION_ID=pool-chrome-1 \
  -v "$(pwd)/video:/data/video" \
  qaguru/webdriver-chrome:148
```

## Run (chrome-min, headless)

```bash
docker run -d --name chrome-min \
  -p 4444:4444 \
  --shm-size=2g \
  qaguru/webdriver-chrome:149-min
```

## Warm API

Same contract as Playwright warm slots — see [warm-pool-orchestrator/README.md](../warm-pool-orchestrator/README.md#warm-api-contract).

```bash
curl -sf http://127.0.0.1:8080/warm/status | jq .
curl -sf -X POST http://127.0.0.1:8080/warm/goto \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com/login.html"}'
curl -sf -X POST http://127.0.0.1:8080/warm/video/start \
  -H 'Content-Type: application/json' \
  -d '{"sessionId":"pool-chrome-1"}'
curl -sf -X POST http://127.0.0.1:8080/warm/video/stop
```

Video files: `{sessionId}-{timestamp}.mp4` in `/data/video` (mount from host).

## browsers.json

```json
{
  "chrome": {
    "default": "148.0",
    "versions": {
      "149.0-min": {
        "image": "qaguru/webdriver-chrome:149-min",
        "port": "4444",
        "path": "/",
        "tmpfs": { "/tmp": "size=512m" }
      },
      "148.0-min": {
        "image": "qaguru/webdriver-chrome:148-min",
        "port": "4444",
        "path": "/",
        "tmpfs": { "/tmp": "size=512m" }
      }
    }
  }
}
```

## Test connection

```bash
export SELENOID_URL=http://127.0.0.1:4444/wd/hub
./gradlew test --tests 'tests.LoginTests.successfulAuthorizationTest' \
  -Denv=ci -DbrowserVersion=148.0
```

For attach to the slot's pre-created session (fastest path), use orchestrator reserve + `-Dwarm.attach=true` (see orchestrator README).
