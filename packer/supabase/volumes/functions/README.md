# Supabase Edge Function Placeholders

This directory and its subdirectories serve as **placeholders** for Supabase Edge Functions. No actual edge function code is stored here by default.

## How Edge Functions Are Deployed

Actual edge functions will be developed and deployed from a separate repository specific to the project that uses these edge functions. This means:

- The files and directories here are only for structure, initialization testing, and placeholder purposes.
- When deploying or updating edge functions, you should do so from your project's own repository, not from within this module.
- This keeps the Terraform module generic and reusable across different projects, while allowing each project to manage its own edge function logic and codebase.

## Summary
- **Do not place production edge function code here.**
- **Use your project's repository for actual edge function development and deployment.**