FROM node:18-alpine

# Luodaan kansio ja asetetaan oikeudet node-käyttäjälle
RUN mkdir -p /app && chown node:node /app
WORKDIR /app

# Kopioidaan package.json ja package-lock.json node-käyttäjän omistamaksi
COPY --chown=node:node package*.json ./

RUN chown -R node:node /app
RUN chmod -R 755 /app

# Asennetaan riippuvuudet node-käyttäjänä
RUN sudo npm ci --verbose

USER node

# Kopioidaan loput tiedostot node-käyttäjän omistamaksi
COPY --chown=node:node . .

EXPOSE 3000

CMD ["npm", "start"]
