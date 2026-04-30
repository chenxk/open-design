FROM node:24-bookworm-slim

WORKDIR /app

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV NODE_ENV=production
ENV OD_PORT=7456
ENV OD_DATA_DIR=.od

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && ln -sf /usr/bin/python3 /usr/bin/python \
  && rm -rf /var/lib/apt/lists/*

RUN corepack enable

COPY . .

RUN pnpm install --frozen-lockfile \
  && pnpm run build

EXPOSE 7456

VOLUME ["/app/.od"]

CMD ["node", "apps/daemon/cli.js", "--no-open", "--port", "7456"]
