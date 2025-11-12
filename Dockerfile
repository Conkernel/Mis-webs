FROM nginx:alpine

RUN apk add --no-cache nodejs npm iproute2 && npm install -g pm2

WORKDIR /var/www/crawler

COPY crawler/package*.json ./

RUN npm install

COPY web.casa.lan.conf /etc/nginx/conf.d/web.casa.lan.conf

COPY docker/install.sh /var/www/docker/install.sh

COPY zsh/install.sh /var/www/zsh/install.sh

COPY crawler /var/www/crawler/

COPY archy /var/www/archy/

COPY neovim /var/www/neovim/

RUN mkdir -p /var/log/pm2 && chown nginx:nginx /var/log/pm2

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

RUN rm -f /etc/nginx/conf.d/default.conf

RUN chown nginx:nginx /var/www/docker/install.sh

RUN chmod -R 755 /var/www/


ENTRYPOINT ["/entrypoint.sh"]


EXPOSE 80
EXPOSE 3000