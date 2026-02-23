# Käytä virallista Node.js-kuvaa pohjana
FROM node:18-alpine

# Aseta työhakemisto
WORKDIR /app

# Kopioi package.json ja package-lock.json
COPY package*.json ./

# Asenna riippuvuudet
USER node
RUN npm install

# Kopioi sovelluksen lähdekoodi
COPY . .

# Altista sovelluksen portti
EXPOSE 3000

# Käynnistä sovellus
CMD ["npm", "start"]
