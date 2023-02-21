---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Deploy and release your application **(FREE)**

Deployment is the step of the software delivery process when your
application gets deployed to its final, target infrastructure.

You can deploy your application internally or to the public.
Preview a release in a Review App, and use feature flags to
release features incrementally.

- [Environments and deployments](../ci/environments/index.md)
- [Releases](../user/project/releases/index.md)
- [Review Apps](../ci/review_apps/index.md)
- [Feature flags](../operations/feature_flags.md)

## Related topics

- [Auto DevOps](autodevops/index.md) is an automated CI/CD-based workflow that supports the entire software
  supply chain: build, test, lint, package, deploy, secure, and monitor applications using GitLab CI/CD.
  It provides a set of ready-to-use templates that serve the vast majority of use cases.
- [Auto Deploy](autodevops/stages.md#auto-deploy) is the DevOps stage dedicated to software
  deployment using GitLab CI/CD. Auto Deploy has built-in support for EC2 and ECS deployments.
- Deploy to Kubernetes clusters by using the [GitLab agent](../user/clusters/agent/install/index.md).
- Use Docker images to run AWS commands from GitLab CI/CD, and a template to
  facilitate [deployment to AWS](../ci/cloud_deployment).
- Use GitLab CI/CD to target any type of infrastructure accessible by GitLab Runner.
  [User and pre-defined environment variables](../ci/variables/index.md) and CI/CD templates
  support setting up a vast number of deployment strategies.
- Use GitLab [Cloud Seed](../cloud_seed/index.md), an open-source Incubation Engineering program,
  to set up deployment credentials and deploy your application to Google Cloud Run with minimal friction.
