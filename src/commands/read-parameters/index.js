const path = require('path');
const fs = require('fs');

const { JSON_ENV_FILE } = process.env;

const toEnvKey = (key) => (
  key.replace(/^\//, '').replace(/\//g, '_').replace( /([a-z])([A-Z])/g, '$1_$2' ).toUpperCase()
);

const main = () => {
  const obj = JSON.parse(fs.readFileSync(JSON_ENV_FILE), 'utf8');
  Object.entries(obj).forEach(([key, value]) => {
    console.log(`export ${toEnvKey(key)}="${value}"`)
  });
};

main();