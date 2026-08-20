const SCREEN_COUNT = 18;
const SCREEN_IMAGES = __SCREEN_DATA__;
const WIDTH = 390;
const HEIGHT = 844;

const SCREEN_META = [
  ['welcome', '01-welcome', '01 · Welcome'],
  ['signIn', '02-sign-in', '02 · Sign in'],
  ['register', '03-register', '03 · Create account'],
  ['home', '04-home', '04 · Travel home'],
  ['builder', '05-build-mystery', '05 · Build your mystery'],
  ['picks', '06-mystery-picks', '06 · Generated mystery picks'],
  ['preview', '07-mission-preview', '07 · Mystery preview'],
  ['previewActions', '07b-mission-preview-actions', '07B · Preview stops and actions'],
  ['missions', '08-missions', '08 · My missions'],
  ['active', '09-active-mission', '09 · Active mission'],
  ['clue', '10-clue', '10 · Mystery clue'],
  ['revealed', '11-destination-revealed', '11 · Destination revealed'],
  ['passport', '12-passport', '12 · Digital passport'],
  ['diary', '13-diary', '13 · Travel diary'],
  ['crew', '14-crew', '14 · Collaborative travel'],
  ['lobby', '15-shared-lobby', '15 · Shared mission lobby'],
  ['notifications', '16-notifications', '16 · Notifications'],
  ['profile', '17-profile', '17 · Profile'],
];

const NAV = [
  [0, 754, 78, 90, 'home', 'Home tab'],
  [78, 754, 78, 90, 'missions', 'Mission tab'],
  [156, 754, 78, 90, 'passport', 'Passport tab'],
  [234, 754, 78, 90, 'crew', 'Crew tab'],
  [312, 754, 78, 90, 'profile', 'Profile tab'],
];

const HOTSPOTS = {
  welcome: [
    [18, 662, 354, 70, 'signIn', 'Start the adventure'],
    [85, 734, 220, 54, 'home', 'Explore the UI demo'],
  ],
  signIn: [
    [0, 0, 60, 58, 'welcome', 'Back'],
    [18, 418, 354, 68, 'home', 'Sign in'],
    [18, 532, 354, 70, 'register', 'Create an account'],
  ],
  register: [
    [0, 0, 60, 58, 'signIn', 'Back'],
    [18, 646, 354, 74, 'home', 'Create my account'],
  ],
  home: [
    [312, 8, 74, 72, 'notifications', 'Notifications'],
    [18, 226, 354, 338, 'builder', 'Plan from my location'],
    ...NAV,
  ],
  builder: [
    [0, 0, 60, 58, 'home', 'Back'],
    [16, 766, 358, 76, 'picks', 'Generate mysterious missions'],
  ],
  picks: [
    [0, 0, 60, 58, 'builder', 'Back'],
    [18, 348, 354, 304, 'preview', 'Select the first mystery'],
    [18, 660, 354, 184, 'preview', 'Select another mystery'],
  ],
  preview: [
    [0, 0, 60, 58, 'picks', 'Close preview'],
    [0, 620, 390, 224, 'previewActions', 'Continue through destination previews'],
  ],
  previewActions: [
    [0, 0, 390, 86, 'preview', 'Back to mission briefing'],
    [18, 688, 354, 70, 'active', 'Choose this mission'],
    [18, 758, 354, 70, 'lobby', 'Make it a shared mission'],
  ],
  missions: [
    [18, 350, 354, 154, 'active', 'Resume paused mission'],
    [18, 512, 354, 154, 'active', 'Start saved mission'],
    [18, 670, 354, 84, 'active', 'Open active mission'],
    ...NAV,
  ],
  active: [
    [0, 0, 60, 58, 'missions', 'Back to missions'],
    [18, 246, 354, 300, 'revealed', 'Simulate automatic arrival'],
    [18, 678, 174, 62, 'clue', 'View clue'],
  ],
  clue: [
    [0, 0, 60, 58, 'active', 'Back'],
    [18, 624, 354, 62, 'clue', 'Request one additional hint'],
    [18, 686, 354, 66, 'active', 'Back to location verification'],
  ],
  revealed: [
    [0, 0, 60, 58, 'active', 'Back to mission'],
    [18, 766, 354, 78, 'clue', 'Continue to next clue'],
  ],
  passport: [
    [18, 648, 354, 106, 'diary', 'Open travel diary'],
    ...NAV,
  ],
  diary: [
    [0, 0, 60, 58, 'passport', 'Back to passport'],
    [18, 222, 354, 166, 'diary', 'Choose eligible completed mission'],
    [18, 458, 354, 84, 'diary', 'Open saved memory'],
  ],
  crew: [
    [18, 302, 354, 102, 'lobby', 'Open shared mission'],
    [194, 564, 166, 68, 'lobby', 'Accept invitation'],
    [18, 674, 354, 62, 'builder', 'Generate a mission to share'],
    ...NAV,
  ],
  lobby: [
    [0, 0, 60, 58, 'crew', 'Back to crew'],
    [258, 244, 112, 58, 'lobby', 'Invite traveller'],
    [194, 772, 180, 70, 'active', 'Start shared mission'],
  ],
  notifications: [
    [0, 0, 60, 58, 'home', 'Back to home'],
    [18, 64, 354, 126, 'crew', 'Open mission invitation'],
  ],
  profile: [
    [312, 8, 74, 72, 'profile', 'Edit profile'],
    [18, 720, 354, 42, 'welcome', 'Sign out'],
    ...NAV,
  ],
};

function base64Bytes(input) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  const lookup = new Uint8Array(256);
  for (let index = 0; index < alphabet.length; index++) {
    lookup[alphabet.charCodeAt(index)] = index;
  }
  const output = new Uint8Array(Math.floor(input.length * 3 / 4));
  let buffer = 0;
  let bits = 0;
  let offset = 0;
  for (let index = 0; index < input.length; index++) {
    const code = input.charCodeAt(index);
    if (code === 61) break;
    buffer = (buffer << 6) | lookup[code];
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      output[offset++] = (buffer >> bits) & 255;
    }
  }
  return output.slice(0, offset);
}

function screenshotFrame(meta, index) {
  const [id, imageName, displayName] = meta;
  const frame = figma.createFrame();
  frame.name = displayName;
  frame.resize(WIDTH, HEIGHT);
  frame.x = (index % 5) * 470;
  frame.y = Math.floor(index / 5) * 940;
  frame.fills = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
  frame.clipsContent = true;
  frame.cornerRadius = 24;

  const image = figma.createImage(base64Bytes(SCREEN_IMAGES[imageName]));
  const render = figma.createRectangle();
  render.name = 'Pixel-accurate Flutter render';
  render.resize(WIDTH, HEIGHT);
  render.fills = [{ type: 'IMAGE', imageHash: image.hash, scaleMode: 'FILL' }];
  render.locked = true;
  frame.appendChild(render);
  return [id, frame];
}

async function connect(source, target, values) {
  const [x, y, width, height, targetId, description] = values;
  const hotspot = figma.createRectangle();
  hotspot.name = `Hotspot · ${description} → ${targetId}`;
  hotspot.x = x;
  hotspot.y = y;
  hotspot.resize(width, height);
  hotspot.fills = [
    {
      type: 'SOLID',
      color: { r: 1, g: 1, b: 1 },
      opacity: 0.001,
    },
  ];
  hotspot.strokes = [];
  hotspot.description = description;
  source.appendChild(hotspot);

  const action = {
    type: 'NODE',
    destinationId: target.id,
    navigation: 'NAVIGATE',
    transition: {
      type: 'DISSOLVE',
      easing: { type: 'EASE_OUT' },
      duration: 0.18,
    },
    preserveScrollPosition: false,
  };
  await hotspot.setReactionsAsync([
    { trigger: { type: 'ON_CLICK' }, action, actions: [action] },
  ]);
}

async function main() {
  if (Object.keys(SCREEN_IMAGES).length !== SCREEN_COUNT) {
    throw new Error(`Expected ${SCREEN_COUNT} screenshots.`);
  }

  const page = figma.createPage();
  page.name = `Mystery Malaysia · exact UI prototype`;
  await figma.setCurrentPageAsync(page);

  const frames = {};
  SCREEN_META.forEach((meta, index) => {
    const [id, frame] = screenshotFrame(meta, index);
    frames[id] = frame;
  });

  for (const [sourceId, hotspots] of Object.entries(HOTSPOTS)) {
    for (const values of hotspots) {
      const target = frames[values[4]];
      if (!target) throw new Error(`Missing target ${values[4]}`);
      await connect(frames[sourceId], target, values);
    }
  }

  figma.currentPage.selection = [frames.home];
  figma.viewport.scrollAndZoomIntoView([frames.home]);
  figma.notify('Mystery Malaysia: 18 exact Flutter screens with working prototype links created.');
  figma.closePlugin('Done — select Home and click Present to test the flow.');
}

main().catch((error) => {
  figma.closePlugin(`Could not generate prototype: ${error.message || error}`);
});
