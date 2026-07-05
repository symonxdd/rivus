---
title: How Rivus Works
description: A plain-language walkthrough of every technology and term behind Rivus, for anyone (including future-you) who wants to actually understand it, not just skim it.
---

This page explains every piece of technology Rivus touches, in plain language, including why things are named what they're named when that's not obvious. [architecture.md](architecture.md) documents *decisions* (which package was chosen and why); this page documents *concepts* (what a DIDL-Lite even is). Skip to the [glossary](#glossary) at the bottom for quick lookups, or read top to bottom for the full story of what happens when you tap a song.

## The big picture

Casting a song from your phone to a speaker like a Sonos involves two completely separate things happening at once:

1. **Telling the speaker what to play**: a short text message saying "here's a web address, go fetch and play whatever's there."
2. **Actually getting the audio there**: your phone briefly acts as its own tiny web server, and the speaker downloads the file from it over your home network, the same way a browser downloads a webpage.

The speaker never receives the audio file directly from your phone in one lump; it's told a URL, and it fetches that URL itself, the same way you'd type a web address into a browser. Everything below explains the specific technologies that make each of those two things work.

## Finding the speaker: discovery

### What is UPnP?

**UPnP** stands for **Universal Plug and Play**. "Plug and Play" is the same phrase used for hardware peripherals (like a USB mouse) that work the instant you connect them, no setup required. UPnP applies that same idea to devices on a network: a UPnP device announces itself and describes what it can do, so other devices can find and use it automatically, with no manual configuration (no typing in IP addresses, no pairing codes). It's "universal" because it's an open, vendor-neutral standard: a UPnP app from one company can control a UPnP speaker from a completely different company.

### What is DLNA?

**DLNA** stands for **Digital Living Network Alliance**, the industry group (Sony, Samsung, and others) that formed to make home media devices, TVs, speakers, phones, actually interoperate. DLNA didn't invent a new networking protocol; it wrote a set of stricter rules and certification tests on *top* of UPnP, specifically for media (what audio/video formats a device must support, how metadata should be labeled, etc.). In practice, "DLNA device" and "UPnP media device" are used almost interchangeably. Sonos speakers are UPnP devices that also follow (most of) DLNA's media conventions.

### What is a MediaRenderer?

Within UPnP, devices declare a **device type** describing their role. `MediaRenderer` is the type for "a thing that plays media" (a speaker, a smart TV). The counterpart, `MediaServer`, is for "a thing that stores/offers media" (like a NAS). Rivus only looks for `MediaRenderer` devices, since it's casting *to* a speaker, not browsing files *from* one.

### What is SSDP, and how does discovery actually work?

**SSDP** stands for **Simple Service Discovery Protocol**, the specific part of UPnP responsible for the "find devices automatically" step. Here's the mechanism: your phone sends out a single short network message called an **M-SEARCH**, addressed not to one specific device, but to a special shared address that every device on the network is listening to (this is called **multicast**, explained below). Any UPnP device that matches what you're searching for (in Rivus's case, "any MediaRenderer") replies directly back to your phone with a short message pointing to its own **device description** (an XML document describing exactly what that device can do; see below). Rivus does this scan for five seconds and collects whatever speakers reply in that window.

### Multicast vs. unicast vs. broadcast

Normal network traffic (**unicast**) is addressed to exactly one specific device, like mailing a letter to one street address. **Broadcast** sends a message to *every* device on the network, no addressing at all. **Multicast** sits in between: a message is sent to a special "channel" address, and only devices that have chosen to "tune in" to that channel receive it, everyone else ignores it. SSDP uses multicast (the address `239.255.255.250`) so a phone can ask "any speakers out there?" without needing to already know who's out there.

This is also exactly where the app hit a real Android quirk during development: Android filters out incoming multicast traffic by default, for every app, to save battery, so SSDP replies were silently getting dropped before ever reaching Rivus. The fix, `WifiManager.MulticastLock`, is covered in the "Android multicast quirk" section of [architecture.md](architecture.md).

## Talking to the speaker: UPnP control

### Device description XML and control URLs

Once a speaker replies to the SSDP search, Rivus fetches a small XML document from a URL the speaker provided. This document is the speaker's own self-description: its friendly name (e.g. "Living Room"), manufacturer, model, and, most importantly, a list of **services** it offers, each with its own **control URL**, a specific web address Rivus can send commands to for that particular service.

### Services: AVTransport, RenderingControl, ConnectionManager

A UPnP MediaRenderer exposes its capabilities as separate **services**, each handling one job:

- **AVTransport**: playback itself, "set what to play," "play," "pause," "seek." ("AV" = audio/video; "Transport" = the tape-deck-era term for play/pause/rewind controls, carried over from VCR remotes.)
- **RenderingControl**: output-level adjustments, primarily volume and mute.
- **ConnectionManager**: lets a controller ask a device what formats/codecs it actually supports, before trying to send it something it can't play.

Each service has its own control URL and its own list of supported **actions** (named operations, like `Play` or `SetVolume`). Sonos additionally exposes a **GroupRenderingControl** service (for volume across a *group* of speakers playing together), which turned out to have a nearly-identical name to plain RenderingControl and caused a real bug during development, covered in the "Sonos's GroupRenderingControl quirk" section of [architecture.md](architecture.md).

### What is SOAP?

**SOAP** stands for **Simple Object Access Protocol**. It's the message format UPnP uses to actually send a command to a service's control URL: a small, strictly-structured XML document naming which action to run (e.g. `Play`) and its parameters (e.g. `Speed: 1`), wrapped in a standard "envelope." It's essentially a way to call a specific function on a remote device over the network, with the function name and arguments spelled out in XML rather than in a programming language. Every button press in Rivus's transport controls (play, pause, seek, volume) is one SOAP message to the relevant control URL.

### What is DIDL-Lite?

**DIDL-Lite** stands for **Digital Item Declaration Language, Lite** (a simplified/"lite" version of a more complex media-description standard called MPEG-21 DIDL). In plain terms: it's the small chunk of XML that describes *what* is being played, before the speaker fetches it: the title, whether it's music or a video, and its web address and format. Before a speaker starts fetching a file, Rivus sends it this description as part of the `SetAVTransportURI` SOAP action, so the speaker knows what it's about to receive.

This is exactly where the earlier "casting doesn't work" bug lived: the DIDL-Lite must correctly say `object.item.audioItem.musicTrack` for a song. The library Rivus is built on originally hardcoded `object.item.videoItem` instead (it was written primarily for casting video), and Sonos, quite reasonably, rejected that outright for an actual audio file. See the "Casting" section of [architecture.md](architecture.md) for the full story.

### What is `protocolInfo`?

Alongside the DIDL-Lite description sits a short string called `protocolInfo`, describing the technical format of the file, e.g. `http-get:*:audio/mpeg:*`. Reading it left to right: `http-get` (fetch it via a normal HTTP GET request), `*` (any network), `audio/mpeg` (the file's MIME type, its content format), `*` (any additional codec-specific flags). It's essentially a compact, standardized way of saying "here's how to fetch this, and here's what it is once you do." Getting this string's content-type field right (matching what the file actually is) turned out to matter a lot in practice; see the "Embedded HTTP file server" section of [architecture.md](architecture.md).

## Getting the file to the speaker

### What is MediaStore?

**MediaStore** is Android's own built-in, system-wide index of every media file on the device (songs, photos, videos), regardless of which app put them there. Instead of every app scanning the entire filesystem itself (slow, and blocked by Android's privacy rules anyway), apps ask MediaStore's index for what they need. Rivus asks it for every audio track's title, duration, file path, and MIME type.

### What is a platform channel?

Flutter apps are written in Dart, but some Android capabilities (like querying MediaStore) require calling into Android's own native code, written in Kotlin. A **platform channel** is Flutter's built-in bridge for this: Dart code sends a named message ("please run `querySongs`") across the channel, a small piece of Kotlin code on the other side receives it, does the actual work, and sends the result back the same way. It's essentially a structured, two-way messaging pipe between the Dart and Kotlin halves of the app. Rivus's `MediaStoreAudioQuery.kt` is the Kotlin side; `MediaStoreAudioService` (Dart) is the side that calls it.

### The embedded HTTP server

Once you tap a song, Rivus needs to hand the speaker a web address it can fetch the file from. Since the file lives on your phone, your phone briefly runs its own miniature web server (using the `shelf`/`shelf_static` packages), serving just that one file at a locally-reachable address like `http://10.0.0.44:45293/track.m4a`. The speaker then does a completely ordinary HTTP download from that address, the same way a browser downloads any file from the internet, just from your phone instead of a distant server.

## App-side building blocks

### Riverpod, briefly

Rivus uses [Riverpod](https://riverpod.dev) to manage state, information that changes over time and multiple parts of the UI need to react to (the list of discovered speakers, the currently-playing track, and so on). A `Provider` is a recipe for a piece of state; a `Notifier` is a provider whose value can change and has methods to change it; widgets `watch` a provider to rebuild automatically whenever it changes. This is covered in more depth, with the exact providers used in this app, in earlier project notes; [architecture.md](architecture.md) documents each feature's specific state controllers.

### Where things live

Every concept above maps to a specific file in the codebase; see the "Folder structure" section and per-feature sections in [architecture.md](architecture.md) for exactly where.

## Glossary

Quick lookup, alphabetical. Full explanations with context are in the sections above.

| Term | Full name | What it means |
|---|---|---|
| AVTransport | Audio/Video Transport | The UPnP service for play/pause/seek/load-media actions. |
| DIDL-Lite | Digital Item Declaration Language, Lite | The small XML snippet describing what media is being cast (title, type, format, URL). |
| DLNA | Digital Living Network Alliance | The industry group whose media-specific rules sit on top of UPnP. |
| M-SEARCH | (not an acronym; "search" message) | The specific SSDP multicast message that asks "any matching devices out there?" |
| MediaRenderer | | The UPnP device-type for "a thing that plays media," like a speaker. |
| MediaStore | | Android's built-in, system-wide index of media files on the device. |
| Multicast | | A network message sent to a shared "channel" address, received only by devices listening on it. |
| Platform channel | | Flutter's built-in messaging bridge between Dart code and native Android (Kotlin) code. |
| protocolInfo | | The short string describing a media file's transport and format, e.g. `http-get:*:audio/mpeg:*`. |
| RenderingControl | | The UPnP service for output-level adjustments, mainly volume and mute. |
| SOAP | Simple Object Access Protocol | The XML message format UPnP uses to send a named action and its arguments to a device. |
| SSDP | Simple Service Discovery Protocol | The part of UPnP responsible for automatically finding devices on the network. |
| UPnP | Universal Plug and Play | The open, vendor-neutral standard for devices to announce themselves and be controlled automatically, with no manual setup. |
