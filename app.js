const express = require('express');
const app = express();
const port = process.env.PORT || 3000;
const host = process.env.HOST || '0.0.0.0';

app.get('/', (req, res) => {
  const environment = {
    pod: process.env.POD_NAME,
    podIP: process.env.POD_IP,
    node: process.env.NODE_NAME
  };
  const hasClusterInfo = Object.values(environment).some(Boolean);

  res.json({
    message: 'Hello, the app is working very well from Docker',
    version: '1.0.0',
    ...(hasClusterInfo ? { environment } : { environment: 'local-dev' })
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.listen(port, host, () => {
  console.log(`App running on http://${host}:${port}`);
});