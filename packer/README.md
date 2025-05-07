# Supabase on DigitalOcean - Packer

> **IMPORTANT:** Do not commit secrets/tokens/API keys to version control. All sensitive values should be managed securely.

## What is this?
This directory contains [Packer](https://www.packer.io/) configuration for building the base DigitalOcean image (snapshot) used to deploy self-hosted Supabase on DigitalOcean. The image includes Docker, Docker Compose, and all necessary configuration and files for Supabase services.

## How it Works
- **Automated CI/CD:**
  - Any push to the `dev` or `main` branches that modifies files in this directory (or the workflow file itself) triggers the [build-packer-image.yml](../.github/workflows/build-packer-image.yml) GitHub Actions workflow.
  - The workflow builds and publishes a new image for both the `dev` and `prd` environments using [HCP Packer](https://developer.hashicorp.com/packer/docs/hcp).
  - Image metadata is managed in HCP Packer, and the image is published to DigitalOcean for use in downstream Terraform deployments.

- **Environment Mapping:**
  - Changes on `dev` branch build and publish a `dev` image.
  - Changes on `main` branch build and publish a `prd` (production) image.

## How to Make and Test Changes
1. **Edit the Image:**
   - Modify files in the `supabase/` directory to change what gets baked into the image (e.g., Docker Compose files, configs, SQL scripts).
   - Update the `supabase.pkr.hcl` config or scripts as needed.

2. **Test Locally (Optional):**
   - Copy and edit `supabase.auto.pkrvars.hcl.example` to `supabase.auto.pkrvars.hcl` and fill in your secrets and settings.
   - From the `packer` directory:
     ```bash
     packer init .
     packer build .
     ```
   - This will build and upload a snapshot to your DigitalOcean account for manual testing.

3. **Push Changes:**
   - Commit and push your changes to `dev` or `main`.
   - The GitHub Actions workflow will automatically build and publish the new image for the correct environment.
   - You can view build logs and image info in the Actions tab and HCP Packer dashboard.

## How the Automation Works
- See [build-packer-image.yml](../.github/workflows/build-packer-image.yml) for full details.
- The workflow:
  - Authenticates using GitHub and HCP Packer credentials.
  - Initializes and builds the Packer image.
  - Publishes the image to HCP Packer and DigitalOcean.
  - Tags images for `dev` or `prd` based on the branch.

## File Structure
- `supabase/`: All files and configs baked into the image (Docker Compose, configs, SQL, etc.)
- `scripts/`: Setup scripts run during image build.
- `supabase.pkr.hcl`: Main Packer configuration.
- `supabase.auto.pkrvars.hcl.example`: Example secrets/config file for local builds.

---

After a successful build, the new image will be available in DigitalOcean and referenced by downstream Terraform modules for infrastructure deployment.

For next steps, see the [terraform directory](../terraform/).

## Packer file structure

**_What's happening in the background_**

 A DigitalOcean Droplet is temporarily spun up to create the Snapshot. Within this Droplet, Packer copies the [supabase](./packer/supabase) directory that contains the following files:

 ```bash
 .
├── docker-compose.yml # Containers to run Supabase on a Droplet
├── supabase.subdomain.conf # Configuration file for the swag container (runs nginx)
└── volumes
    └── db # SQL files when initialising Supabase
        ├── realtime.sql
        └── roles.sql
 ```

 and also runs the [setup script](./packer/scripts/setup.sh) that installs `docker` and `docker-compose` onto the image.

 _N.B. If you changed the image to a non Ubuntu/Debian image the script will fail as it uses the `apt` package manager. Should you wish to use a different OS, modify the script with the appropriate package manager._

 Throughout the build you might see some warnings/errors. If the build ends with showing the version of Docker Compose installed and stating that the build was successful, as shown below, you can disregard these messages. Your Snapshot name will be slightly different to the one shown below as the time the build started is appended to the name in the following format `supabase-yyyymmddhhmmss`.

```md
    digitalocean.supabase: Docker Compose version v2.15.1
==> digitalocean.supabase: Gracefully shutting down droplet...
==> digitalocean.supabase: Creating snapshot: supabase-20230126130703
==> digitalocean.supabase: Waiting for snapshot to complete...
==> digitalocean.supabase: Destroying droplet...
==> digitalocean.supabase: Deleting temporary ssh key...
Build 'digitalocean.supabase' finished after 5 minutes 8 seconds.

==> Wait completed after 5 minutes 8 seconds

==> Builds finished. The artifacts of successful builds are:
--> digitalocean.supabase: A snapshot was created: 'supabase-20230126130703' (ID: 125670916) in regions 'ams3'
```

You'll be able to see the snapshot in the images section of the DigitalOcean UI.
![Snapshot UI](../assets/Snapshots-UI.png "Snapshot UI")

Now that we've created a snapshot with Docker and Docker Compose installed on it as well as the required `docker-compose.yml` and `conf` files, we will use Terraform to deploy all the resources required to have Supabase up and running on DigitalOcean.

* The next steps can be found in the [terraform directory](../terraform/).