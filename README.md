# Mystery Malaysia

An interactive mobile travel mystery game built with Flutter.

## UI prototype

The current build implements a bright Malaysia-tourism experience across all six modules:

- authentication and profile;
- AI mission discovery and recommendation previews;
- active mission map, Hot & Cold guidance, pause/resume and arrival reveal;
- one canonical clue with one optional additional hint;
- digital passport, stamps, achievements, reflections and AI diary;
- direct mission invitations, lobby, readiness and group proximity.

Run the prototype with `flutter run`. Select **Explore the UI demo** on the welcome screen to enter the authenticated shell without connecting external APIs.

## Architecture

All implementation must follow [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). It defines feature ownership, dependency boundaries, backend responsibilities, mission state transitions, security rules, and the required source layout.

The UI follows client-side MVC: Views render and forward actions, Controllers own interaction state, and Models remain independent of Flutter widgets and external providers. Supabase, Google Maps and Gemini integrations remain isolated under `lib/services/` for the next implementation phase.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
