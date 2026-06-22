const express = require('express');
const app = express();

// get the port from env variable
const PORT = process.env.PORT || 5001;

const GOAT = 'L. Messi';

app.use(express.static('dist'));

app.get('/health', (req, res) => {
  res.send('ok');
});

app.get('/goat', (req, res) => {
  res.send(GOAT);
});

const start = async () => {
  await app.listen(PORT);
  console.log(`server started on port ${PORT}`);
};

if (require.main === module) {
  start();
}

module.exports = app;
