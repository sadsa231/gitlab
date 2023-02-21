---
stage: Create
group: Code Review
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference
---

# Issue closing pattern **(FREE SELF)**

NOTE:
This is the administration documentation. There is a separate [user documentation](../user/project/issues/managing_issues.md#closing-issues-automatically)
on issue closing pattern.

When a commit or merge request resolves one or more issues, it is possible to
automatically close these issues when the commit or merge request lands
in the project's default branch.

## Change the issue closing pattern

The [default issue closing pattern](../user/project/issues/managing_issues.md#default-closing-pattern)
covers a wide range of words. You can change the pattern to suit your needs.

NOTE:
You are advised to use <https://rubular.com> to test the issue closing pattern.
However, since Rubular doesn't understand `%{issue_ref}`, you can replace this by
`#\d+` when testing your patterns, which matches only local issue references like `#123`.

To change the default issue closing pattern:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and change the `gitlab_rails['gitlab_issue_closing_pattern']`
   value:

   ```ruby
   gitlab_rails['gitlab_issue_closing_pattern'] = /<regular_expression>/.source
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml` and change the `issueClosingPattern` value:

   ```yaml
   global:
     appConfig:
       issueClosingPattern: "<regular_expression>"
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml` and change the `gitlab_rails['gitlab_issue_closing_pattern']`
   value:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['gitlab_issue_closing_pattern'] = /<regular_expression>/.source
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml` and change the `issue_closing_pattern` value:

   ```yaml
   production: &base
     gitlab:
       issue_closing_pattern: "<regular_expression>"
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs
