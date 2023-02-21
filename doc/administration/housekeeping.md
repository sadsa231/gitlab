---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Housekeeping **(FREE SELF)**

GitLab supports and automates housekeeping tasks in Git repositories to ensure
that they can be served as efficiently as possible. Housekeeping tasks include:

- Compressing Git objects and revisions.
- Removing unreachable objects.
- Removing stale data like lock files.
- Maintaining data structures that improve performance.
- Updating object pools to improve object deduplication across forks.

WARNING:
Do not manually execute Git commands to perform housekeeping in Git
repositories that are controlled by GitLab. Doing so may lead to corrupt
repositories and data loss.

## Housekeeping strategy

Gitaly can perform housekeeping tasks in a Git repository in two ways:

- [Eager housekeeping](#eager-housekeeping) executes specific housekeeping tasks
  independent of the state a repository is in.
- [Heuristical housekeeping](#heuristical-housekeeping) executes housekeeping
  tasks based on a set of heuristics that determine what housekeeping tasks need
  to be executed based on the repository state.

### Eager housekeeping

The "eager" housekeeping strategy executes housekeeping tasks in a repository
independent of the repository state. This is the default strategy as used by the
[manual trigger](#manual-trigger) and the push-based trigger.

The eager housekeeping strategy is controlled by the GitLab application.
Depending on the trigger that caused the housekeeping job to run, GitLab asks
Gitaly to perform specific housekeeping tasks. Gitaly performs these tasks even
if the repository is in an optimized state. As a result, this strategy can be
inefficient in large repositories where performing the housekeeping tasks may
be slow.

### Heuristical housekeeping

> - [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/2634) in GitLab 14.9 for the [manual trigger](#manual-trigger) and the push-based trigger [with a flag](feature_flags.md) named `optimized_housekeeping`. Enabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/353607) in GitLab 14.10.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661) in GitLab 15.8. Feature flag `optimized_housekeeping` removed.

The heuristical (or "opportunistic") housekeeping strategy analyzes the
repository's state and executes housekeeping tasks only when it finds one or
more data structures are insufficiently optimized. This is the strategy used by
[scheduled housekeeping](#scheduled-housekeeping).

Heuristical housekeeping uses the following information to decide on the tasks
it needs to run:

- The number of loose and stale objects.
- The number of packfiles that contain already-compressed objects.
- The number of loose references.
- The presence of a commit-graph.

The decision whether any of the analyzed data structures need to be optimized is
based on the size of the repository:

- Objects are repacked frequently the bigger the total size of all objects.
- References are repacked less frequently the more references there are in
  total.

Gitaly does this to offset the fact that optimizing those data structures takes
more time the bigger they get. It is especially important in large
monorepos (which receive a lot of traffic) to avoid optimizing them too
frequently.

You can change how often Gitaly is asked to optimize a repository.

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Repository**.
1. Expand **Repository maintenance**.
1. In the **Housekeeping** section, configure the housekeeping options.
1. Select **Save changes**.

- **Enable automatic repository housekeeping**: Regularly ask Gitaly to run repository optimization. If you
  keep this setting disabled for a long time, Git repository access on your GitLab server becomes
  slower and your repositories use more disk space.
- **Optimize repository period**: Number of Git pushes after which Gitaly is asked to optimize a repository.

## Running housekeeping tasks

There are different ways in which GitLab runs housekeeping tasks:

- A project's administrator can [manually trigger](#manual-trigger) repository
  housekeeping tasks.
- GitLab can automatically schedule housekeeping tasks after a number of Git pushes.
- GitLab can [schedule a job](#scheduled-housekeeping) that runs housekeeping
  tasks for all repositories in a configurable time frame.

### Manual trigger

Administrators of repositories can manually trigger housekeeping tasks in a
repository. In general this is not required as GitLab knows to automatically run
housekeeping tasks. The manual trigger can be useful when either:

- A repository is known to require housekeeping.
- Automated push-based scheduling of housekeeping tasks has been disabled.

To trigger housekeeping tasks manually:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. Select **Run housekeeping**.

This starts an asynchronous background worker for the project's repository. The
background worker asks Gitaly to perform a number of optimizations.

Housekeeping also [removes unreferenced LFS files](../raketasks/cleanup.md#remove-unreferenced-lfs-files)
from your project every `200` push, freeing up storage space for your project.

### Scheduled housekeeping

While GitLab automatically performs housekeeping tasks based on the number of
pushes, it does not maintain repositories that don't receive any pushes at all.
As a result, inactive repositories or repositories that are only getting read
requests may not benefit from improvements in the repository housekeeping
strategy.

Administrators can enable a background job that performs housekeeping in all
repositories at a customizable interval to remedy this situation. This
background job processes all repositories hosted by a Gitaly node in a random
order and eagerly performs housekeeping tasks on them. The Gitaly node stops
processing repositories if it takes longer than the configured interval.

#### Configure scheduled housekeeping

Background maintenance of Git repositories is configured in Gitaly. By default,
Gitaly performs background repository maintenance every day at 12:00 noon for a
duration of 10 minutes.

You can change this default in Gitaly configuration. The following snippet
enables daily background repository maintenance starting at 23:00 for 1 hour
for the `default` storage:

```toml
[daily_maintenance]
start_hour = 23
start_minute = 00
duration = 1h
storages = ["default"]
```

Use the following snippet to completely disable background repository
maintenance:

```toml
[daily_maintenance]
disabled = true
```

## Object pool repositories

Object pool repositories are used by GitLab to deduplicate objects across forks
of a repository. When creating the first fork, we:

1. Create an object pool repository that contains all objects of the repository
   that is about to be forked.
1. Link the repository to this new object pool via the alternates mechanism of Git.
1. Repack the repository so that it uses objects from the object pool. It thus
   can drop its own copy of the objects.

Any forks of this repository can now link against the object pool and thus only
have to keep objects that diverge from the primary repository.

GitLab needs to perform special housekeeping operations in object pools:

- Gitaly cannot ever delete unreachable objects from object pools because they
  might be used by any of the forks that are connected to it.
- Gitaly must keep all objects reachable due to the same reason. Object pools
  thus maintain references to unreachable "dangling" objects so that they don't
  ever get deleted.
- GitLab must update object pools regularly to pull in new objects that have
  been added in the primary repository. Otherwise, an object pool becomes
  increasingly inefficient at deduplicating objects.

These housekeeping operations are performed by the specialized
`FetchIntoObjectPool` RPC that handles all of these special tasks while also
executing the regular housekeeping tasks we execute for standard Git
repositories.

Object pools are getting optimized automatically whenever the primary member is
getting garbage collected. Therefore, the cadence can be configured using the
same Git GC period in that project.

If you need to manually invoke the RPC from a [Rails console](operations/rails_console.md),
you can call `project.pool_repository.object_pool.fetch`. This is a potentially
long-running task, though Gitaly times out after about 8 hours.
