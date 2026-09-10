# Stage 1: install deps and run unit tests (integration tests need Mongo; they run in CI, not here)
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx jest tests/unit --ci --passWithNoTests

# Stage 2: lean runtime image, no dev tooling, non-root user
FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app .
RUN addgroup -S app && adduser -S app -G app && chown -R app:app /app
USER app
EXPOSE 8080
CMD ["node", "server.js"]
