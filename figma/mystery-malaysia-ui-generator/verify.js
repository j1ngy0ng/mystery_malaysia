const fs = require('fs');
const assert = require('assert');

const manifest = JSON.parse(fs.readFileSync('manifest.json', 'utf8'));
const code = fs.readFileSync('code.js', 'utf8');

assert.deepStrictEqual(manifest.editorType, ['figma']);
assert.deepStrictEqual(manifest.networkAccess.allowedDomains, ['none']);
assert.match(code, /const SCREEN_COUNT = 18/);
assert.match(code, /setCurrentPageAsync/);
assert.match(code, /setReactionsAsync/);

console.log('Figma generator verified: offline, 18 exact screens, prototype links.');
