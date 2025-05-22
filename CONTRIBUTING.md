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

## Publishing to the Terraform Registry

The Terraform Registry only recognizes tags that match the format `x.y.z` or `vx.y.z` (for example, `1.0.4` or `v1.0.4`). Tags with extra suffixes like `-dev.1` or `-beta.1` are ignored by the registry.

**How this works with our workflow:**
- The `main` branch creates stable release tags (like `v1.2.3`) via semantic-release. These are picked up and published by the Terraform Registry.
- The `dev` branch creates pre-release tags (like `1.2.4-dev.1`), which are **not** published to the registry, but are useful for internal testing.

**To publish a new module version:**
1. Merge your changes into `main` using a Conventional Commit message (e.g., `feat: add new variable`).
2. semantic-release will automatically create a new version tag and GitHub release.
3. The Terraform Registry will detect the new tag and publish the module version.

**Summary Table:**

| Branch | Tag Example      | Registry Picked Up? | Purpose              |
|--------|------------------|---------------------|----------------------|
| main   | `v1.2.3`         | ✅ Yes              | Public release       |
| dev    | `v1.2.4-dev.1`   | ❌ No               | Internal pre-release |

**Best Practice:** Only merge to `main` when you are ready to publish a new version. Use `dev` for ongoing development and testing.


---

## Testing Pre-releases Locally and with Terraform Cloud

When you want to test changes before they are published as a stable release (for example, after a pre-release on the `dev` branch), you have several options:

### 1. Use a Local Path (for local development)
```hcl
module "supabase" {
  source = "../path/to/terraform-digitalocean-supabase"
  # ...other variables...
}
```
- **Use this when:** You are developing both your root config and the module on the same machine.

### 2. Use a Git Source with a Branch or Pre-release Tag
```hcl
module "supabase" {
  source = "github.com/bldxio/terraform-digitalocean-supabase?ref=dev"
  # or use a specific pre-release tag
  # source = "github.com/bldxio/terraform-digitalocean-supabase?ref=1.2.4-dev.1"
}
```
- **Use this when:** You want to test a pre-release version from GitHub, even if it isn't published to the registry.

### 3. Override in Terraform Cloud
- Temporarily point your module source to a branch or pre-release tag in your `main.tf` (as above).
- Run your Terraform Cloud workspace as usual to test the pre-release.
- Switch back to the registry source after merging to `main` and publishing a stable version.

### 4. Using a Private Repo
If your repo is private, you may need to set a `GITHUB_TOKEN` or use an SSH URL in your source string.

### Summary Table
| Use case         | Module source example                                               |
|------------------|---------------------------------------------------------------------|
| Local dev        | `../path/to/terraform-digitalocean-supabase`                        |
| Git pre-release  | `github.com/bldxio/terraform-digitalocean-supabase?ref=dev`         |
| Git tag          | `github.com/bldxio/terraform-digitalocean-supabase?ref=1.2.4-dev.1` |
| Registry (prod)  | `bldxio/digitalocean-supabase/module` (from registry)               |

**Best Practice:** Never reference `dev` or pre-release tags in production code. Use only for local/dev/test workspaces.


---

## Recommended Developer Workflow for Module Changes

To ensure safe and efficient development, follow this workflow:

1. **Checkout a feature branch from `dev`.**
2. **Test locally:**
   - Use a local path for fastest iteration:
     ```hcl
     source = "/absolute/path/to/terraform-digitalocean-supabase/terraform"
     ```
   - Or use a remote feature branch if pushed:
     ```hcl
     source = "github.com/bldxio/terraform-digitalocean-supabase//terraform?ref=feature/my-feature"
     ```
   - Run `terraform init` and `terraform plan` locally to validate changes.
3. **Open a PR to `dev` in the module repo.**
4. **When merged, CI creates a pre-release tag** (e.g., `v1.2.4-dev.1`).
5. **Update the dev environment to use the new pre-release tag:**
   ```hcl
   source = "github.com/bldxio/terraform-digitalocean-supabase//terraform?ref=v1.2.4-dev.1"
   ```
6. **A GitHub Actions automation will open a PR in the infra repo to update the dev environment's module source to the new pre-release tag.**
7. **Merge the PR to deploy the new version to dev, then run `terraform init` and `terraform apply`.**

| Stage            | Module Source Example                                                                 |
|------------------|--------------------------------------------------------------------------------------|
| Local feature    | /absolute/path/to/terraform-digitalocean-supabase/terraform                          |
| Remote feature   | github.com/bldxio/terraform-digitalocean-supabase//terraform?ref=feature/my-feature  |
| Dev environment  | github.com/bldxio/terraform-digitalocean-supabase//terraform?ref=v1.2.4-dev.1        |
| Production       | app.terraform.io/BLDX/supabase/digitalocean//terraform + version                     |

**Never use dev or feature branches as sources in production. Only use stable releases from the registry in prod.**

For questions, ask in the repo or contact the maintainers.
