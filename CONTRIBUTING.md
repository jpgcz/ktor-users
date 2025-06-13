# Contributing Guidelines

## Commit Message Format

We use semantic commit messages to automate versioning:

- `feat(scope): description` - A new feature (triggers a MINOR version bump)
- `fix(scope): description` - A bug fix (triggers a PATCH version bump)
- `perf(scope): description` - A performance improvement (triggers a PATCH version bump)
- `BREAKING CHANGE: description` - A breaking API change (triggers a MAJOR version bump)

Examples:

- `feat(api): add new user endpoint`
- `fix(auth): resolve login issue`
- `perf(db): optimize query performance`
- `feat(api)!: redesign user API` (with `BREAKING CHANGE: redesigned user API` in the commit body)
