FROM busybox

MAINTAINER b@tavakalov.ru

WORKDIR /app

VOLUME /app

VOLUME /storage/db

CMD /bin/sh