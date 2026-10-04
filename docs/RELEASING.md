# Releasing

Versions and the changelog are managed by [release-please](https://github.com/googleapis/release-please)
(`.github/workflows/release-please.yml`). Nobody edits `package.json` versions, tags or `CHANGELOG.md` by hand.

## Versioning policy

- [SemVer](https://semver.org/), continuing the upstream line (fork starts from upstream `4.0.1`).
- Tags have no `v` prefix: `4.1.0`, consistent with upstream.
- No `-fork.N` style suffixes: a SemVer pre-release sorts *below* its base version.
- Major bump for breaking changes, including runtime upgrades (Meteor 2.x, MongoDB driver 4.x, mongosh)
  and deployment changes that require users to change their setup.

## Commits

Commits on `master` must follow [Conventional Commits](https://www.conventionalcommits.org/).
The type decides the version bump:

| Commit | Bump | In changelog |
|--------|------|--------------|
| `feat:` | minor | Features |
| `fix:` | patch | Bug Fixes |
| `perf:` | patch | Performance Improvements |
| `feat!:` / `fix!:` or a `BREAKING CHANGE:` footer | major | ⚠ Breaking Changes |
| `chore:`, `docs:`, `ci:`, `test:`, `refactor:`, `style:`, `build:` | none | hidden |

Merging a PR:

- **Rebase merge** or **merge commit**: every commit lands as is, so each must be a Conventional Commit.
- **Squash merge**: only the PR title ends up on `master`, so the title must be a Conventional Commit
  (`fix: compare versions semantically`). A non-conventional title is ignored and the change is missing
  from the changelog.

To force a specific version, add a `Release-As: 4.1.0` footer to a commit body.

## Flow

1. Feature/fix PR → `master`.
2. On every push to `master`, release-please opens or updates a **Release PR** (`chore(master): release X.Y.Z`)
   that bumps `package.json`, `package-lock.json`, `.release-please-manifest.json` and prepends the
   release notes to `CHANGELOG.md`.
3. The Release PR can stay open while more changes land; it is updated each time.
4. Merging the Release PR creates the `X.Y.Z` tag and a GitHub release.
5. The Docker image is built from that release (see below).

The in-app "new version available" check reads the latest GitHub release of this repository,
so a release is visible to users as soon as step 4 is done.

## Docker image

Tags and releases created by release-please use the workflow's `GITHUB_TOKEN`, and events created with
that token **do not trigger other workflows** (a separate `on: push: tags` workflow would not run).
Build the image as a job in `release-please.yml` gated on the `release_created` output
(`needs: release-please`, `if: needs.release-please.outputs.release_created == 'true'`), or have the
release-please step use a PAT / GitHub App token instead.

## Repository settings

release-please opens PRs with `GITHUB_TOKEN`, which requires
*Settings → Actions → General → Workflow permissions →
"Allow GitHub Actions to create and approve pull requests"* to be enabled.
