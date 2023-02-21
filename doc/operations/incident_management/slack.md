---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Incident management for Slack **(FREE SAAS)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/344856) in GitLab 15.7 [with a flag](../../administration/feature_flags.md) named `incident_declare_slash_command`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `incident_declare_slash_command`.
On GitLab.com, this feature is not available.
The feature is not ready for production use.

Many teams receive alerts and collaborate in real time during incidents in Slack.
Use the GitLab for Slack app to:

- Create GitLab incidents from Slack.
- Receive incident notifications.
<!-- The below content is commented out until these features are implemented in https://gitlab.com/groups/gitlab-org/-/epics/8545 -->
<!-- - Send important updates between Slack and GitLab incidents. -->

Incident management for Slack is only available for GitLab.com. Some of the functionality
described might be available for
[the self-managed Slack app](../../user/project/integrations/slack_slash_commands.md).

To stay up to date, follow [epic 1211](https://gitlab.com/groups/gitlab-org/-/epics/1211).

## Manage an incident from Slack

Prerequisites:

1. Install the [GitLab for Slack app](../../user/project/integrations/gitlab_slack_application.md).
   This way, you can use slash commands in Slack to create and update GitLab incidents.
1. Enable [Slack notifications](../../user/project/integrations/slack.md). Be sure to enable
   notifications for `Incident` events, and to define a Slack channel to receive the relevant notifications.
1. Authorize GitLab to take actions on behalf of your Slack user.
   Each user must do this before they can use any of the incident slash commands.

   To start the authorization flow, try executing a non-incident [Slack slash command](../../integration/slash_commands.md),
   like `/gitlab <project-alias> issue show <id>`.
   The `<project-alias>` you select must be a project that has the GitLab for Slack app set up.
   For more context, visit [issue 377548](https://gitlab.com/gitlab-org/gitlab/-/issues/377548).

<!-- The below content is commented out until these features are implemented in https://gitlab.com/groups/gitlab-org/-/epics/8545 -->
<!--
To manage incidents, use the following slash commands in Slack:

| Command                            | Description                                 |
| ---------------------------------- | ------------------------------------------- |
| `/gitlab incident declare`         | Creates an incident in GitLab.              |
| `/gitlab incident comment <text>`  | Adds a comment on a GitLab incident.        |
| `/gitlab incident timeline <text>` | Adds a timeline event to a GitLab incident. |
| `/gitlab incident close`           | Closes an incident in GitLab.               |
-->

After the GitLab for Slack app is configured, you can also use any of the existing [Slack slash commands](../../user/project/integrations/slack_slash_commands.md).

## Declare an incident

To declare a GitLab incident from Slack:

1. In Slack, in any channel or DM, enter the `/gitlab incident declare` slash command.
1. From the modal, select the relevant incident details, including:

   - The incident title and description.
   - The project where the incident should be created.
   - The severity of the incident.

   If there is an existing [incident template](../metrics/alerts.md#trigger-actions-from-alerts) for your
   project, that template is automatically applied to the description text box. The template is applied
   only if the description text box is empty.

   You can also include GitLab [quick actions](../../user/project/quick_actions.md) in the description text box.
   For example, entering `/link https://example.slack.com/archives/123456789 Dedicated Slack channel`
   adds a dedicated Slack channel to the incident you create. For a complete list of
   quick actions for incidents, see [Use GitLab quick actions](#use-gitlab-quick-actions).
1. Optional. Add a link to an existing Zoom meeting.
1. Select **Create**.

If the incident is successfully created, Slack shows a confirmation notification.

### Use GitLab quick actions

Use [quick actions](../../user/project/quick_actions.md) in the description text box when creating
a GitLab incident from Slack. The following quick actions might be most relevant to you:

| Command                  | Description                               |
| ------------------------ | ----------------------------------------- |
| `/assign @user1 @user2`  | Adds an assignee to the GitLab incident.  |
| `/label ~label1 ~label2` | Adds labels to the GitLab incident.       |
| `/link <URL> <text>`     | Adds a link to a dedicated Slack channel, runbook, or any relevant resource to the `Related resources` section of an incident. |
| `/zoom <URL>`            | Adds a Zoom meeting link to the incident. |

<!-- The below content is commented out until these features are implemented in https://gitlab.com/groups/gitlab-org/-/epics/8545 -->
<!-- ### Comment on a GitLab incident

To comment on a GitLab incident from Slack, enter the `/gitlab incident comment <text>` slash command.
Slack shows a prompt asking you to confirm which incident you'd like to post your comment to.

### Add a timeline event

To add a [timeline event](incident_timeline_events.md) to a GitLab incident from Slack, enter the
`/gitlab incident timeline <text>` slash command.
Slack shows a prompt asking you to confirm which incident you'd like to add your timeline event to.

### Close an incident

To close a GitLab incident from Slack when it is resolved, enter the `/gitlab incident close`
slash command.
Slack shows a prompt asking you to confirm which incident you'd like to close.  -->

## Send GitLab incident notifications to Slack

If you have [enabled notifications](#manage-an-incident-from-slack) for incidents, you should receive
notifications to the selected Slack channel every time an incident is opened, closed, or updated.
