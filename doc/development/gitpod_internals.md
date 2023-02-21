---
stage: none
group: Engineering Productivity
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Gitpod internal configuration

## Settings

The settings for `gitlab-org/gitlab` are defined under a [project's settings in a Gitpod dashboard](https://gitpod.io/t/gitlab-org/gitlab/settings). To view the settings, you must first join the `gitlab-org` team on [Gitpod.io](https://gitpod.io/). You can join the team using the bookmark link at the top of `#gitpod-gdk` internal Slack channel.

The current settings are:

- `Enable Incremental Prebuilds`: Uses an earlier successful prebuild to create new prebuilds faster.
- `Use Last Successful Prebuild`: Skips waiting for prebuilds currently in progress and uses the last successful prebuild from previous commits on the same branch.

## Webhooks

A webhook that starts with `https://gitpod.io/` is created to enable prebuilds (see [Enabling Prebuilds](https://www.gitpod.io/docs/configure/authentication/gitlab#enabling-prebuilds) for more details). The webhook is maintained by an [Engineering Productivity team](https://about.gitlab.com/handbook/engineering/quality/engineering-productivity/).

You can find this webhook in [Webhook Settings in `gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab/-/hooks). If you cannot access this setting, please chat to the [Engineering Productivity team](https://about.gitlab.com/handbook/engineering/quality/engineering-productivity/).

### Troubleshooting a failed webhook

If a webhook failed to connect for a long time, then it may have been disabled in the project.

To re-enable a failing or failed webhook, send a test request in [Webhook Settings](https://gitlab.com/gitlab-org/gitlab/-/hooks). See [Re-enable disabled webhooks page](https://docs.gitlab.com/15.4/ee/user/project/integrations/webhooks.html#re-enable-disabled-webhooks) for more details.

After re-enabling, check the prebuilds' health in a [project's prebuilds](https://gitpod.io/t/gitlab-org/gitlab/prebuilds) and confirm that prebuilds start without any errors.
