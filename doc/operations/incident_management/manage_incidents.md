---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Manage incidents **(FREE)**

This page collects instructions for all the things you can do with [incidents](incidents.md) or in relation to them.

## Create an incident

You can create an incident manually or automatically.

### From the incidents list

> - [Moved](https://gitlab.com/gitlab-org/monitor/monitor/-/issues/24) to GitLab Free in 13.3.
> - [Permission changed](https://gitlab.com/gitlab-org/gitlab/-/issues/336624) from Guest to Reporter in GitLab 14.5.
> - Automatic application of the `incident` label [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/290964) in GitLab 14.8.

Prerequisites:

- You must have at least the Reporter role for the project.

To create an incident from the incidents list:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Monitor > Incidents**.
1. Select **Create incident**.

### From the issues list

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/230857) in GitLab 13.4.

Prerequisites:

- You must have at least the Reporter role for the project.

To create an incident from the issues list:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Issues > List**, and select **New issue**.
1. From the **Type** dropdown list, select **Incident**. Only fields relevant to
   incidents are available on the page.
1. Select **Create issue**.

### From an alert

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217745) in GitLab 13.1.

Create an incident issue when viewing an [alert](alerts.md).
The incident description is populated from the alert.

Prerequisites:

- You must have at least the Developer role for the project.

To create an incident from an alert:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Monitor > Alerts**.
1. Select your desired alert.
1. Select **Create incident**.

After an incident is created, to view it from the alert, select **View incident**.

When you [close an incident](#close-an-incident) linked to an alert, GitLab
[changes the alert's status](alerts.md#change-an-alerts-status) to **Resolved**.
You are then credited with the alert's status change.

### Automatically, when an alert is triggered **(ULTIMATE)**

In the project settings, you can turn on [creating an incident automatically](../metrics/alerts.md#trigger-actions-from-alerts)
whenever an alert is triggered.

### Using the PagerDuty webhook

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/119018) in GitLab 13.3.
> - [PagerDuty V3 Webhook](https://support.pagerduty.com/docs/webhooks) support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383029) in GitLab 15.7.

You can set up a webhook with PagerDuty to automatically create a GitLab incident
for each PagerDuty incident. This configuration requires you to make changes
in both PagerDuty and GitLab.

Prerequisites:

- You must have at least the Maintainer role for the project.

To set up a webhook with PagerDuty:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Monitor**
1. Expand **Incidents**.
1. Select the **PagerDuty integration** tab.
1. Turn on the **Active** toggle.
1. Select **Save integration**.
1. Copy the value of **Webhook URL** for use in a later step.
1. To add the webhook URL to a PagerDuty webhook integration, follow the steps described in the [PagerDuty documentation](https://support.pagerduty.com/docs/webhooks#manage-v3-webhook-subscriptions).

To confirm the integration is successful, trigger a test incident from PagerDuty to
check if a GitLab incident is created from the incident.

## View incidents list

To view the [incidents list](incidents.md#incidents-list):

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Monitor > Incidents**.

To view an incident's [details page](incidents.md#incident-details), select it from the list.

### Who can view an incident

Whether you can view an incident depends on the [project visibility level](../../user/public_access.md) and
the incident's confidentiality status:

- Public project and a non-confidential incident: You don't have to be a member of the project.
- Private project and non-confidential incident: You must have at least the Guest role for the project.
- Confidential incident (regardless of project visibility): You must have at least the Reporter role for the project.

## Assign to a user

Assign incidents to users that are actively responding.

Prerequisites:

- You must have at least the Reporter role for the project.

To assign a user:

1. In an incident, on the right sidebar, next to **Assignees**, select **Edit**.
1. From the dropdown list, select one or [multiple users](../../user/project/issues/multiple_assignees_for_issues.md) to add as **assignees**.
1. Select any area outside the dropdown list.

## Change severity

> Editing severity on incident details page was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/229402) in GitLab 13.4.

See [incident list](incidents.md#incidents-list) for a full description of the severity levels available.

Prerequisites:

- You must have at least the Reporter role for the project.

To change an incident's severity:

1. In an incident, on the right sidebar, next to **Severity**, select **Edit**.
1. From the dropdown list, select the new severity.

You can also change the severity using the `/severity` [quick action](../../user/project/quick_actions.md).

## Change status

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5716) in GitLab 14.9 [with a flag](../../administration/feature_flags.md) named `incident_escalations`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) in GitLab 14.10.
> - [Feature flag `incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769) removed in GitLab 15.1.

Prerequisites:

- You must have at least the Developer role for the project.

To change the status of an incident:

1. In an incident, on the right sidebar, next to **Status**, select **Edit**.
1. From the dropdown list, select the new severity.

**Triggered** is the default status for new incidents.

### As an on-call responder **(PREMIUM)**

On-call responders can respond to [incident pages](paging.md#escalating-an-incident)
by changing the status.

Changing the status has the following effects:

- To **Acknowledged**: limits on-call pages based on the project's [escalation policy](escalation_policies.md).
- To **Resolved**: silences all on-call pages for the incident.
- From **Resolved** to **Triggered**: restarts the incident escalating.

In GitLab 15.1 and earlier, changing the status of an [incident created from an alert](#from-an-alert)
also changes the alert status. In [GitLab 15.2 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/356057),
the alert status is independent and does not change when the incident status changes.

## Change escalation policy **(PREMIUM)**

Prerequisites:

- You must have at least the Developer role for the project.

To change the escalation policy of an incident:

1. In an incident, on the right sidebar, next to **Escalation policy**, select **Edit**.
1. From the dropdown list, select the escalation policy.

By default, new incidents do not have an escalation policy selected.

Selecting an escalation policy [changes the incident status](#change-status) to **Triggered** and begins
[escalating the incident to on-call responders](paging.md#escalating-an-incident).

In GitLab 15.1 and earlier, the escalation policy for [incidents created from alerts](#from-an-alert)
reflects the alert's escalation policy and cannot be changed. In [GitLab 15.2 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/356057),
the incident escalation policy is independent and can be changed.

## Embed metrics

You can embed metrics anywhere [GitLab Flavored Markdown](../../user/markdown.md) is
used, like descriptions or comments. Embedding
metrics helps you share them when discussing incidents or performance issues.

To embed metrics in a Markdown text box in GitLab,
[paste the link to the dashboard](../metrics/embed.md#embedding-gitlab-managed-kubernetes-metrics).

You can embed both [GitLab-hosted metrics](../metrics/embed.md) (deprecated) and
[Grafana metrics](../metrics/embed_grafana.md) in incidents and issue
templates.

## Close an incident

Prerequisites:

- You must have at least the Reporter role for the project.

To close an incident, in the top right, select **Close incident**.

When you close an incident that is linked to an [alert](alerts.md),
the linked alert's status changes to **Resolved**.
You are then credited with the alert's status change.

### Automatically close incidents via recovery alerts

> [Introduced for HTTP integrations](https://gitlab.com/gitlab-org/gitlab/-/issues/13402) in GitLab 13.4.

Turn on closing an incident automatically when GitLab receives a recovery alert
from a HTTP or Prometheus webhook.

Prerequisites:

- You must have at least the Maintainer role for the project.

To configure the setting:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Monitor**.
1. Expand the **Incidents** section.
1. Select the **Automatically close associated incident** checkbox.
1. Select **Save changes**.

When GitLab receives a recovery alert, it closes the associated incident.
This action is recorded as a system note on the incident indicating that it
was closed automatically by the GitLab Alert bot.

## Other actions

Because incidents in GitLab are built on top of [issues](../../user/project/issues/index.md),
they have the following actions in common:

- [Add a to-do item](../../user/todos.md#create-a-to-do-item)
- [Add labels](../../user/project/labels.md#assign-and-unassign-labels)
- [Assign a milestone](../../user/project/milestones/index.md#assign-a-milestone-to-an-issue-or-merge-request)
- [Make an incident confidential](../../user/project/issues/confidential_issues.md)
- [Set a due date](../../user/project/issues/due_dates.md)
- [Toggle notifications](../../user/profile/notifications.md#edit-notification-settings-for-issues-merge-requests-and-epics)
- [Track time spent](../../user/project/time_tracking.md)
