# Snag

Search [7TV](https://7tv.app) emotes and copy them straight to your clipboard as
real image files, not links, so they paste into WhatsApp, Discord, Signal or
anything else, even apps with no 7TV integration.

Two front ends over the same 7TV search:

- **[`public/`](public/)** — a web app for iOS and the browser. Add it to your
  Home Screen and it behaves like a native app. **Live:**
  <https://snag.nakama.mov>
- **[`raycast/`](raycast/)** — a Raycast extension for macOS. A hotkey pops the
  picker over whatever chat you are in, and Enter pastes the emote into the
  message box.

## Why

7TV's own site is built for desktop chat. On a phone, getting an emote into a
conversation means long-pressing an image, saving to Photos, then attaching it.
Snag is a search box and a grid: tap an emote, it's on your clipboard.

Both hit the public 7TV GraphQL API directly, sort by popularity, page 60 at a
time, default to 2x, and paste a real image file rather than a link. That is not
a coincidence they have to maintain: the query and the file choice live once in
[`public/snag.js`](public/snag.js), which the web app imports over HTTP and the
extension bundles. They differ only where the platform forces them to, which is
entirely about the clipboard.

## The web app

Two static files, `index.html` and the shared `snag.js`. No backend, no build
step, no dependencies, no tracking.

It talks to the API directly from the browser — both
`7tv.io` and `cdn.7tv.app` send permissive CORS headers, so no proxy is needed.

Emotes are copied via the async Clipboard API. 7TV serves static emotes as PNG
and animated ones as gif/webp/avif, and the app copies whichever the emote
actually is — GIF for animated, PNG for static.

### Formats and the animation caveat

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

## The Raycast extension

The whole animation caveat above evaporates on macOS: Raycast pastes a real
*file*, so an animated emote arrives animated. There is no share sheet, no
format detection, and no canvas fallback — nothing needs converting, so on the
rare emote shipping neither GIF nor PNG the webp is pasted as-is.

Format and size selection is not merely identical, it is the same code:
[`raycast/src/pick.ts`](raycast/src/pick.ts) is four lines re-exporting
`public/snag.js` with types attached. Paging is identical too, except scrolling
loads the next 60 instead of a button.

Set it up:

```sh
just dev             # installs into Raycast and rebuilds on every save
```

Then bind a hotkey to **Snag Emote** in Raycast Settings → Extensions. Enter
pastes into the frontmost app; ⌘K → *Copy Emote* copies without pasting.

Publishing to the Raycast Store: `ray login`, then `npm run publish` from
`raycast/` — it builds, validates, forks `raycast/extensions` and opens the PR.
`ray lint` passes and [`raycast/CHANGELOG.md`](raycast/CHANGELOG.md) is written.

There is deliberately no `raycast/metadata/` directory. Screenshots are optional
while it is absent and strictly validated at 2000×1250 the moment it exists, and
Raycast's **Window Capture** only reaches that on a 2× display — every monitor
here runs at 1×, so it tops out near 1000×625. Add screenshots from a Retina
display later rather than shipping an upscale.

## Development

There is no Raycast CLI to install: `ray` ships inside `@raycast/api`, so
`npm install` puts it at `raycast/node_modules/.bin/ray` and every recipe below
uses that copy. Nothing here needs to be installed globally.

```sh
just                 # list every recipe
just serve           # the web app on http://localhost:8000
just dev             # the Raycast extension, watching for changes
just test            # asserts format and size selection, no test framework
just build           # type-check and bundle the extension
just clean           # drop node_modules and build output
```

**HTTPS or localhost is mandatory for the web app** — the Clipboard API refuses
to run on an insecure origin, so opening `index.html` as a `file://` URL will
not work, and neither will a plain-http LAN address.

Append `#selftest` to the URL to run the web app's built-in checks: it asserts
the webp→PNG converter emits valid PNG magic bytes, verifies the
format-selection logic, and prints what this device's clipboard actually
supports. The extension's equivalent is `just test`.

Changes to search, sorting, paging, sizes or format selection land in
`public/snag.js` and therefore hit **both** apps at once — see
[`CLAUDE.md`](CLAUDE.md) before changing either.

## Deployment

Pushing to `master` publishes `public/` to GitHub Pages via
[`.github/workflows/pages.yaml`](.github/workflows/pages.yaml). No API tokens or
secrets are involved — the workflow authenticates with its own OIDC identity.

Repository settings must have **Pages → Source → GitHub Actions** selected.

The custom domain lives in [`public/CNAME`](public/CNAME) so that it survives
each deploy, rather than only in the repository settings.

## Licence

MIT
