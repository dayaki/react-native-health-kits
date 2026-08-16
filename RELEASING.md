# Releasing

Releases run through [release-it](https://github.com/release-it/release-it),
configured in `.release-it.json`. One command bumps the version, stamps the
changelog, builds, publishes to npm, tags, and opens a GitHub release.

## Before you start

- Be on `main`, up to date, with a clean working tree. release-it refuses
  otherwise (`requireBranch`, `requireCleanWorkingDir`, `requireUpstream`).
- CI must be green on `main`. Nothing in the release flow builds the native
  code — that is CI's job, and a release does not re-check it.
- Be logged in: `npm whoami`. If that 401s, run `npm login` first.
- **Verify on a device.** CI proves the Swift and Kotlin compile, not that the
  module registers or returns correct data. For anything touching native code,
  run the example app on a real device first — see `example/README.md`.

## Normal release

Add entries under `## [Unreleased]` in `CHANGELOG.md` as you merge work. Then:

```bash
yarn release            # prompts for major / minor / patch
yarn release minor      # or state it outright
```

What happens, in order:

1. `yarn typecheck` (`before:init`) — aborts the release if it fails
2. Version bumped in `package.json`
3. `scripts/changelog-stamp.sh` turns `## [Unreleased]` into
   `## [<version>] - <date>`, opens a fresh Unreleased section, and adds the
   link reference
4. `yarn prepare` builds `lib/`, so a broken build fails before anything is
   published or tagged
5. Release commit `chore: release v<version>`, annotated tag `v<version>`, pushed
6. `npm publish` — `publishConfig.access` is `public`, which a scoped package
   needs
7. GitHub release named `v<version>`, with notes taken from that version's
   CHANGELOG section via `scripts/release-notes.sh`

Preview any of it without side effects:

```bash
yarn release --dry-run
```

## Releasing a version whose number is already set

If `package.json` already carries the version you want to ship — as with 2.0.0,
which was bumped by hand in its release PR — skip the increment:

```bash
yarn release --no-increment
```

The changelog stamp no-ops when the heading for that version already exists, so
a hand-written section is left alone.

## Publishing behind a dist-tag

For a breaking release, or anything not yet device-verified, publish where
existing users won't be upgraded into it:

```bash
yarn release --npm.tag=next
```

`latest` keeps pointing at the previous version. Promote when you're confident:

```bash
npm dist-tag add @mbdayo/react-native-health-kits@<version> latest
```

npm's unpublish window is 72 hours. After that a version is permanent — you can
`npm deprecate` it, but you cannot replace it. Prefer `next` when in doubt.

## Troubleshooting

**`Not authenticated with npm`** — run `npm login`. Add `--otp=<code>` to the
release command if you have 2FA on.

**`Must be on branch main`** — intentional. Release from `main` only.

**`The lockfile would have been modified by this install`** in CI — a
`package.json` dependency or peer-dependency change landed without its
`yarn.lock` update. Run `yarn install` and commit the lockfile. Note that
re-running a PR's CI will *not* fix this after the base branch is fixed: a
re-run replays the original merge commit rather than recomputing it, so push a
commit to the branch instead.

**Changelog notes came out empty** — `scripts/release-notes.sh <version>` needs
a `## [<version>]` heading in `CHANGELOG.md`. Run it directly to see what it
extracts.
