FROM redis:4.0.1
COPY redis.conf /usr/local/etc/redis/redis.conf
COPY sentinel.conf /usr/local/etc/redis/sentinel.conf
RUN chown redis:redis /usr/local/etc/redis/sentinel.conf
RUN chmod u+w /usr/local/etc/redis/sentinel.conf
EXPOSE 26379 6379
CMD ["/bin/bash", "-c", "redis-server /usr/local/etc/redis/redis.conf && redis-server /usr/local/etc/redis/sentinel.conf --sentinel"]

