# NuclearNightmare-Community/catalog

The signed mod catalog for Nuclear Nightmare mods published by the NuclearNightmare-Community organization. The mod manager and the reference verifier download it from here and trust it only when its signatures check out against public keys built into them; this repo and its hosting are not trusted by themselves.

## Files

| File | What it is |
|---|---|
| `index.json`, `index.json.minisig` | the package index and its minisign signature (release key) |
| `revoked.json`, `revoked.json.minisig` | revoked package versions and their signature (revoke key) |
| `keys.json`, `keys.json.minisig` | key rotation and catalog endpoints, when published (release key) |

Each `.json` is published together with its `.minisig`, or not at all. The format (fields, serials, signatures, size limits and fetch rules) is defined by the catalog's index format contract, kept with the release tooling in the maintainer's workspace.

## Where it is served

- GitHub Pages: `https://nuclearnightmare-community.github.io/catalog/<file>`
- The `catalog` release (built-in fallback): `https://github.com/NuclearNightmare-Community/catalog/releases/download/catalog/<file>`

Both serve the same bytes. Only the six files above are published; nothing else in this repo (this README, the workflow and its check scripts in `.github/`) reaches Pages or the release.

**Never rename or transfer this repo, and never delete the `catalog` release or move its tag.** Both URLs are built into shipped clients, and the release URL is the fallback they use when every other endpoint fails.

## How publishing works

The maintainer edits and signs the files on their own machine, then pushes to `main`. The `publish` workflow then:

1. self-tests its check (`.github/test-check-catalog.sh`), then checks (`.github/check-catalog.sh`) that `index.json` and `index.json.minisig` are present, that every `.json` has its `.minisig` and the reverse, that no `.json` exceeds 4 MiB and no `.minisig` exceeds 4096 bytes, and that each is a regular file; on any failure it publishes nothing;
2. deploys exactly the present catalog files, unchanged, to GitHub Pages;
3. uploads the same files to the `catalog` release (creating it on the first run) and removes any catalog file no longer in the repo.

**CI holds no key.** The workflow has no secrets and no signing step, and it never creates or edits a catalog file. It uses only the run's `GITHUB_TOKEN`.

`.gitattributes` sets `* -text` so git never converts line endings: the committed bytes are the signed bytes.
