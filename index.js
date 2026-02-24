const express = require('express');
const { Pool } = require('pg');
const app = express();
const port = 3000;

// Tietokantayhteyden asetukset (samat kuin docker-compose.yml:ssä)
const pool = new Pool({
  user: 'postgres',
  host: 'db',  // Docker Composen palvelimen nimi
  database: 'mydb',
  password: 'postgres',
  port: 5432,
});

// Luo taulu, jos sitä ei ole olemassa
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

// Lisää testiviesti tietokantaan
async function insertTestMessage() {
  try {
    await pool.query(
      'INSERT INTO messages (content) VALUES ($1) ON CONFLICT DO NOTHING',
      ['Tervehdys tietokannasta!']
    );
    console.log('Testiviesti lisätty.');
  } catch (err) {
    console.error('Virhe viestin lisäämisessä:', err);
  }
}

// Hae kaikki viestit tietokannasta
async function getMessages() {
  const res = await pool.query('SELECT * FROM messages');
  return res.rows;
}

// Reitti, joka hakee ja näyttää viestit
app.get('/', async (req, res) => {
  try {
    const messages = await getMessages();
    res.send(`
      <h1>Viestit tietokannasta:</h1>
      <ul>
        ${messages.map(msg => `<li>${msg.content}</li>`).join('')}
      </ul>
    `);
  } catch (err) {
    console.error('Virhe viestien hakemisessa:', err);
    res.status(500).send('Virhe tietokannassa.');
  }
});

// Käynnistä sovellus
app.listen(port, async () => {
  await initializeDatabase();
  await insertTestMessage();
  console.log(`Sovellus kuuntelee porttia ${port}`);
});
