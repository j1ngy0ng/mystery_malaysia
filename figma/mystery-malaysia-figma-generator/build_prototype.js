const fs = require('fs');
const path = require('path');

const root = __dirname;
const screenDirectory = path.join(root, 'screens');
const template = fs.readFileSync(
  path.join(root, 'prototype.template.js'),
  'utf8',
);
const files = fs
  .readdirSync(screenDirectory)
  .filter((name) => name.endsWith('.png'))
  .sort();

if (files.length !== 18) {
  throw new Error(`Expected 18 screenshots, found ${files.length}.`);
}

const images = Object.fromEntries(
  files.map((name) => [
    path.basename(name, '.png'),
    fs.readFileSync(path.join(screenDirectory, name)).toString('base64'),
  ]),
);
const output = template.replace('__SCREEN_DATA__', JSON.stringify(images));
fs.writeFileSync(path.join(root, 'code.js'), output);
console.log(`Built code.js with ${files.length} exact Flutter screenshots.`);
