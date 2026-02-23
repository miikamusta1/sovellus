FROM node:18-alpine

# Luodaan sovelluskansio ja asetetaan oikeudet
RUN mkdir -p /app && chown -R node:node /app
WORKDIR /app

# Kopioidaan package.json ja package-lock.json
COPY --chown=node:node package*.json ./

# Asennetaan riippuvuudet node-käyttäjänä
USER node
RUN npm install --verbose

# Kopioidaan loput tiedostot
COPY --chown=node:node . .

EXPOSE 3000

CMD ["npm", "start"]
