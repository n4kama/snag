# Snag — web app in public/, Raycast extension in raycast/

# List the recipes
default:
    @just --list

# Serve the web app. localhost is mandatory: the Clipboard API refuses file://
serve port="8000":
    python3 -m http.server -d public {{port}}

install:
    cd raycast && npm install

# Install the extension into Raycast and rebuild on every save
dev: install
    cd raycast && npm run dev

build: install
    cd raycast && npx ray build -e dist

# public/snag.js is a copy of the canonical raycast/src/snag.mjs — the store build cannot
# reach outside the extension directory, so the extension owns it.
sync:
    cp raycast/src/snag.mjs public/snag.js

test: install
    @cmp -s raycast/src/snag.mjs public/snag.js || { echo "public/snag.js is stale — run 'just sync'"; exit 1; }
    cd raycast && npm test

lint: install
    cd raycast && npm run fix-lint

# Drop everything regenerable
clean:
    rm -rf raycast/node_modules raycast/dist raycast/raycast-env.d.ts
