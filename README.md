# Mystery Malaysia

An interactive mobile travel mystery game built with Flutter.

## Local configuration

1. Open `.env.local.json`.
2. Replace the two placeholder values with the Supabase project URL and
   publishable key from the Supabase **Connect** panel.
3. Start Android with:

   ```powershell
   .\tool\run_android.cmd
   ```

The local configuration file is ignored by Git. Never put a Supabase secret
key, service-role key, or Gemini key in the Flutter project. `GEMINI_API_KEY`
belongs in Supabase Edge Function secrets.

To link the repository, apply migrations and deploy `generate-mission`, run:

```powershell
.\tool\login_supabase.cmd
.\tool\deploy_supabase.cmd
```

Complete the browser approval and enter its verification code in the login
window. Deployment may also request the project database password. Neither
credential should be pasted into source code or chat.

## UI prototype

The current build implements a bright Malaysia-tourism experience across all six modules:

- authentication and profile;
- AI mission discovery and recommendation previews;
- active mission map, Hot & Cold guidance, pause/resume and arrival reveal;
- one canonical clue with one optional additional hint;
- digital passport, stamps, achievements, reflections and AI diary;
- direct mission invitations, lobby, readiness and group proximity.

Select **Explore the UI demo** on the welcome screen to enter the shell without
signing in. Database and Gemini actions require an authenticated account.

## Architecture

All implementation must follow [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). It defines feature ownership, dependency boundaries, backend responsibilities, mission state transitions, security rules, and the required source layout.

The UI follows client-side MVC: Views render and forward actions, Controllers
own interaction state, and Models remain independent of Flutter widgets and
external providers. Supabase, Google Maps and Gemini integrations are isolated
under `lib/services/`; Gemini is called only through a protected Supabase Edge
Function.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
