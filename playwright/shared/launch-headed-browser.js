const { chromium, firefox, webkit } = require("playwright-core");

const browserTypes = { chromium, firefox, webkit };

const browserTypeName = process.env.PW_BROWSER_TYPE || "chromium";
const browserType = browserTypes[browserTypeName] || chromium;

process.env.DISPLAY = process.env.DISPLAY || ":99";

const launchOptions = { headless: false };
const channel = process.env.PW_BROWSER_CHANNEL;
if (channel) {
  launchOptions.channel = channel;
}

(async () => {
  const browser = await browserType.launch(launchOptions);
  const page = await browser.newPage();
  await page.goto("about:blank");
  browser.on("disconnected", () => process.exit(0));
})().catch((err) => {
  console.error("Failed to launch headed browser for VNC:", err.message || err);
  process.exit(1);
});
