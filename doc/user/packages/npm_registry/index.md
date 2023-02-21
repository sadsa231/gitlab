---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# npm packages in the Package Registry **(FREE)**

For documentation of the specific API endpoints that the npm package manager client uses, see the [npm API documentation](../../../api/packages/npm.md).

Learn how to build an [npm](../workflows/build_packages.md#npm) or [yarn](../workflows/build_packages.md#yarn) package.

Watch a [video demo](https://youtu.be/yvLxtkvsFDA) of how to publish npm packages to the GitLab Package Registry.

## Publish to GitLab Package Registry

### Authentication to the Package Registry

You need an token to publish a package. There are different tokens available depending on what you're trying to achieve. For more information, review the [guidance on tokens](../../../user/packages/package_registry/index.md#authenticate-with-the-registry).

- If your organization uses two factor authentication (2FA), you must use a personal access token with the scope set to `api`.
- If you are publishing a package via CI/CD pipelines, you must use a CI job token.

Create a token and save it to use later in the process.

### Naming convention

Depending on how the package is installed, you may need to adhere to the naming convention.

You can use one of two API endpoints to install packages:

- **Instance-level**: Use when you have many npm packages in different GitLab groups or in their own namespace.
- **Project-level**: Use when you have few npm packages and they are not in the same GitLab group.

If you plan to install a package through the [project level](#install-from-the-project-level), then you do not have to adhere to the naming convention.

If you plan to install a package through the [instance level](#install-from-the-instance-level), then you must name your package with a [scope](https://docs.npmjs.com/misc/scope/). Scoped packages begin with a `@` have the format of `@owner/package-name`. You can set up the scope for your package in the `.npmrc` file and by using the `publishConfig` option in the `package.json`.

- The value used for the `@scope` is the root of the project that is hosting the packages and not the root
  of the project with the source code of the package itself. The scope should be lowercase.
- The package name can be anything you want

| Project URL                                             | Package Registry in | Scope     | Full package name      |
| ------------------------------------------------------- | ------------------- | --------- | ---------------------- |
| `https://gitlab.com/my-org/engineering-group/analytics` | Analytics           | `@my-org` | `@my-org/package-name` |

Make sure that the name of your package in the `package.json` file matches this convention:

```shell
"name": "@my-org/package-name"
```

## Publishing a package via the command line

### Authenticating via the `.npmrc`

Create or edit the `.npmrc` file in the same directory as your `package.json`. Include the following lines in the `.npmrc` file:

```shell
@scope:registry=https://your_domain_name/api/v4/projects/your_project_id/packages/npm/
//your_domain_name/api/v4/projects/your_project_id/packages/npm/:_authToken="${NPM_TOKEN}"
```

- Replace `@scope` with the [root level group](#naming-convention) of the project you're publishing to the package to.
- Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
- Replace `your_project_id` is your project ID, found on the project's home page.
- `"${NPM_TOKEN}"` is associated with the token you created later in the process.

WARNING:
Never hardcode GitLab tokens (or any tokens) directly in `.npmrc` files or any other files that can
be committed to a repository.

### Publishing a package via the command line

Associate your [token](#authentication-to-the-package-registry) with the `"${NPM_TOKEN}"` in the `.npmrc`. Replace `your_token` with a deploy token, group access token, project access token, or personal access token.

```shell
NPM_TOKEN=your_token npm publish
```

Your package should now publish to the Package Registry.

## Publishing a package via a CI/CD pipeline

### Authenticating via the `.npmrc`

Create or edit the `.npmrc` file in the same directory as your `package.json` in a GitLab project. Include the following lines in the `.npmrc` file:

```shell
@scope:registry=https://your_domain_name/api/v4/projects/your_project_id/packages/npm/
//your_domain_name/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}
```

- Replace `@scope` with the [root level group](#naming-convention) of the project you're publishing to the package to.
- The `${CI_PROJECT_ID}` and `${CI_JOB_TOKEN}` are [predefined variables](../../../ci/variables/predefined_variables.md) that are available in the pipeline and do not need to be replaced.

### Publishing a package via a CI/CD pipeline

In the GitLab project that houses your `.npmrc` and `package.json`, edit or create a `.gitlab-ci.yml` file. For example:

```yaml
image: node:latest

stages:
  - deploy

deploy:
  stage: deploy
  script:
    - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}">.npmrc
    - npm publish
```

Your package should now publish to the Package Registry when the pipeline runs.

## Install a package

If multiple packages have the same name and version, when you install a package, the most recently-published package is retrieved.

You can install a package from a GitLab project or instance:

- **Instance-level**: Use when you have many npm packages in different GitLab groups or in their own namespace.
- **Project-level**: Use when you have few npm packages and they are not in the same GitLab group.

### Install from the instance level

WARNING:
To install a package from the instance level, the package must have been published following the scoped [naming convention](#naming-convention).

1. Authenticate to the Package Registry

   If you would like to install a package from a private project, you would have to authenticate to the Package Registry. Skip this step if the project is not private.

   ```shell
   npm config set -- //your_domain_name/api/v4/packages/npm/:_authToken=your_token
   ```

   - Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
   - Replace `your_token` with a deploy token, group access token, project access token, or personal access token.

1. Set the registry

   ```shell
   npm config set @scope:registry https://your_domain_name.com/api/v4/packages/npm/
   ```

   - Replace `@scope` with the [root level group](#naming-convention) of the project you're installing to the package from.
   - Replace `your_domain_name` with your domain name, for example `gitlab.com`.
   - Replace `your_token` with a deploy token, group access token, project access token, or personal access token.

1. Install the package

   ```shell
   npm install @scope/my-package
   ```

### Install from the project level

1. Authenticate to the Package Registry

   If you would like to install a package from a private project, you would have to authenticate to the Package Registry. Skip this step if the project is not private.

   ```shell
   npm config set -- //your_domain_name/api/v4/projects/your_project_id/packages/npm/:_authToken=your_token
   ```

   - Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
   - Replace `your_project_id` is your project ID, found on the project's home page.
   - Replace `your_token` with a deploy token, group access token, project access token, or personal access token.

1. Set the registry

   ```shell
   npm config set @scope:registry=https://your_domain_name/api/v4/projects/your_project_id/packages/npm/
   ```

   - Replace `@scope` with the [root level group](#naming-convention) of the project you're installing to the package from.
   - Replace `your_domain_name` with your domain name, for example, `gitlab.com`.
   - Replace `your_project_id` is your project ID, found on the project's home page.

1. Install the package

   ```shell
   npm install @scope/my-package
   ```

## Helpful hints

### Package forwarding to npmjs.com

When an npm package is not found in the Package Registry, the request is forwarded to [npmjs.com](https://www.npmjs.com/).

Administrators can disable this behavior in the [Continuous Integration settings](../../admin_area/settings/continuous_integration.md).

Group owners can disable this behavior in the group Packages and Registries settings.

### Install npm packages from other organizations

You can route package requests to organizations and users outside of GitLab.

To do this, add lines to your `.npmrc` file. Replace `@my-other-org` with the namespace or group that owns your project's repository,
and use your organization's URL. The name is case-sensitive and must match the name of your group or namespace exactly.

```shell
@scope:registry=https://my_domain_name.com/api/v4/packages/npm/
@my-other-org:registry=https://my_domain_name.example.com/api/v4/packages/npm/
```

### npm metadata

The GitLab Package Registry exposes the following attributes to the npm client.
These are similar to the [abbreviated metadata format](https://github.com/npm/registry/blob/9e368cf6aaca608da5b2c378c0d53f475298b916/docs/responses/package-metadata.md#abbreviated-metadata-format):

- `name`
- `versions`
  - `name`
  - `version`
  - `deprecated`
  - `dependencies`
  - `devDependencies`
  - `bundleDependencies`
  - `peerDependencies`
  - `bin`
  - `directories`
  - `dist`
  - `engines`
  - `_hasShrinkwrap`

### Add npm distribution tags

You can add [distribution tags](https://docs.npmjs.com/cli/dist-tag/) to newly-published packages.
Tags are optional and can be assigned to only one package at a time.

When you publish a package without a tag, the `latest` tag is added by default.
When you install a package without specifying the tag or version, the `latest` tag is used.

Examples of the supported `dist-tag` commands:

```shell
npm publish @scope/package --tag               # Publish a package with new tag
npm dist-tag add @scope/package@version my-tag # Add a tag to an existing package
npm dist-tag ls @scope/package                 # List all tags under the package
npm dist-tag rm @scope/package@version my-tag  # Delete a tag from the package
npm install @scope/package@my-tag              # Install a specific tag
```

You cannot use your `CI_JOB_TOKEN` or deploy token with the `npm dist-tag` commands.
View [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/258835) for details.

Due to a bug in npm 6.9.0, deleting distribution tags fails. Make sure your npm version is 6.9.1 or later.

### Supported CLI commands

The GitLab npm repository supports the following commands for the npm CLI (`npm`) and yarn CLI
(`yarn`):

- `npm install`: Install npm packages.
- `npm publish`: Publish an npm package to the registry.
- `npm dist-tag add`: Add a dist-tag to an npm package.
- `npm dist-tag ls`: List dist-tags for a package.
- `npm dist-tag rm`: Delete a dist-tag.
- `npm ci`: Install npm packages directly from your `package-lock.json` file.
- `npm view`: Show package metadata.

## Troubleshooting

### `npm publish` targets default npm registry (`registry.npmjs.org`)

Ensure that your package scope is set consistently in your `package.json` and `.npmrc` files.

For example, if your project name in GitLab is `@scope/my-package`, then your `package.json` file
should look like:

```json
{
  "name": "@scope/my-package"
}
```

And the `.npmrc` file should look like:

```shell
@scope:registry=https://your_domain_name/api/v4/projects/your_project_id/packages/npm/
//your_domain_name/api/v4/projects/your_project_id/packages/npm/:_authToken="${NPM_TOKEN}"
```

### `npm install` returns `npm ERR! 403 Forbidden`

If you get this error, ensure that:

- The Package Registry is enabled in your project settings. Although the Package Registry is enabled by default, it's possible to [disable it](../package_registry/index.md#disable-the-package-registry).
- Your token is not expired and has appropriate permissions.
- A package with the same name or version doesn't already exist within the given scope.
- The scoped packages URL includes a trailing slash:
  - Correct: `//gitlab.example.com/api/v4/packages/npm/`
  - Incorrect: `//gitlab.example.com/api/v4/packages/npm`

### `npm publish` returns `npm ERR! 400 Bad Request`

If you get this error, one of the following problems could be causing it.

### Package name does not meet the naming convention

Your package name may not meet the [`@scope/package-name` package naming convention](#naming-convention).

Ensure the name meets the convention exactly, including the case. Then try to publish again.

### Package already exists

Your package has already been published to another project in the same root namespace and therefore cannot be published again using the same name.

This is also true even if the prior published package shares the same name, but not the version.

### Package JSON file is too large

Make sure that your `package.json` file does not exceed `20,000` characters.

### `npm publish` returns `npm ERR! 500 Internal Server Error - PUT`

This is a [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/238950) in GitLab 13.3.x and later. The error in the logs appears as:

```plaintext
>NoMethodError - undefined method `preferred_language' for #<Rack::Response
```

This might be accompanied by another error:

```plaintext
>Errno::EACCES","exception.message":"Permission denied
```

This is usually a permissions issue with either:

- `'packages_storage_path'` default `/var/opt/gitlab/gitlab-rails/shared/packages/`.
- The remote bucket if [object storage](../../../administration/packages/index.md#use-object-storage)
  is used.

In the latter case, ensure the bucket exists and GitLab has write access to it.
