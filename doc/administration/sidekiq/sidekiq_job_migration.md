---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Sidekiq job migration Rake tasks **(FREE SELF)**

WARNING:
This operation should be very uncommon. We do not recommend it for the vast majority of GitLab instances.

Sidekiq routing rules allow administrators to re-route certain background jobs from their regular queue to an alternative queue. By default, GitLab uses one queue per background job type. GitLab has over 400 background job types, and so correspondingly it has over 400 queues.

Most administrators do not need to change this setting. In some cases with particularly large background job processing workloads, Redis performance may suffer due to the number of queues that GitLab listens to.

If the Sidekiq routing rules are changed, administrators need to take care with the migration to avoid losing jobs entirely. The basic migration steps are:

1. Listen to both the old and new queues.
1. Update the routing rules.
1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Run the [Rake tasks for migrating queued and future jobs](#migrate-queued-and-future-jobs).
1. Stop listening to the old queues.

## Migrate queued and future jobs

Step 4 involves rewriting some Sidekiq job data for jobs that are already stored in Redis, but due to run in future. There are two sets of jobs to run in future: scheduled jobs and jobs to be retried. We provide a separate Rake task to migrate each set:

- `gitlab:sidekiq:migrate_jobs:retry` for jobs to be retried.
- `gitlab:sidekiq:migrate_jobs:scheduled` for scheduled jobs.

Queued jobs that are yet to be run can also be migrated with a Rake task:

- `gitlab:sidekiq:migrate_jobs:queued` for queued jobs to be performed asynchronously.

Most of the time, running all three at the same time is the correct choice. There are three separate tasks to allow for more fine-grained control where needed. To run all three at once:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued

# source installations
bundle exec rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued RAILS_ENV=production
```
