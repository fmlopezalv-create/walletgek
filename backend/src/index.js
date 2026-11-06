require('dotenv').config();
const app = require('./app');
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`API walletgek escuchando en http://localhost:${PORT}`);
});
