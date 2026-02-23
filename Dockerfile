# 1. Buildivaihe: Asennetaan riippuvuudet
FROM node:18-alpine AS builder
WORKDIR /app

# Kopioidaan package.json ja package-lock.json
COPY package*.json ./

# Asennetaan riippuvuudet
RUN npm ci

# Kopioidaan loput tiedostot (esim. src/, public/, jne.)
COPY . .

# 2. Paketointivaihe: Luodaan kevyempi image suoritusta varten
FROM node:18-alpine
WORKDIR /app

# Kopioidaan node_modules builder-vaiheesta
COPY --from=builder /app/node_modules ./node_modules

# Kopioidaan package.json ja package-lock.json
COPY --from=builder /app/package*.json ./

# Kopioidaan sovelluksen lähdekoodi
COPY --from=builder /app/ .

# Altista portti
EXPOSE 3000

# Käynnistetään sovellus
CMD ["npm", "start"]
