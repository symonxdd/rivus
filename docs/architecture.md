---
title: Architecture
description: Tech stack, folder structure, theming, and the SSDP discovery design behind Rivus.
---

## Why Android-only

Rivus targets Android exclusively. The live-capture milestone depends on `AudioPlaybackCapture` (Android 10+, `MediaProjection` plus a foreground service), which has no equivalent on iOS. Since that capability is core to the app, not an add-on, there was no point maintaining iOS support that would never reach feature parity.

That said, the pure-Dart layers (UPnP, HTTP server, library, UI, state) are written with no Android-specific assumptions baked in; native code only lives behind platform channels, kept separate from everything else.

## Tech stack

- **Flutter** (Material 3), Android-only, strict `flutter_lints` plus a tightened `analysis_options.yaml` (const-everywhere, relative imports, trailing commas, no dynamic calls, sink/subscription hygiene).
- **Riverpod** (`flutter_riverpod`): the app's one state-management solution, used consistently across features.
- **`shared_preferences`**: persists the user's theme choice.
- **`package_info_plus`**: app version/build metadata for the About sheet.
- **`dart_cast`**: SSDP discovery of DLNA MediaRenderer devices, plus (from milestone 3) the parts of its SOAP/HTTP plumbing that aren't video-specific (see [Casting](#casting) below for what's reused versus replaced).
- **`flutter_multicast_lock`**: acquires Android's `WifiManager` multicast lock, without which SSDP replies are silently dropped by the OS (see [SSDP discovery](#ssdp-discovery) below).
- **`permission_handler`**: requests the runtime permission needed to read the local audio library (`READ_MEDIA_AUDIO` on Android 13+, `READ_EXTERNAL_STORAGE` below that).
- **`shelf` / `shelf_static`**: serve the selected local audio file to the renderer over HTTP (see [Embedded HTTP file server](#embedded-http-file-server)).
- **`path`**: used alongside `shelf_static` to give the served file a real extension in its URL.

## Folder structure

The codebase is feature-first: `lib/features/{about,settings,home,discovery,media_library,cast,capture}`, each split into up to four layers:

| Layer | Contains | Depends on Flutter/Riverpod? |
|---|---|---|
| `ui/` | Widgets | Yes |
| `state/` | Riverpod providers/Notifiers holding the feature's reactive state | Yes |
| `models/` | Plain Dart data classes | No |
| `services/` | Code that talks to the outside world: network sockets, HTTP/SOAP calls, MediaStore queries | No (pure Dart, but does real I/O) |

Not every feature has all four yet; only what's needed exists at each milestone. `discovery/`, `media_library/`, and `cast/` are built out; `capture/` is still an empty placeholder for milestone 4.

## Theming

- Default: follows the system theme (`ThemeMode.system`).
- The selector (in the Settings sheet) shows exactly two options, Light and Dark, never a visible "System" option.
- Before the user has chosen, the selector highlights whichever the system currently resolves to.
- The first manual selection is persisted via `shared_preferences` and permanently disables system-following from then on (`ThemeModeController` in `features/settings/state/theme_mode_controller.dart`).

## About sheet

Shows the build environment (dev/release, from `kReleaseMode`), the app version/build number, and a small credit line. Tapping the version number 7 times (with a hint appearing from the 4th tap) reveals a hidden Diagnostics card behind a brief sound-wave ripple animation, showing exact version info and the recent SSDP discovery log.

## SSDP discovery

Milestone 2 needed to find DLNA MediaRenderer devices (like a Sonos speaker) on the LAN. Before writing anything custom, several pub.dev packages were evaluated:

- `ssdp`: Dart 1 only, dead.
- `upnped`: over a year since its last publish, minimal adoption. Effectively abandoned.
- `media_cast_dlna`: an Android-only native plugin covering both discovery and full AVTransport control, but with modest commit history and no confirmed testing against Sonos hardware specifically.
- `dlna_dart`: the best adoption numbers on paper, but a thin, video-cast-oriented API with no documented volume/seek support, and a multi-year gap in its release history despite a recent version bump.
- `upnp_client`: pure Dart with a generic UPnP client, but would still require writing renderer filtering, SOAP calls, and DIDL-Lite construction from scratch on top of it.
- `dart_cast` (chosen): actively maintained, pure Dart, and its DLNA support alone already provides SSDP discovery filtered to MediaRenderer devices, parsed device descriptions with control URLs, and a full AVTransport session API for later milestones.

### The Android multicast quirk

SSDP works by sending a UDP packet to a multicast address that any device on the network can pick up, and listening for replies. Android filters out multicast traffic by default for every app, as a battery-saving measure, which means SSDP requests go out fine but their replies are silently dropped before ever reaching the app.

The fix is Android's `WifiManager.MulticastLock`, a native-only API with no Dart equivalent, which is why a second small plugin (`flutter_multicast_lock`) is used alongside `dart_cast`, purely to acquire that lock for the duration of each scan and release it afterward.

### Discovery state

`RendererDiscoveryController` (a `StreamNotifier`) acquires the multicast lock, runs a 5-second SSDP scan, and releases the lock once the scan ends. It exposes a small `DiscoveryState` model (list of devices found so far, plus an `isScanning` flag), because Riverpod's `AsyncValue` alone can't distinguish "still searching, zero results yet" from "search finished with zero results"; those need different UI (a spinner vs. an empty state with a retry button).

## Local audio library

Milestone 3 needed to enumerate audio files already on the device. Every actively-maintained pub.dev package for this was ruled out:

- `on_audio_query`: the long-standing, most popular option (182 likes), but its GitHub repository is archived: confirmed directly, it's officially end-of-life.
- `on_audio_query_forked` / `on_audio_query_pluse` / `on_audio_query_plus`: small forks trying to keep it alive, each a single-maintainer project with a handful of likes and an unverified publisher.
- `photo_manager`: a much larger, actively maintained, verified-publisher package (773 likes) that can filter to audio files, but only exposes generic file metadata (title, duration, path) with no artist/album. Ruled out for supply-chain trust reasons (a personal, non-technical call) before that gap even mattered.
- `audio_fetcher`, `media_browser`: thin, low-adoption, unproven alternatives.

Since the milestone only needs a flat, title-sorted list (no artist/album grouping required), and querying `MediaStore.Audio.Media` is a small, stable, well-documented Android API, this was implemented directly instead of depending on an abandoned or thin package: a Kotlin class (`android/app/src/main/kotlin/me/symon/rivus/MediaStoreAudioQuery.kt`) queries title, duration, file path, and MIME type, exposed to Dart over a platform channel (`me.symon.rivus/media_store_audio`). `MediaStoreAudioService` (in `media_library/services/`) wraps that channel; `MediaLibraryController` requests the `READ_MEDIA_AUDIO`/`READ_EXTERNAL_STORAGE` permission via `permission_handler` before querying.

`MediaStore` is storage-volume-agnostic, so this should include microSD files automatically once the system has indexed them; not yet verified on hardware, since the primary test device has no SD card slot.

## Embedded HTTP file server

The selected file needs to be served over HTTP so the renderer can fetch it. `dart_cast`'s own embedded server, `MediaProxy`, was tried first, since it already has proven Range/HEAD handling and a documented HTTP/1.0 compatibility fix for renderers that reject HTTP/1.1.

Confirmed on a real Sonos Beam, though: `MediaProxy` has a real defect for audio. Its Content-Type detection (`_contentTypeForPath`) only recognizes a small, video-oriented extension list (`.mp4`, `.m4v`, `.m4s`, `.ts`, `.mkv`, `.vtt`, `.srt`, plus `.aac`); anything else, including `.m4a` and `.mp3`, falls back to a generic `application/octet-stream`. That mismatched the correct MIME type declared in the DIDL-Lite metadata sent to the renderer: Sonos accepted the `SetAVTransportURI` call, started fetching the file, and aborted mid-transfer (`SocketException: Write failed, Broken pipe`) once it noticed the mismatch. There's no public parameter on `registerFile()` to override this.

The fix: a small `AudioHttpServer` (`cast/services/audio_http_server.dart`) built on `shelf`/`shelf_static` (the official Dart-team package, with Range/HEAD support verified directly from its source), passing the file's real MIME type explicitly rather than guessing from the extension, since MediaStore already reports it accurately. `dart_cast`'s `NetworkUtils` (its logic for picking the local IP that's on the same subnet as the renderer) is still reused directly; it's fully standalone and has nothing video-specific about it.

## Casting

`dart_cast`'s high-level `DlnaSession.loadMedia()` (the convenient all-in-one casting call) turned out to assume video content throughout: it hardcodes `<upnp:class>object.item.videoItem</upnp:class>` in its DIDL-Lite metadata, and its `CastMediaType` enum only has `hls`/`mp4`/`mkv`/`mpegTs` values, nothing for plain audio. Confirmed on a real Sonos Beam: sending that for an audio file returns HTTP 500 from the speaker's own SOAP handler, before it ever tries to fetch the file.

`DlnaAudioSoap` (`cast/services/dlna_audio_soap.dart`) builds the same `SetAVTransportURI` SOAP call with correct audio metadata instead: `object.item.audioItem.musicTrack`, the file's real MIME type, and `DLNA.ORG_OP=01` plus `DLNA.ORG_FLAGS` so the renderer knows the resource supports byte-range/seek requests; without these, some renderers accept the call but never actually start playback.

`CastPlaybackController` (`cast/state/cast_playback_controller.dart`, a Riverpod `Notifier`) drives the whole session. It reuses `dart_cast`'s `DlnaHttpClient` (generic SOAP transport) and the parts of `DlnaSoapBuilder`/`DlnaSoapParser` that have no video-specific content at all (Play/Pause/Stop/Seek/Volume actions, and position/transport-state/volume polling once a second), while using its own `AudioHttpServer` and `DlnaAudioSoap` for the two pieces that did assume video. Every `loadAndPlay` call is self-contained (stop the old file server, serve the new file, send a fresh `SetAVTransportURI`+`Play`), so switching tracks mid-playback works cleanly with no special-casing.

### Sonos's GroupRenderingControl quirk

Volume control (`SetVolume`) initially failed with UPnP error 401 ("Invalid Action"), even though AVTransport actions worked fine. Cause: `dart_cast`'s device-description parser picks the RenderingControl URL via `serviceType.contains('RenderingControl')`, which also matches Sonos's separate `GroupRenderingControl` service (for multi-room speaker groups, with a different action set like `SetGroupVolume` instead of `SetVolume`). `CastPlaybackController._correctedRenderingControlUrl` fixes this by substituting `GroupRenderingControl` back to `RenderingControl` in the URL, which Sonos's control URLs consistently follow a predictable pattern for. This is a no-op for every other renderer, since that substring is simply absent unless the device actually exposes a Sonos-style group service.

### Transport controls

`TransportControlsBar` (`cast/ui/transport_controls_bar.dart`) is a persistent bottom bar, hidden until something's been cast, showing the track title, a play/pause toggle, a seek slider with live position/duration labels, and a volume slider. The volume slider updates its displayed value immediately on drag rather than waiting for the network round trip to confirm, since a `Slider` fires `onChanged` many times a second and expects the bound value to update synchronously to track the drag smoothly.

Not yet built: a simple queue, the one remaining piece of milestone 3.
