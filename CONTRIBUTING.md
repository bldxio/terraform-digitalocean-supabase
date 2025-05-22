# Contributing & Semantic Versioning Guide

## Commit Message Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/) for all commits. This enables automated semantic versioning and changelog generation via [semantic-release](https://semantic-release.gitbook.io/semantic-release/).

### Commit Format
```
<type>[optional scope]: <short summary>

[optional body]

[optional footer(s)]
```
**Types:**
- `feat`: New feature (minor version bump)
- `fix`: Bug fix (patch version bump)
- `chore`: Maintenance (no release by default)
- `docs`: Documentation changes
- `refactor`: Code refactor (no user-facing change)
- `BREAKING CHANGE`: (in body/footer) triggers a major release

**Examples:**
- `feat: add support for custom DigitalOcean region`
- `fix: correct typo in droplet_size variable name`
- `chore: update dependencies in packer config`
- `feat: change default networking to private\n\nBREAKING CHANGE: The default networking mode is now private.`

## Using the Commit Template

A commit message template is provided in `.gitmessage` to help you write valid commit messages. To use it:

```sh
git config commit.template .gitmessage
```

## Semantic Release Workflow
- **Branches:**
  - `main`: Stable releases (e.g., `1.2.3`)
  - `dev`: Pre-releases (e.g., `1.2.4-dev.1`)
- On every push to `main` or `dev`, the CI pipeline:
  - Runs tests and builds
  - Runs `semantic-release` to:
    - Analyze commits
    - Bump version/tag
    - Update the changelog
    - Create a GitHub release
- **Release notes** are generated automatically from commit messages.

## Tips
- Use clear, descriptive commit messages.
- For breaking changes, add `BREAKING CHANGE:` in the body or footer.
- See `.gitmessage` for a template.

---

For questions, ask in the repo or contact the maintainers.
