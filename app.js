const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.json({
    message: "Hello The App Working Very Well From Docker 🐳",
    version: "1.0.0"
  });
});

app.listen(port, () => {
  console.log(`App running on http://localhost:${port}`);
});