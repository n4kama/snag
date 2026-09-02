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

test: install
    cd raycast && npm test

lint: install
    cd raycast && npm run fix-lint

# Drop everything regenerable
clean:
    rm -rf raycast/node_modules raycast/dist raycast/raycast-env.d.ts
