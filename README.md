# Rivus

Rivus (Latin: "stream") is a minimalist Android app that casts audio to UPnP/DLNA renderers on the LAN, such as a Sonos speaker.

## What it does

- Browse audio already on the phone (internal storage and microSD) and cast it to a chosen renderer, with play/pause/seek/volume controls.
- (Planned) Capture the phone's live media audio output and stream it to a renderer in real time.

## Status

Milestones 1 through 3 are done: scaffold and theming, SSDP renderer discovery, and local file casting with full transport controls, all confirmed working against a real Sonos Beam. Milestone 4 (live audio capture) is next.

## Documentation

The full docs site is at **[symonxdd.github.io/rivus](https://symonxdd.github.io/rivus/)**, or browse the same content directly in [docs/](docs/):

- [docs/README.md](docs/README.md): project overview and current status
- [docs/concepts.md](docs/concepts.md): plain-language explanations of every technology involved (UPnP, DLNA, SSDP, SOAP, DIDL-Lite, and more), plus a glossary
- [docs/architecture.md](docs/architecture.md): tech stack, folder structure, and the reasoning behind each decision

## Tech stack

Flutter (Material 3, Android only), Riverpod, `dart_cast` for UPnP/DLNA, a small Kotlin platform channel for the local audio library, and `shelf`/`shelf_static` for the embedded HTTP file server.

## Running it

```
flutter pub get
flutter run
```

Android only; there's no iOS build target, since the live-capture milestone depends on an Android-only API with no iOS equivalent.
