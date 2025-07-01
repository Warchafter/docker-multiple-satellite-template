# ── Stage 1: L’Alchimiste Frontend ────────────────────────────────────
FROM node:lts-alpine AS l_alchimiste_ssr
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# Bring in the source and forge the static site
COPY . .
RUN npm run build # outputs to /app/dist

# ── Stage 2: Le Spectre ─────────────────────────────────────
FROM node:lts-alpine AS le_spectre

WORKDIR /app

COPY --from=l_alchimiste_ssr /app/dist ./dist
COPY --from=l_alchimiste_ssr /app/node_modules ./node_modules
COPY --from=l_alchimiste_ssr /app/package.json ./package.json


ENV HOST=0.0.0.0
ENV PORT=4321
EXPOSE 4321

CMD ["node", "/dist/server/entry.mjs"]
