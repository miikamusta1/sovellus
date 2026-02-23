# 1. Buildivaihe: Asennetaan riippuvuudet
FROM node:18-alpine AS builder
WORKDIR /app

# Kopioidaan package.json ja package-lock.json
COPY package*.json ./

# Asennetaan riippuvuudet
RUN npm ci --omit=dev

# Kopioidaan loput tiedostot
COPY . .

# Suoritetaan buildaus (jos tarvitaan, esim. React/TypeScript)
# RUN npm run build

# 2. Paketointivaihe: Luodaan kevyempi image suoritusta varten
FROM node:18-alpine
WORKDIR /app

# Kopioidaan vain tarvittavat tiedostot builder-vaiheesta
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/ .

# Käynnistetään sovellus
EXPOSE 3000
CMD ["npm", "start"]
