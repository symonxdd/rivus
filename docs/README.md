---
title: Rivus documentation
description: Documentation for Rivus, an Android app that casts audio to UPnP/DLNA renderers on the local network.
---

Rivus (Latin: "stream") is a minimalist Android app that casts audio to UPnP/DLNA renderers on the LAN, such as a Sonos speaker. It's a small, single-developer project built milestone by milestone.

## What it does

Rivus has two core capabilities, built in stages:

1. **Local file casting**: browse audio already on the phone (internal storage and microSD), serve the selected file over an embedded HTTP server, and push it to a chosen renderer over UPnP AVTransport, with play/pause/seek/volume and a simple queue. Working end-to-end against a real Sonos Beam; the queue is the one piece not built yet.
2. **Live audio casting**: capture the phone's media audio output (Android's `AudioPlaybackCapture` API) and expose it as a live HTTP stream that a renderer can play, so whatever is playing on the phone plays on the speaker.

## Current status

| Milestone | What it covers | Status |
|---|---|---|
| 1 | Scaffold, strict lints, feature-first structure, theming, About sheet | Done |
| 2 | SSDP renderer discovery + picker UI | Done |
| 3 | Local library, embedded HTTP file server, casting + transport controls | In progress: browsing, casting, and play/pause/seek/volume all confirmed working; the simple queue is the remaining piece |
| 4 | Live audio capture + live-stream casting | Not started |

## Where to go next

| Doc | What's in it |
|---|---|
| [architecture.md](architecture.md) | Tech stack, folder structure, theming, discovery/casting design |

## Quick map of the codebase

| Path | Contains |
|---|---|
| `lib/main.dart` | App entry point: `SharedPreferences` bootstrap, `ProviderScope`, `MaterialApp` |
| `lib/core/theme/` | Material 3 `ThemeData` (light/dark) |
| `lib/core/persistence/` | The `SharedPreferences` Riverpod provider |
| `lib/features/*/ui/` | Widgets |
| `lib/features/*/state/` | Riverpod providers/Notifiers |
| `lib/features/*/models/` | Plain Dart data classes |
| `lib/features/*/services/` | Code that talks to the network/OS (sockets, HTTP, MediaStore) |

See [architecture.md](architecture.md) for why the folders are split that way, and what exists in each feature so far.
