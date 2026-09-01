# Snag

Search [7TV](https://7tv.app) emotes and copy them straight to your clipboard as
real image files, not links, so they paste into WhatsApp, Discord, Signal or
anything else, even apps with no 7TV integration.

Built for iOS: add it to your Home Screen and it behaves like a native app.

**Live:** <https://snag.nakama.mov>

## Why

7TV's own site is built for desktop chat. On a phone, getting an emote into a
conversation means long-pressing an image, saving to Photos, then attaching it.
Snag is a search box and a grid: tap an emote, it's on your clipboard.

## How it works

One HTML file. No backend, no build step, no dependencies, no tracking.

It talks to the public 7TV GraphQL API directly from the browser — both
`7tv.io` and `cdn.7tv.app` send permissive CORS headers, so no proxy is needed.

Emotes are copied via the async Clipboard API. 7TV serves static emotes as PNG
and animated ones as gif/webp/avif, and the app copies whichever the emote
actually is — GIF for animated, PNG for static.

## Formats and the animation caveat

There is nothing to choose: a static emote copies as a real PNG, an animated one
copies as a GIF. There is no reason to want frame 1 of an animation, so the app
never offers it.

**A web page cannot put an animated GIF on the system clipboard.** The Clipboard
API spec only permits `text/plain`, `text/html` and `image/png` to be written,
and WebKit rejects `image/gif` outright. The `web image/gif` custom format exists
but native apps cannot read it, so it is useless for pasting into a chat app.

The workaround is the share sheet, which hands a real `File` to the OS and skips
the pasteboard entirely. Where the clipboard refuses GIF, tapping an animated
emote opens the share sheet instead — no separate button, the tile does it. The
app detects the refusal once, remembers it, and routes around it from then on.
A canvas-rendered PNG of frame 1 is the last resort, used only when the emote
ships no GIF file or the device has neither GIF clipboard nor file sharing.

Results come 60 at a time; **Load more** appends the next page and the status
line tracks how many of the total you have. The API rejects `page > 100`, so the
button disappears at 6000 results, or earlier when the results run out.

Size (1x–4x) is togglable and persists locally. 2x is the default — 4x is
noticeably heavier (GIGACHAD is 83 KB at 1x and 1.2 MB at 4x).

## Development

It is one static file. Open it over HTTP:

```sh
python3 -m http.server -d public 8000
```

Then visit <http://localhost:8000>. **HTTPS or localhost is mandatory** — the
Clipboard API refuses to run on an insecure origin, so opening `index.html` as a
`file://` URL will not work, and neither will a plain-http LAN address.

Append `#selftest` to the URL to run the built-in checks: it asserts the
webp→PNG converter emits valid PNG magic bytes, verifies the format-selection
logic, and prints what this device's clipboard actually supports.

## Deployment

Pushing to `master` publishes `public/` to GitHub Pages via
[`.github/workflows/pages.yaml`](.github/workflows/pages.yaml). No API tokens or
secrets are involved — the workflow authenticates with its own OIDC identity.

Repository settings must have **Pages → Source → GitHub Actions** selected.

The custom domain lives in [`public/CNAME`](public/CNAME) so that it survives
each deploy, rather than only in the repository settings.

## Licence

MIT
