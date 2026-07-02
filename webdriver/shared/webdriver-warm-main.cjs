#!/usr/bin/env node
"use strict";

const { createWarmServer, env } = require("./warm-server.cjs");

const driverBase = env("WEBDRIVER_URL", "http://127.0.0.1:4444").replace(/\/+$/, "");
const driverRoot = driverBase.endsWith("/wd/hub") ? driverBase : `${driverBase}/wd/hub`;

async function driverFetch(path, init = {}) {
  const response = await fetch(`${driverRoot}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...(init.headers || {}),
    },
  });
  const text = await response.text();
  let body = {};
  if (text) {
    try {
      body = JSON.parse(text);
    } catch (_) {
      body = { raw: text };
    }
  }
  if (!response.ok) {
    const message = body.value?.message || body.message || text || response.statusText;
    throw new Error(message);
  }
  return body;
}

async function createSession() {
  const payload = {
    capabilities: {
      alwaysMatch: {
        browserName: "chrome",
        "goog:chromeOptions": {
          args: ["--no-sandbox", "--disable-dev-shm-usage", "--disable-gpu"],
        },
      },
    },
  };
  const body = await driverFetch("/session", {
    method: "POST",
    body: JSON.stringify(payload),
  });
  const sessionId = body.value?.sessionId || body.sessionId;
  if (!sessionId) {
    throw new Error("chromedriver did not return sessionId");
  }
  return sessionId;
}

async function deleteSession(sessionId) {
  if (!sessionId) {
    return;
  }
  await driverFetch(`/session/${sessionId}`, { method: "DELETE" }).catch(() => {});
}

async function main() {
  await waitForChromedriver();

  let webdriverSessionId = await createSession();
  console.log(`[webdriver-warm] session=${webdriverSessionId}`);

  const warm = createWarmServer({
    protocol: "webdriver",
    async getStatus() {
      return {
        webdriverUrl: driverRoot,
        webdriverSessionId,
      };
    },
    async goto(url) {
      await driverFetch(`/session/${webdriverSessionId}/url`, {
        method: "POST",
        body: JSON.stringify({ url }),
      });
      return { webdriverSessionId };
    },
    async reset() {
      await driverFetch(`/session/${webdriverSessionId}/cookie`, { method: "DELETE" }).catch(() => {});
      await driverFetch(`/session/${webdriverSessionId}/url`, {
        method: "POST",
        body: JSON.stringify({ url: "about:blank" }),
      });
      return { webdriverSessionId };
    },
  });

  await warm.start();

  const shutdown = async () => {
    await warm.stop();
    await deleteSession(webdriverSessionId);
    process.exit(0);
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

async function waitForChromedriver() {
  const deadline = Date.now() + 60_000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`${driverRoot}/status`);
      if (response.ok) {
        return;
      }
    } catch (_) {
      /* retry */
    }
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  throw new Error(`chromedriver is not ready at ${driverRoot}`);
}

main().catch((error) => {
  console.error("[webdriver-warm] fatal:", error);
  process.exit(1);
});
