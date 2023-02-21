---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Container Registry **(FREE)**

> Searching by image repository name was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31322) in GitLab 13.0.

You can use the integrated Container Registry to store container images for each GitLab project

To enable the Container Registry for your GitLab instance, see the [administrator documentation](../../../administration/packages/container_registry.md).

NOTE:
If you pull Docker container images from Docker Hub, you can use the
[GitLab Dependency Proxy](../dependency_proxy/index.md#use-the-dependency-proxy-for-docker-images) to avoid
rate limits and speed up your pipelines. For more information about the Docker Registry, see  <https://docs.docker.com/registry/introduction/>.

## View the Container Registry

You can view the Container Registry for a project or group.

1. On the top bar, select **Main menu**, and:
   - For a project, select **Projects** and find your project.
   - For a group, select **Groups** and find your group.
1. On the left sidebar, select **Packages and registries > Container Registry**.

You can search, sort, filter, and [delete](delete_container_registry_images.md#use-the-gitlab-ui)
 your container images. You can share a filtered view by copying the URL from your browser.

Only members of the project or group can access the Container Registry for a private project.
Container images downloaded from a private registry may be [available to other users in a shared runner](https://docs.gitlab.com/runner/security/index.html#usage-of-private-docker-images-with-if-not-present-pull-policy).

If a project is public, the Container Registry is also public.

### View the tags of a specific container image in the Container Registry

You can use the Container Registry **Tag Details** page to view a list of tags associated with a given container image:

1. On the top bar, select **Main menu**, and:
   - For a project, select **Projects** and find your project.
   - For a group, select **Groups** and find your group.
1. On the left sidebar, select **Packages and registries > Container Registry**.
1. Select your container image.

You can view details about each tag, such as when it was published, how much storage it consumes,
and the manifest and configuration digests.

You can search, sort (by tag name), filter, and [delete](delete_container_registry_images.md#use-the-gitlab-ui)
tags on this page. You can share a filtered view by copying the URL from your browser.

## Use container images from the Container Registry

To download and run a container image hosted in the Container Registry:

1. On the top bar, select **Main menu**, and:
   - For a project, select **Projects** and find your project.
   - For a group, select **Groups** and find your group.
1. On the left sidebar, select **Packages and registries > Container Registry**.
1. Find the container image you want to work with and select **Copy**.

    ![Container Registry image URL](img/container_registry_hover_path_13_4.png)

1. Use `docker run` with the copied link:

   ```shell
   docker run [options] registry.example.com/group/project/image [arguments]
   ```

NOTE:
You must [authenticate with the container registry](authenticate_with_container_registry.md) to download
container images from a private repository.

For more information on running container images, visit the [Docker documentation](https://docs.docker.com/get-started/).

## Naming convention for your container images

Your container images must follow this naming convention:

```plaintext
<registry URL>/<namespace>/<project>/<image>
```

For example, if your project is `gitlab.example.com/mynamespace/myproject`,
then your container image must be named `gitlab.example.com/mynamespace/myproject`.

You can append additional names to the end of a container image name, up to two levels deep.

For example, these are all valid names for container images in the project named `myproject`:

```plaintext
registry.example.com/mynamespace/myproject:some-tag
```

```plaintext
registry.example.com/mynamespace/myproject/image:latest
```

```plaintext
registry.example.com/mynamespace/myproject/my/image:rc1
```

## Move or rename Container Registry repositories

Moving or renaming existing Container Registry repositories is not supported after you have pushed
container images. The container images are stored in a path that matches the repository path. To move
or rename a repository with a Container Registry, you must delete all existing container images.
Community suggestions to work around this known issue are shared in
[issue 18383](https://gitlab.com/gitlab-org/gitlab/-/issues/18383#possible-workaround).

## Disable the Container Registry for a project

The Container Registry is enabled by default.

You can, however, remove the Container Registry for a project:

1. On the top bar, select **Main menu > Projects**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Visibility, project features, permissions** section
   and disable **Container Registry**.
1. Select **Save changes**.

The **Packages and registries > Container Registry** entry is removed from the project's sidebar.

## Change visibility of the Container Registry

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18792) in GitLab 14.2.

By default, the Container Registry is visible to everyone with access to the project.
You can, however, change the visibility of the Container Registry for a project.

For more information about the permissions that this setting grants to users,
see [Container Registry visibility permissions](#container-registry-visibility-permissions).

1. On the top bar, select **Main menu > Projects**.
1. On the left sidebar, select **Settings > General**.
1. Expand the section **Visibility, project features, permissions**.
1. Under **Container Registry**, select an option from the dropdown list:

   - **Everyone With Access** (Default): The Container Registry is visible to everyone with access
   to the project. If the project is public, the Container Registry is also public. If the project
   is internal or private, the Container Registry is also internal or private.

   - **Only Project Members**: The Container Registry is visible only to project members with
   Reporter role or higher. This visibility is similar to the behavior of a private project with Container
   Registry visibility set to **Everyone With Access**.

1. Select **Save changes**.

## Container Registry visibility permissions

The ability to view the Container Registry and pull container images is controlled by the Container Registry's
visibility permissions. You can change the visibility through the [visibility setting on the UI](#change-visibility-of-the-container-registry)
or the [API](../../../api/container_registry.md#change-the-visibility-of-the-container-registry).
[Other permissions](../../permissions.md) such as updating the Container Registry and pushing or deleting container images are not affected by
this setting. However, disabling the Container Registry disables all Container Registry operations.

|                                                                                                                   |                                               | Anonymous<br/>(Everyone on internet) | Guest | Reporter, Developer, Maintainer, Owner |
|-------------------------------------------------------------------------------------------------------------------|-----------------------------------------------|--------------------------------------|-------|----------------------------------------|
| Public project with Container Registry visibility <br/> set to **Everyone With Access** (UI) or `enabled` (API)   | View Container Registry <br/> and pull images | Yes                                  | Yes   | Yes                                    |
| Public project with Container Registry visibility <br/> set to **Only Project Members** (UI) or `private` (API)   | View Container Registry <br/> and pull images | No                                   | No    | Yes                                    |
| Internal project with Container Registry visibility <br/> set to **Everyone With Access** (UI) or `enabled` (API) | View Container Registry <br/> and pull images | No                                   | Yes   | Yes                                    |
| Internal project with Container Registry visibility <br/> set to **Only Project Members** (UI) or `private` (API) | View Container Registry <br/> and pull images | No                                   | No    | Yes                                    |
| Private project with Container Registry visibility <br/> set to **Everyone With Access** (UI) or `enabled` (API)  | View Container Registry <br/> and pull images | No                                   | No    | Yes                                    |
| Private project with Container Registry visibility <br/> set to **Only Project Members** (UI) or `private` (API)  | View Container Registry <br/> and pull images | No                                   | No    | Yes                                    |
| Any project with Container Registry `disabled`                                                                    | All operations on Container Registry          | No                                   | No    | No                                     |
