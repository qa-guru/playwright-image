const { chromium, firefox, webkit } = require("playwright");

const browserTypes = { chromium, firefox, webkit };

const pwBrowser = process.env.PW_BROWSER || "chromium";
const browserType = browserTypes[pwBrowser] || chromium;

process.env.DISPLAY = process.env.DISPLAY || ":99";

(async () => {
  const browser = await browserType.launch({ headless: false });
  const page = await browser.newPage();
  await page.goto("about:blank");
  browser.on("disconnected", () => process.exit(0));
})().catch((err) => {
  console.error("Failed to launch headed browser for VNC:", err.message || err);
  process.exit(1);
});
