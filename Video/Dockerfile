FROM jrottenberg/ffmpeg:6.0-alpine
LABEL authors="Selenium <selenium-developers@googlegroups.com>"
LABEL authors="Happy TestOps <contact@ndviet.org>"

#========================
# Supervisor
#========================
RUN apk update \
  && apk upgrade \
  && apk add --no-cache --update --virtual .build-deps supervisor bash curl jq xset python3 py3-psutil py3-pip \
  && ln -sf python3 /usr/bin/python \
  && rm -rf /tmp/* /var/cache/apk/*

ENV PYTHONUNBUFFERED=1
RUN python3 -m pip install --no-cache --upgrade --no-cache-dir pip urllib3 setuptools requests

#======================================
# Add Supervisor configuration files
#======================================
ENV SE_VIDEO_FOLDER /videos
ENV SE_SESSION_FOLDER /sessions
RUN mkdir -p /opt/bin/
RUN mkdir -p /var/run/supervisor /var/log/supervisor ${SE_VIDEO_FOLDER} ${SE_SESSION_FOLDER}

COPY supervisord.conf /etc
COPY entry_point.sh video.sh session_task.sh video_ready.py /opt/bin/

RUN chmod +x /opt/bin/*
ENTRYPOINT ["/opt/bin/entry_point.sh"]
CMD ["/opt/bin/entry_point.sh"]

ENV DISPLAY_NUM 99
ENV DISPLAY_CONTAINER_NAME selenium
ENV SE_SCREEN_WIDTH 1360
ENV SE_SCREEN_HEIGHT 1020
ENV SE_FRAME_RATE 15
ENV SE_CODEC libx264
ENV SE_PRESET "-preset ultrafast"
ENV FILE_NAME video.mp4
ENV SE_VIDEO_RECORD true
ENV SE_NODE_PORT 5555
ENV DRAIN_AFTER_SESSION_COUNT 0

EXPOSE 9000
