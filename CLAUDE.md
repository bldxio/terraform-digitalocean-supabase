# terraform-digitalocean-supabase

## Commands
```bash
# Build Packer image
cd packer
packer init .
packer build .

# Deploy with Terraform 
cd terraform
terraform init
terraform plan
terraform apply

# View outputs
terraform output htpasswd
terraform output psql_pass
terraform output jwt
terraform output jwt_anon
terraform output jwt_service_role
```

## Code Style
- Follow Terraform style guide (terraform fmt)
- Use 4-space indentation (2 spaces for .yml files)
- Avoid trailing whitespace
- End files with newline
- Use UTF-8 encoding and LF line endings
- Document all Terraform modules with terraform-docs
- Variables should be sorted by required/optional

## Project Structure
- `/packer` - Packer configuration for Supabase snapshot
- `/terraform` - Terraform modules for DigitalOcean resources
- `.github/workflows` - GitHub Actions workflows
- Sensitive information should never be stored in version control

## GitHub Actions Workflow
The repository includes a GitHub Actions workflow for automatically building Packer images:

- Triggers when changes are pushed to the `dev` branch in the `packer/` directory
- Uses HashiCorp Cloud Platform (HCP) Packer to store image metadata
- Required environment variables:
  - GitHub Secrets:
    - `HCP_CLIENT_ID` - HCP client ID
    - `HCP_CLIENT_SECRET` - HCP client secret
    - `HCP_PROJECT_ID` - HCP project ID
    - `DO_API_TOKEN` - DigitalOcean API token
  - GitHub Environment Variables:
    - `DO_REGION` - DigitalOcean region (defaults to 'sfo3')
    - `DO_DROPLET_IMAGE` - Base image (defaults to 'ubuntu-22-10-x64')
    - `DO_DROPLET_SIZE` - Droplet size (defaults to 's-2vcpu-4gb')
    - `HCP_BUCKET_NAME` - HCP Packer bucket name