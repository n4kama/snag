# Snag

Two front ends, one behaviour: the web app in `public/index.html` and the
Raycast extension in `raycast/`.

## Every change is a decision for both apps

Before changing either app, work out what the change means for the other one and
**bring it up in the conversation before making it**. Do not implement a change
in one app and leave the other for later, and do not silently decide the other
app does not need it.

State which of these three it is, and get agreement first:

1. **Applies to both** — implement it in both in the same change.
2. **Applies to both, but differently** — say why the platform forces a
   different implementation, and what the shared behaviour still is.
3. **Applies to one only** — say why the other is genuinely unaffected.

This matters most for anything touching **search, sorting, paging, size
selection, or the GIF/PNG rule**. That is the shared contract and it lives in
one place, `public/snag.js`: the web app imports it over HTTP, the extension
bundles it through the four-line re-export in `raycast/src/pick.ts`. Editing it
changes both apps at once, which is the point — and the reason to think about
both before editing it.

Keep `public/snag.js` free of anything platform-specific. It is plain ES
modules with JSDoc types and no imports, because it has to run unbuilt in Safari
and type-check under the extension's `tsc` at the same time. Clipboard formats,
canvas conversion, sharing and pasting belong in the callers.

The current deliberate divergence, for reference: the web app fights the
Clipboard API's refusal to write `image/gif` (share-sheet fallback, canvas
frame-1 last resort, remembered refusal), and the extension has none of that,
because Raycast pastes a real file. Same behaviour, forced apart by the platform.

## Checks

- `just test` — the extension's format and size selection
- `#selftest` appended to the web app URL — the same logic, plus the converter
- `just build` — type-check and bundle the extension

Both are assert-based and dependency-free. Keep them that way.
