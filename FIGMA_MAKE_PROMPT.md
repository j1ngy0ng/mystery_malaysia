# Mystery Malaysia — Figma Make Prompt

Create a polished, mobile-first interactive travel mystery game called **Mystery Malaysia**. Build it as a fully navigable high-fidelity prototype, not a landing page. The experience should feel adventurous, playful, social, and distinctly Malaysian while remaining easy to understand outdoors on a phone.

## Product concept

Players receive AI-generated mystery missions based on their budget, available time, preferences, group type, location, past activity, and destination popularity. They travel to real destinations, unlock clues, use hints and hot/cold proximity feedback, confirm arrival, collect passport stamps and XP, and generate a reflective travel diary. Players can complete missions alone or collaboratively with friends.

Use realistic Malaysian examples such as Kuala Lumpur, Melaka, Penang, Ipoh, Kota Kinabalu, Kuching, Langkawi, and local food, heritage, nature, and cultural experiences. Use friendly Malaysian English. Keep copy concise and suitable for a mobile game.

## Visual direction

- Mobile canvas: 390 × 844 px, optimized for modern iPhone and Android devices.
- Style: bright tropical adventure, rounded, energetic, welcoming, and youthful without looking childish.
- Primary teal: `#12B8A6`; dark teal: `#087F8C`; pale teal: `#D9FBF5`.
- Mango yellow: `#FFBF3F`; pale mango: `#FFF2C7`.
- Coral: `#FF6B6B`; purple: `#6C4CE6`; sky blue: `#3BAAF2`; success green: `#22C55E`.
- Canvas: `#F7FAFC`; cards: white; primary text: `#172033`; secondary text: `#667085`.
- Typography: Fredoka for bold, playful headings; Nunito for body text and controls.
- Use 8, 12, 16, 24, 32, and 48 px spacing; rounded corners of 16–24 px; pill controls; minimum 48 px touch targets.
- Use soft shadows, tactile cards, colorful progress indicators, cheerful badges, map motifs, dotted travel paths, passport stamps, tropical foliage, stars, and subtle Malaysian architectural or textile-inspired patterns.
- Icons should be simple rounded line icons. Do not use flags as decorative wallpaper and avoid cultural stereotypes.
- Maintain WCAG-friendly contrast, clear hierarchy, large outdoor-readable controls, safe areas, and visible focus/pressed/disabled states.

## Global structure

Use a persistent bottom navigation after sign-in with five destinations:

1. Home
2. Explore
3. Passport
4. Friends
5. Profile

During an active mission, replace the standard navigation with a focused mission HUD and a clear way to pause or exit. Add smooth playful transitions, card lifts on tap, progress celebrations, stamp animations, and subtle haptics where appropriate.

Build reusable components for buttons, inputs, chips, mission cards, clue cards, player avatars, status pills, bottom navigation, top app bars, progress rings, XP bars, stamp tiles, badge tiles, diary cards, modals, snackbars, empty states, skeleton loaders, and error banners. Include variants for default, pressed, selected, disabled, loading, success, warning, and error states.

## Complete screen set and flows

### 1. Onboarding and authentication

- Splash screen with animated compass/map-pin identity and the line “Your next mystery is closer than you think.”
- Three-page onboarding carousel: discover hidden Malaysia, solve clues in the real world, collect memories with friends.
- Welcome screen with Sign in, Create account, and Continue as guest.
- Sign-in form with email, password visibility, remember me, forgot password, social sign-in placeholders, validation, loading, and incorrect-credentials error.
- Registration flow with name, email, password strength, confirm password, terms consent, success state, and email-verification message.
- Forgot-password flow: enter email, confirmation, reset-password form, and success screen.
- Permission primer explaining location, camera, notifications, and photo access before the native permission requests.

### 2. Home and mission discovery

- Home dashboard greeting the player, showing current XP/level, streak, weather/location context, an active-mission card if applicable, a large “Find me a mystery” action, nearby recommendations, friends’ activity, and recent passport stamps.
- If a mission is currently running, place a prominent persistent **Active mission** card at the top of Home. Show mission title, current chapter, progress, elapsed time, participant status when shared, and a primary **Continue mission** button. Add a small active indicator/badge to the Home navigation icon.
- If a mission was paused, replace this with a **Paused mission** card showing where the player stopped, saved timestamp, progress, and primary **Resume mission** plus secondary **Abandon** actions. On the next app launch, show a lightweight “Continue your mystery?” resume sheet before Home, without forcing the player to resume.
- Allow only one active or paused mission at a time. If the player tries to start another, show a dialog offering **Resume current mission**, **Abandon and start new**, or **Cancel**.
- Mission request wizard with playful step progress:
  1. Current location or chosen city.
  2. Available time: under 1 hour, 1–3 hours, half day, full day.
  3. Budget slider and free/low/moderate/premium shortcuts in MYR.
  4. Interests: food, culture, nature, history, art, adventure, shopping, hidden gems.
  5. Group type: solo, couple, family, friends.
  6. Accessibility and travel preferences.
- AI-generating screen with animated route, rotating playful status messages, and Cancel.
- Mission recommendations showing one featured mystery and two alternatives. Each card includes evocative title, concealed destination treatment, city/starting area, duration, budget, difficulty, walking distance, interests, XP reward, accessibility notes, and save/share actions.
- Mission-detail preview with a spoiler-free story hook, preparation checklist, estimated itinerary, reward preview, participant selector, Start mission, and Choose another.
- No-match state with editable constraints and suggested relaxations.
- Location-permission denied state with Open settings and Enter location manually.
- Destination-unavailable state with alternatives.

### 3. Solo active mission

- Mission-start countdown with safety reminder and preparation confirmation.
- Active mission hub showing chapter progress, elapsed time, budget estimate, current clue, hint tokens, and Pause.
- Story/clue screen with strong typography, illustration area, clue text, optional photo/audio clue, Submit answer, and Get a hint.
- Multiple-choice clue, text-answer clue, photo challenge, observation challenge, and QR/check-in challenge variants.
- Hint confirmation sheet showing hint cost or XP impact before revealing escalating hints.
- Map/proximity screen with a stylized map, player location, broad search zone rather than instantly revealing the destination, compass button, and safety-friendly directions.
- Hot/cold proximity screen with four visually distinct stages: cold, warm, hot, and nearby. Use color plus text/icon so state is never communicated by color alone.
- Arrival-confirmation screen using GPS radius, with Confirm arrival, Try again, and “I’m here but GPS is inaccurate.”
- Destination reveal with celebratory animation, destination name, image, cultural/history context, respectful visitor tips, opening information placeholder, and Continue challenge.
- Mission progress timeline showing completed and locked chapters.
- Pause sheet with Resume, Save for later, and Abandon mission.
- Abandon confirmation explaining progress consequences and offering Keep playing.
- Connection-required state that blocks network-dependent gameplay and offers Retry.
- GPS weak/unavailable and clue-answer incorrect states with recovery guidance.
- Mission-complete celebration showing XP, level progress, passport stamp, badges, time, distance, spending reflection, and Continue to reflection.

### 4. Passport, rewards, diary, and progression

- Digital passport overview with player identity, level, total XP, regions visited, stamp count, and a grid/map toggle.
- Passport stamp collection grouped by Malaysian state or territory, with collected, locked, rare, and newly earned states.
- Stamp-detail screen with destination memory, date, mission name, facts, photos, and Share memory.
- Reflection form with mood, favourite moment, what was learned, spending, rating, private notes, and optional photos.
- AI diary-generating state followed by a warm scrapbook-style diary entry combining route, highlights, photos, cultural facts, and reflection. Allow Edit, Regenerate, Save privately, and Share.
- Diary timeline with search, filters, trip cards, private/shared indicators, and empty state.
- Progression dashboard with current level, animated XP bar, weekly activity, completed missions, states explored, distance travelled, badges, streaks, and next milestones.
- Badge gallery and badge-detail modal explaining how each badge is earned.
- Mission history with completed, paused, abandoned, and saved tabs plus filters.
- Treat **Home** as the main return point for the single current active/paused mission. Keep a secondary record under **Profile → Mission history → Paused** so it remains discoverable if the Home card is dismissed. Selecting it opens a mission recap screen with **Resume mission**.
- Level-up celebration overlay and compact XP-earned toast.

### 5. Collaborative missions

- Friends hub showing online friends, invitations, recent group memories, and Create shared mission.
- Create-group flow: select or invite friends, choose group name, privacy, participant limit, and mission constraints.
- Invite screen with searchable friends, QR code, shareable link, and invitation status.
- Incoming invitation detail with host, participants, constraints, expiry, Accept, Decline, and Ask a question.
- Group lobby with player avatars, ready/not-ready states, host controls, mission summary, group chat preview, and Start when everyone is ready.
- Participant status sheet for joined, ready, navigating, disconnected, completed, or left.
- Shared active mission screen using the same gameplay foundations plus team progress, participant positions/status, cooperative clue actions, lightweight reactions, and Help teammate.
- Group decision/poll sheet for choosing an alternative or using a hint.
- Disconnected participant and host-left recovery states.
- Shared completion celebration with team statistics, group stamp, each player’s XP, and Continue to reflections.
- Individual reflection collection status followed by an AI-generated shared diary/scrapbook with participant highlights, photos, quotes, and sharing permissions.

### 6. Profile and settings

- Profile overview with avatar, display name, hometown, interests, level, stats, badges, edit action, and friend code.
- Edit profile with avatar upload, name, bio, interests, accessibility preferences, and Save state.
- Settings grouped into account, privacy, location, notifications, accessibility, language, support, and legal.
- Notification preferences for invitations, mission reminders, friend activity, rewards, and recommendations.
- Privacy controls for profile visibility, location sharing during group missions, diary visibility, friend requests, and data permissions.
- Accessibility controls for larger text, reduced motion, high contrast, colour-safe proximity signals, screen-reader descriptions, and walking considerations.
- Help and safety screen with emergency guidance, responsible exploration reminders, FAQ, report issue, and contact support.
- Log-out confirmation and account-deletion flow with clear destructive styling.

### 7. System and utility states

- Global search for missions, destinations, stamps, diary entries, and friends.
- Notifications inbox with unread/read states and filters.
- Generic loading skeletons, optimistic success, snackbar messages, empty states, maintenance, no internet, server error, timeout, and retry states.
- Permission denied, expired invitation, unavailable mission, already-completed mission, and session-expired dialogs.
- Camera/photo picker bottom sheet and upload progress.
- Share sheet preview for a stamp, diary entry, or group achievement.

## Prototype behavior

Create a coherent clickable happy path:

Splash → onboarding → sign in → Home → mission request wizard → AI generation → recommendation → mission detail → start → clue → hint → map/proximity → arrival → destination reveal → completion → reflection → AI diary → passport.

Also create a collaborative path:

Friends → invitation → group lobby → ready states → shared mission → group completion → individual reflections → shared diary.

All main buttons must work in the prototype. Include Back, Cancel, Close, Pause, Resume, Retry, and error recovery paths. Use realistic sample content rather than lorem ipsum. Populate the prototype with a fictional Kuala Lumpur food-and-heritage mystery while keeping the final destination concealed until arrival.

## Quality bar

The result should look like a cohesive production-ready mobile product with a reusable design system, consistent spacing and typography, no clipped content, no inaccessible colour combinations, and no dead-end screens. Prioritize the core flows visually, but include every screen and state listed above. Keep interactions fun, fast, legible, and safe for players using the app while exploring outdoors.
