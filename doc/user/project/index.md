---
stage: Manage
group: Organization
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Create a project **(FREE)**

You can create a project in many ways in GitLab.

## Create a blank project

To create a blank project:

1. On the top bar, select **Main menu > Projects > View all projects**.
1. On the right of the page, select **New project**.
1. Select **Create blank project**.
1. Enter the project details:
   - In the **Project name** field, enter the name of your project. You cannot use special characters at
     the start or end of a project name.
   - In the **Project slug** field, enter the path to your project. The GitLab instance uses the
     slug as the URL path to the project. To change the slug, first enter the project name,
     then change the slug.
   - In the **Project deployment target (optional)** field, select your project's deployment target.
     This information helps GitLab better understand its users and their deployment requirements.
   - To modify the project's [viewing and access rights](../public_access.md) for
     users, change the **Visibility Level**.
   - To create README file so that the Git repository is initialized, has a default branch, and
     can be cloned, select **Initialize repository with a README**.
   - To analyze the source code in the project for known security vulnerabilities,
     select **Enable Static Application Security Testing (SAST)**.
1. Select **Create project**.

## Create a project from a built-in template

A built-in project template populates a new project with files to get you started.
Built-in templates are sourced from the following groups:

- [`project-templates`](https://gitlab.com/gitlab-org/project-templates)
- [`pages`](https://gitlab.com/pages)

Anyone can [contribute a built-in template](../../development/project_templates.md).

To create a project from a built-in template:

1. On the top bar, select **Main menu > Projects > View all projects**.
1. On the right of the page, select **New project**.
1. Select **Create from template**.
1. Select the **Built-in** tab.
1. From the list of templates:
   - To view a preview of the template, select **Preview**.
   - To use a template for the project, select **Use template**.
1. Enter the project details:
   - In the **Project name** field, enter the name of your project. You cannot use special characters at
     the start or end of a project name.
   - In the **Project slug** field, enter the path to your project. The GitLab instance uses the
     slug as the URL path to the project. To change the slug, first enter the project name,
     then change the slug.
   - In the **Project description (optional)** field, enter the description of your project's dashboard.
   - To modify the project's [viewing and access rights](../public_access.md) for users,
     change the **Visibility Level**.
1. Select **Create project**.

NOTE:
A user who creates a project [from a template](#create-a-project-from-a-built-in-template) or [by import](settings/import_export.md#import-a-project-and-its-data) is displayed as the author of the imported objects (such as issues and merge requests), which keep the original timestamp from the template or import.
Imported objects are labeled as `By <username> on <timestamp> (imported from GitLab)`.
For this reason, the creation date of imported objects can be older than the creation date of the user's account. This can lead to objects appearing to have been created by a user before they even had an account.

## Create a project from a custom template **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/6860) in GitLab 11.2.

Custom project templates are available at:

- The [instance-level](../../user/admin_area/custom_project_templates.md)
- The [group-level](../../user/group/custom_project_templates.md)

1. On the top bar, select **Main menu > Projects > View all projects**.
1. On the right of the page, select **New project**.
1. Select **Create from template**.
1. Select the **Instance** or **Group** tab.
1. From the list of templates:
   - To view a preview of the template, select **Preview**.
   - To use a template for the project, select **Use template**.
1. Enter the project details:
   - In the **Project name** field, enter the name of your project. You cannot use special characters at
     the start or end of a project name.
   - In the **Project slug** field, enter the path to your project. The GitLab instance uses the
     slug as the URL path to the project. To change the slug, first enter the project name,
     then change the slug.
   - The description of your project's dashboard in the **Project description (optional)** field.
   - To modify the project's [viewing and access rights](../public_access.md) for users,
     change the **Visibility Level**.
1. Select **Create project**.

## Create a project from the HIPAA Audit Protocol template **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13756) in GitLab 12.10

The HIPAA Audit Protocol template contains issues for audit inquiries in the
HIPAA Audit Protocol published by the U.S Department of Health and Human Services.

To create a project from the HIPAA Audit Protocol template:

1. On the top bar, select **Main menu > Projects > View all projects**.
1. On the right of the page, select **New project**.
1. Select **Create from template**.
1. Select the **Built-in** tab.
1. Locate the **HIPAA Audit Protocol** template:
   - To view a preview of the template, select **Preview**.
   - To use the template for the project, select **Use template**.
1. Enter the project details:
   - In the **Project name** field, enter the name of your project. You cannot use special characters at
     the start or end of a project name.
   - In the **Project slug** field, enter the path to your project. The GitLab instance uses the
     slug as the URL path to the project. To change the slug, first enter the project name,
     then change the slug.
   - In the **Project description (optional)** field, enter the description of your project's dashboard.
   - To modify the project's [viewing and access rights](../public_access.md) for users,
     change the **Visibility Level**.
1. Select **Create project**.

## Create a new project with Git push

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/26388) in GitLab 10.5.

Use `git push` to push a local project repository to GitLab. After you push a repository,
GitLab creates your project in your chosen namespace.

You cannot use `git push` to create projects with project paths that:

- Have previously been used.
- Have been [renamed](settings/index.md#rename-a-repository).

Previously used project paths have a redirect. The redirect causes push attempts to redirect requests
to the renamed project location, instead of creating a new project. To create a new project for a previously
used or renamed project, use the [UI](#create-a-project) or the [Projects API](../../api/projects.md#create-project).

Prerequisites:

- To push with SSH, you must have [an SSH key](../ssh.md) that is
  [added to your GitLab account](../ssh.md#add-an-ssh-key-to-your-gitlab-account).
- You must have permission to add new projects to a namespace. To check if you have permission:

  1. On the top bar, select **Main menu > Groups** and find your group.
  1. Confirm that **New project** is visible in the upper right
     corner. Contact your GitLab
     administrator if you require permission.

To push your repository and create a project:

1. Push with SSH or HTTPS:
   - To push with SSH:

      ```shell
      git push --set-upstream git@gitlab.example.com:namespace/myproject.git master
      ```

   - To push with HTTPS:

      ```shell
      git push --set-upstream https://gitlab.example.com/namespace/myproject.git master
      ```

   - For `gitlab.example.com`, use the domain name of the machine that hosts your Git repository.
   - For `namespace`, use the name of your [namespace](../namespace/index.md).
   - For `myproject`, use the name of your project.
   - Optional. To export existing repository tags, append the `--tags` flag to your `git push` command.
1. Optional. To configure the remote:

   ```shell
   git remote add origin https://gitlab.example.com/namespace/myproject.git
   ```

When the push completes, GitLab displays the message:

```shell
remote: The private project namespace/myproject was created.
```

To view your new project, go to `https://gitlab.example.com/namespace/myproject`.
Your project's visibility is set to **Private** by default. To change project visibility, adjust your
[project's settings](../public_access.md#change-project-visibility).

## Related topics

- For a list of words that you cannot use as project names, see
  [reserved project and group names](../../user/reserved_names.md).
- For a list of characters that you cannot use in project and group names, see
  [limitations on project and group names](../../user/reserved_names.md#limitations-on-project-and-group-names).
- [Manage projects](working_with_projects.md).
