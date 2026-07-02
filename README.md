# browser-image

Один git-репозиторий [qa-guru/browser-image](https://github.com/qa-guru/browser-image) для Docker-образов браузерных нод Selenoid.

| Папка | Образы | Документация |
|-------|--------|--------------|
| [`playwright/`](playwright/) | `qaguru/playwright-*` | Playwright nodes + `chromium-min` |
| [`webdriver/`](webdriver/) | `qaguru/webdriver-chrome*` | Warm WebDriver + `chrome-min` |

## Быстрый старт

```bash
# Playwright
./playwright/scripts/build.sh chromium 1.61.1
./playwright/scripts/build.sh chromium 1.61.1 min

# WebDriver
./webdriver/scripts/build.sh chrome 148
./webdriver/scripts/build.sh chrome 1.61.1 min
```

Публикация — см. `playwright/README.md` и `webdriver/README.md`. CI: `.github/workflows/`.
