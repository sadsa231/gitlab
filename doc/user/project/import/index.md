---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Import and migrate projects **(FREE)**

If you want to bring existing projects to GitLab or copy GitLab projects to a different location, you can:

- Import projects from external systems using one of the [available importers](#available-project-importers).
- Migrate GitLab projects:
  - Between two GitLab self-managed instances.
  - Between a self-managed instance and GitLab.com in both directions.
  - In the same GitLab instance.

Prerequisite:

- At least the Maintainer role on the destination group to import to. Using the Developer role for this purpose was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/387891) in GitLab 15.8 and will be removed in GitLab 16.0.

For any type of source and target, you can migrate GitLab projects:

- When [migrating groups by direct transfer](../../group/import/index.md#migrate-groups-by-direct-transfer-recommended), which allows you to migrate all
  projects in a group at once. Migrating projects by direct transfer is in [Beta](../../../policy/alpha-beta-support.md#beta-features). The feature is not ready
  for production use.
- Using [file exports](../settings/import_export.md). With this method you can migrate projects one by one. No network
  connection between instances is required.

If you only need to migrate Git repositories, you can [import each project by URL](repo_by_url.md). However, you can't
import issues and merge requests this way. To retain metadata like issues and merge requests, either:

- [Migrate projects with groups by direct transfer](../../group/import/index.md#migrate-groups-by-direct-transfer-recommended). This feature is in [Beta](../../../policy/alpha-beta-support.md#beta-features). It is not ready for production use.
- Use [file exports](../settings/import_export.md) to import projects.

Keep in mind the limitations of [migrating using file exports](../settings/import_export.md#items-that-are-exported).
When migrating from self-managed to GitLab.com, user associations (such as comment author)
are changed to the user who is importing the projects.

## Available project importers

You can import projects from:

- [Bitbucket Cloud](bitbucket.md)
- [Bitbucket Server (also known as Stash)](bitbucket_server.md)
- [ClearCase](clearcase.md)
- [CVS](cvs.md)
- [FogBugz](fogbugz.md)
- [GitHub.com or GitHub Enterprise](github.md)
- [Gitea](gitea.md)
- [Perforce](perforce.md)
- [TFVC](tfvc.md)
- [Repository by URL](repo_by_url.md)
- [Uploading a manifest file (AOSP)](manifest.md)
- [Jira (issues only)](jira.md)

You can also import any Git repository through HTTP from the **New Project** page. If the repository
is too large, the import can timeout.

You can then [connect your external repository to get CI/CD benefits](../../../ci/ci_cd_for_external_repos/index.md).

## Import from Subversion

GitLab can not automatically migrate Subversion repositories to Git. Converting Subversion repositories to Git can be difficult, but several tools exist including:

- [`git svn`](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git), for very small and simple repositories.
- [`reposurgeon`](http://www.catb.org/~esr/reposurgeon/repository-editing.html), for larger and more complex repositories.

## Migrate using the API

To migrate all data from self-managed to GitLab.com, you can leverage the [API](../../../api/rest/index.md).
Migrate the assets in this order:

1. [Groups](../../../api/groups.md)
1. [Projects](../../../api/projects.md)
1. [Project variables](../../../api/project_level_variables.md)

You must still migrate your [Container Registry](../../packages/container_registry/index.md)
over a series of Docker pulls and pushes. Re-run any CI pipelines to retrieve any build artifacts.

## Migrate between two self-managed GitLab instances

To migrate from an existing self-managed GitLab instance to a new self-managed GitLab instance, it's
best to [back up](../../../raketasks/backup_restore.md)
the existing instance and restore it on the new instance. For example, this is useful when migrating
a self-managed instance from an old server to a new server.

The backups produced don't depend on the operating system running GitLab. You can therefore use
the restore method to switch between different operating system distributions or versions, as long
as the same GitLab version [is available for installation](../../../administration/package_information/supported_os.md).

Administrators can use the [Users API](../../../api/users.md) to migrate users.

## View project import history

You can view all project imports created by you. This list includes the following:

- Paths of source projects if projects were imported from external systems, or import method if GitLab projects were migrated.
- Paths of destination projects.
- Start date of each import.
- Status of each import.
- Error details if any errors occurred.

To view project import history:

1. Sign in to GitLab.
1. On the top bar, select **Create new...** (**{plus-square}**).
1. Select **New project/repository**.
1. Select **Import project**.
1. Select **History** in the upper right corner.
1. If there are any errors for a particular import, you can see them by selecting **Details**.

The history also includes projects created from [built-in](../index.md#create-a-project-from-a-built-in-template)
or [custom](../index.md#create-a-project-from-a-built-in-template)
templates. GitLab uses [import repository by URL](repo_by_url.md)
to create a new project from a template.

## LFS authentication

When importing a project that contains LFS objects, if the project has an [`.lfsconfig`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-config.adoc)
file with a URL host (`lfs.url`) different from the repository URL host, LFS files are not downloaded.

## Project aliases **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3264) in GitLab 12.1.

GitLab repositories are usually accessed with a namespace and a project name. When migrating
frequently accessed repositories to GitLab, however, you can use project aliases to access those
repositories with the original name. Accessing repositories through a project alias reduces the risk
associated with migrating such repositories.

This feature is only available on Git over SSH. Also, only GitLab administrators can create project
aliases, and they can only do so through the API. For more information, see the
[Project Aliases API documentation](../../../api/project_aliases.md).

After an administrator creates an alias for a project, you can use the alias to clone the
repository. For example, if an administrator creates the alias `gitlab` for the project
`https://gitlab.com/gitlab-org/gitlab`, you can clone the project with
`git clone git@gitlab.com:gitlab.git` instead of `git clone git@gitlab.com:gitlab-org/gitlab.git`.

## Automate group and project import **(PREMIUM)**

The GitLab Professional Services team uses [Congregate](https://gitlab.com/gitlab-org/professional-services-automation/tools/migration/congregate)
to orchestrate user, group, and project import API calls. With Congregate, you can migrate data to
GitLab from:

- Other GitLab instances
- GitHub Enterprise
- GitHub.com
- Bitbucket Server
- Bitbucket Data Center

For more information, see:

- [Quick Start](https://gitlab.com/gitlab-org/professional-services-automation/tools/migration/congregate/-/blob/master/docs/using-congregate.md#quick-start).
- [Frequently Asked Migration Questions](https://gitlab.com/gitlab-org/professional-services-automation/tools/migration/congregate/-/blob/master/customer/famq.md),
  including settings that need checking afterwards and other limitations.

For support, customers must enter into a paid engagement with GitLab Professional Services.
