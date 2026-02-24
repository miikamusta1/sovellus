# sovellus
Ohjelmistotuotannon jatkokurssin harjoitustyö

# Sovelluksen pystyttäminen alusta loppuun

Tämä ohjeistus auttaa sinua pystyttämään sovelluksen paikallisesti, rakentamaan Docker-imagin, julkaisemaan sen Docker Hubiin ja deployaamaan palvelimelle.

---

## Edellytykset

Varmista, että sinulla on asennettuna:
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Node.js](https://nodejs.org/) (paikallista kehitystä varten)
- Git

---

## 1. Projektin luominen ja paikallinen kehitys

### 1.1 Aloita uusi projekti
bash
mkdir sovellus
cd sovellus
npm init -y


### 1.2 Asenna riippuvuudet
bash
npm install express pg


### 1.3 Luo `index.js`
Luo tiedosto `index.js` ja lisää seuraava koodi:

javascript
const express = require('express');
const { Pool } = require('pg');
const app = express();
const port = 3000;

const pool = new Pool({
  user: 'postgres',
  host: 'db',
  database: 'mydb',
  password: 'postgres',
  port: 5432,
});

async function initializeDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        content TEXT NOT NULL
      )
    `);
    console.log('Tietokantataulu luotu tai olemassa.');
  } catch (err) {
    console.error('Virhe taulun luomisessa:', err);
  }
}

async function insertTestMessage() {
  try {
    await pool.query(
      'INSERT INTO messages (content) VALUES (\$1) ON CONFLICT DO NOTHING',
      ['Tervehdys tietokannasta!']
    );
    console.log('Testiviesti lisätty.');
  } catch (err) {
    console.error('Virhe viestin lisäämisessä:', err);
  }
}

async function getMessages() {
  const res = await pool.query('SELECT * FROM messages');
  return res.rows;
}

app.get('/', async (req, res) => {
  try {
    const messages = await getMessages();
    res.send(`
      <h1>Viestit tietokannasta:</h1>
      <ul>
        \${messages.map(msg => `<li>${msg.content}</li>`).join('')}
      </ul>
    `);
  } catch (err) {
    console.error('Virhe viestien hakemisessa:', err);
    res.status(500).send('Virhe tietokannassa.');
  }
});

app.listen(port, async () => {
  await initializeDatabase();
  await insertTestMessage();
  console.log(`Sovellus kuuntelee porttia ${port}`);
});


### 1.4 Päivitä `package.json`
Varmista, että `package.json` sisältää seuraavat skriptit ja riippuvuudet:

json
{
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.3"
  }
}


### 1.5 Luo `Dockerfile`
dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000
CMD ["npm", "start"]


### 1.6 Luo `docker-compose.yml`
yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgres://postgres\:postgres@db:5432/mydb
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:


---

## 2. Docker-imagin rakentaminen ja julkaiseminen

### 2.1 Rakenna Docker-image paikallisesti
bash
docker compose build


### 2.2 Testaa sovellus paikallisesti
bash
docker compose up -d

Avaa selain: [http://localhost:3000](http://localhost:3000)

### 2.3 Kirjaudu Docker Hubiin
bash
docker login


### 2.4 Nimeä ja puske image Docker Hubiin
bash
docker tag sovellus-app miikamusta/sovellusrepo\:latest
docker push miikamusta/sovellusrepo\:latest


---

## 3. Sovelluksen deployaus palvelimelle

### 3.1 Kirjaudu palvelimelle
bash
ssh ubuntu@193.166.24.90


### 3.2 Luo kansio sovellukselle
bash
mkdir -p /home/ubuntu/app
cd /home/ubuntu/app


### 3.3 Luo `docker-compose.yml` palvelimelle
yaml
version: '3.8'

services:
  app:
    image: docker.io/miikamusta/sovellusrepo\:latest
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgres://postgres\:postgres@db:5432/mydb
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:


### 3.4 Vedä ja käynnistä sovellus
bash
docker compose pull
docker compose up -d


### 3.5 Tarkista, että sovellus toimii
bash
curl http://localhost:3000

Odottamasi vastaus:
html
<h1>Viestit tietokannasta:</h1>
<ul>
  <li>Tervehdys tietokannasta!</li>
</ul>


### 4. Päivitä sovellus

1. Tee muutokset paikallisesti.
2. Rakenna ja puske uusi image:
   bash
   docker compose build
   docker push miikamusta/sovellusrepo\:latest
   
3. Päivitä sovellus palvelimella:
   bash
   docker compose pull
   docker compose up -d
   

---

## 5. GitHub Actions (automaattinen deployaus)

### 5.1 Luo `.github/workflows/docker-build-push.yml`
yaml
name: Docker Build and Push

on:
  push:
    branches: [ "main" ]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: miikamusta/sovellusrepo\:latest


### 5.2 Lisää salaisuudet GitHub-repositorioon
- Mene **Settings → Secrets → Actions** ja lisää:
  - `DOCKER_HUB_USERNAME`: Docker Hub -käyttäjänimesi
  - `DOCKER_HUB_TOKEN`: [Docker Hub Access Token](https://hub.docker.com/settings/security)

---

## Valmis! 🎉
Nyt sovelluksesi on käynnissä ja näyttää tietokannan sisällön.
