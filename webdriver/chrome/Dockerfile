ARG CHROME_VERSION=148
FROM twilio/selenoid:chrome_stable_${CHROME_VERSION}

USER root

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl \
        dumb-init \
        ffmpeg \
        nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/warm/api /data/video /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix

COPY shared/common.sh shared/entrypoint.sh /opt/warm/
COPY shared/webdriver-warm-main.cjs /opt/warm/api/
COPY warm-api/warm-server.cjs warm-api/video-recorder.cjs /opt/warm/api/

RUN chmod +x /opt/warm/entrypoint.sh

ENV WARM_PORT=8080 \
    WARM_VIDEO_DIR=/data/video \
    WARM_VIDEO=true \
    WEBDRIVER_URL=http://127.0.0.1:4444 \
    DISPLAY=:99 \
    DISPLAY_NUM=99 \
    SCREEN_RESOLUTION=1920x1080x24

EXPOSE 4444 8080 5900

HEALTHCHECK --interval=5s --timeout=3s --start-period=45s --retries=8 \
    CMD curl -sf http://127.0.0.1:8080/warm/status >/dev/null || exit 1

LABEL org.opencontainers.image.title="qaguru/webdriver-chrome" \
      org.opencontainers.image.source="https://github.com/qa-guru/browser-image" \
      io.qaguru.browser="chrome" \
      io.qaguru.protocol="webdriver" \
      io.qaguru.warm="true"

ENTRYPOINT ["dumb-init", "--", "/opt/warm/entrypoint.sh"]
