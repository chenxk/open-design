FROM node:24-bookworm-slim

WORKDIR /app

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV NODE_ENV=production
ENV OD_PORT=7456
ENV OD_DATA_DIR=.od

RUN corepack enable

COPY . .

RUN pnpm install --frozen-lockfile \
  && pnpm run build

EXPOSE 7456

VOLUME ["/app/.od"]

CMD ["node", "apps/daemon/cli.js", "--no-open", "--port", "7456"]
