# Stage 1: build the static bundle. VITE_API_PATH is empty because the
# frontend and API share one hostname behind the ingress (same-origin /api).
FROM node:20-alpine AS build
WORKDIR /app
ARG VITE_API_PATH=""
ENV VITE_API_PATH=$VITE_API_PATH
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: serve with nginx, SPA fallback to index.html
FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
