FROM node:lts-alpine3.19 AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
WORKDIR /usr/src/app
RUN corepack enable
ENV PORT 3000
EXPOSE $PORT

FROM base AS install
# Create a temporary directory to store the dev dependencies
RUN mkdir -p /temp/dev
COPY package*.json pnpm-lock.yaml /temp/dev/
RUN cd /temp/dev && pnpm install --frozen-lockfile

# Create a temporary directory to store the production dependencies
RUN mkdir -p /temp/prod
COPY package*.json pnpm-lock.yaml /temp/prod/
RUN cd /temp/prod && pnpm install --prod --frozen-lockfile

# Build the app
FROM base AS builder
COPY --from=install /temp/dev/node_modules node_modules
COPY . .
RUN npm run build

# Run development mode
FROM base AS dev
COPY --from=install /temp/dev/node_modules node_modules
COPY . .
ENV NODE_ENV=development
USER node
CMD [ "pnpm", "run", "dev" ]

# Run production mode
FROM base AS prod
COPY --from=install /temp/prod/node_modules node_modules
COPY --from=install /temp/prod/package*.json .
COPY --from=builder /usr/src/app/build/ .
ENV NODE_ENV=production
USER node
CMD [ "node", "index.js" ]





