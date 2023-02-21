---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Maven packages in the Package Registry **(FREE)**

Publish [Maven](https://maven.apache.org) artifacts in your project's Package Registry.
Then, install the packages whenever you need to use them as a dependency.

For documentation of the specific API endpoints that the Maven package manager
client uses, see the [Maven API documentation](../../../api/packages/maven.md).

Learn how to build a [Maven](../workflows/build_packages.md#maven) package.

## Publish to the GitLab Package Registry

### Authenticate to the Package Registry

You need an token to publish a package. There are different tokens available depending on what you're trying to achieve. For more information, review the [guidance on tokens](../package_registry/index.md#authenticate-with-the-registry).

Create a token and save it to use later in the process.

### Edit the `settings.xml`

Add the following section to your
[`settings.xml`](https://maven.apache.org/settings.html) file.

NOTE:
The `<name>` field must be named to match the token you chose.

| Token type            | Name must be    | Token                                                                  |
| --------------------- | --------------- | ---------------------------------------------------------------------- |
| Personal access token | `Private-Token` | Paste token as-is, or define an environment variable to hold the token |
| Deploy token          | `Deploy-Token`  | Paste token as-is, or define an environment variable to hold the token |
| CI Job token          | `Job-Token`     | `${CI_JOB_TOKEN}`                                                      |

```xml
<settings>
  <servers>
    <server>
      <id>gitlab-maven</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>REPLACE_WITH_NAME</name>
            <value>REPLACE_WITH_TOKEN</value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
</settings>
```

### Naming convention

You can use one of three endpoints to install a Maven package. You must publish a package to a project, but the endpoint you choose determines the settings you add to your `pom.xml` file for publishing.

The three endpoints are:

- **Project-level**: Use when you have a few Maven packages and they are not in the same GitLab group.
- **Group-level**: Use when you want to install packages from many different projects in the same GitLab group. GitLab does not guarantee the uniqueness of package names within the group. You can have two projects with the same package name and package version. As a result, GitLab serves whichever one is more recent.
- **Instance-level**: Use when you have many packages in different GitLab groups or in their own namespace.

**Only packages that have the same path as the project** are exposed by the instance-level endpoint.

| Project             | Package                          | Instance-level endpoint available |
| ------------------- | -------------------------------- | --------------------------------- |
| `foo/bar`           | `foo/bar/1.0-SNAPSHOT`           | Yes                               |
| `gitlab-org/gitlab` | `foo/bar/1.0-SNAPSHOT`           | No                                |
| `gitlab-org/gitlab` | `gitlab-org/gitlab/1.0-SNAPSHOT` | Yes                               |

#### Endpoint URLs

| Endpoint | Endpoint URL for `pom.xml`                                               | Additional information                                                                                                             |
| -------- | ------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| Project  | `https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven` | Replace `gitlab.example.com` with your domain name. Replace `<project_id>` with your project ID, found on your project's homepage. |
| Group    | `https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/maven`   | Replace `gitlab.example.com` with your domain name. Replace `<group_id>` with your group ID, found on your group's homepage.      |
| Instance | `https://gitlab.example.com/api/v4/packages/maven`                       | Replace `gitlab.example.com` with your domain name.                                                                                |

### Edit the `pom.xml` for publishing

No matter which endpoint you choose, you must have:

- A project-specific URL in the `distributionManagement` section.
- A `repository` and `distributionManagement` section.

The relevant `repository` section of your `pom.xml` in Maven should look like this:

```xml
<repositories>
  <repository>
    <id>gitlab-maven</id>
    <url><your_endpoint_url></url>
  </repository>
</repositories>
<distributionManagement>
  <repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven</url>
  </repository>
  <snapshotRepository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven</url>
  </snapshotRepository>
</distributionManagement>
```

- The `id` is what you [defined in `settings.xml`](#edit-the-settingsxml).
- The `<your_endpoint_url>` depends on which [endpoint](#endpoint-urls) you choose.
- Replace `gitlab.example.com` with your domain name.

## Publish a package

After you have set up the [authentication](#authenticate-to-the-package-registry)
and [chosen an endpoint for publishing](#naming-convention),
publish a Maven package to your project.

To publish a package by using Maven:

```shell
mvn deploy
```

If the deploy is successful, the build success message should be displayed:

```shell
...
[INFO] BUILD SUCCESS
...
```

The message should also show that the package was published to the correct location:

```shell
Uploading to gitlab-maven: https://example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.jar
```

## Install a package

To install a package from the GitLab Package Registry, you must configure
the [remote and authenticate](#authenticate-to-the-package-registry).
When this is completed, you can install a package from a project,
group, or namespace.

If multiple packages have the same name and version, when you install
a package, the most recently-published package is retrieved.

### Use Maven with `mvn install`

To install a package by using `mvn install`:

1. Add the dependency manually to your project `pom.xml` file.
   To add the example created earlier, the XML would be:

   ```xml
   <dependency>
     <groupId>com.mycompany.mydepartment</groupId>
     <artifactId>my-project</artifactId>
     <version>1.0-SNAPSHOT</version>
   </dependency>
   ```

1. In your project, run the following:

   ```shell
   mvn install
   ```

The message should show that the package is downloading from the Package Registry:

```shell
Downloading from gitlab-maven: http://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.pom
```

### Use Maven with `mvn dependency:get`

You can install packages by using the Maven `dependency:get` [command](https://maven.apache.org/plugins/maven-dependency-plugin/get-mojo.html) directly.

1. In your project directory, run:

   ```shell
   mvn dependency:get -Dartifact=com.nickkipling.app:nick-test-app:1.1-SNAPSHOT -DremoteRepositories=gitlab-maven::::<gitlab endpoint url>  -s <path to settings.xml>
   ```

   - `<gitlab endpoint url>` is the URL of the GitLab [endpoint](#endpoint-urls).
   - `<path to settings.xml>` is the path to the `settings.xml` file that contains the [authentication details](#edit-the-settingsxml).

NOTE:
The repository IDs in the command(`gitlab-maven`) and the `settings.xml` file must match.

The message should show that the package is downloading from the Package Registry:

```shell
Downloading from gitlab-maven: http://gitlab.example.com/api/v4/projects/PROJECT_ID/packages/maven/com/mycompany/mydepartment/my-project/1.0-SNAPSHOT/my-project-1.0-20200128.120857-1.pom
```

## Helpful hints

### Publishing a package with the same name or version

When you publish a package with the same name and version as an existing package, the new package
files are added to the existing package. You can still use the UI or API to access and view the
existing package's older assets.

To delete older package versions, consider using the Packages API or the UI.

### Do not allow duplicate Maven packages

To prevent users from publishing duplicate Maven packages, you can use the [GraphQl API](../../../api/graphql/reference/index.md#packagesettings) or the UI.

In the UI:

1. For your group, go to **Settings > Packages and registries**.
1. Expand the **Package Registry** section.
1. Turn on the **Do not allow duplicates** toggle.
1. Optional. To allow some duplicate packages, in the **Exceptions** box, enter a regex pattern that matches the names and/or versions of packages you want to allow.

Your changes are automatically saved.

### Request forwarding to Maven Central

FLAG:
By default this feature is not available for self-managed. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `maven_central_request_forwarding`.
This feature is not available for SaaS users.

When a Maven package is not found in the Package Registry, the request is forwarded
to [Maven Central](https://search.maven.org/).

When the feature flag is enabled, administrators can disable this behavior in the
[Continuous Integration settings](../../admin_area/settings/continuous_integration.md).

There are many ways to configure your Maven project so that it requests packages
in Maven Central from GitLab. Maven repositories are queried in a
[specific order](https://maven.apache.org/guides/mini/guide-multiple-repositories.html#repository-order).
By default, maven-central is usually checked first through the
[Super POM](https://maven.apache.org/guides/introduction/introduction-to-the-pom.html#Super_POM), so
GitLab needs to be configured to be queried before maven-central.

[Using GitLab as a mirror of the central proxy](#setting-gitlab-as-a-mirror-for-the-central-proxy) is one
way to force GitLab to be queried in place of maven-central.

Maven forwarding is restricted to only the project level and
group level [endpoints](#naming-convention). The instance level endpoint
has naming restrictions that prevent it from being used for packages that don't follow that convention and also
introduces too much security risk for supply-chain style attacks.

#### Setting GitLab as a mirror for the central proxy

To ensure all package requests are sent to GitLab instead of Maven Central,
you can override Maven Central as the central repository by adding a `<mirror>`
section to your `settings.xml`:

```xml
<settings>
  <servers>
    <server>
      <id>central-proxy</id>
      <configuration>
        <httpHeaders>
          <property>
            <name>Private-Token</name>
            <value><personal_access_token></value>
          </property>
        </httpHeaders>
      </configuration>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>central-proxy</id>
      <name>GitLab proxy of central repo</name>
      <url>https://gitlab.example.com/api/v4/projects/<project_id>/packages/maven</url>
      <mirrorOf>central</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

### Create Maven packages with GitLab CI/CD

After you have configured your repository to use the Package Repository for Maven,
you can configure GitLab CI/CD to build new packages automatically.

### Create Maven packages with GitLab CI/CD using Maven

You can create a new package each time the `main` branch is updated.

1. Create a `ci_settings.xml` file that serves as Maven's `settings.xml` file.

1. Add the `server` section with the same ID you defined in your `pom.xml` file.
   For example, use `gitlab-maven` as the ID:

   ```xml
   <settings xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
     xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
     <servers>
       <server>
         <id>gitlab-maven</id>
         <configuration>
           <httpHeaders>
             <property>
               <name>Job-Token</name>
               <value>${CI_JOB_TOKEN}</value>
             </property>
           </httpHeaders>
         </configuration>
       </server>
     </servers>
   </settings>
   ```

1. Make sure your `pom.xml` file includes the following.
   You can either let Maven use the [predefined CI/CD variables](../../../ci/variables/predefined_variables.md), as shown in this example,
   or you can hard code your server's hostname and project's ID.

   ```xml
   <repositories>
     <repository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
     </repository>
   </repositories>
   <distributionManagement>
     <repository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
     </repository>
     <snapshotRepository>
       <id>gitlab-maven</id>
       <url>${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/maven</url>
     </snapshotRepository>
   </distributionManagement>
   ```

1. Add a `deploy` job to your `.gitlab-ci.yml` file:

   ```yaml
   deploy:
     image: maven:3.6-jdk-11
     script:
       - 'mvn deploy -s ci_settings.xml'
     only:
       - main
   ```

1. Push those files to your repository.

The next time the `deploy` job runs, it copies `ci_settings.xml` to the
user's home location. In this example:

- The user is `root`, because the job runs in a Docker container.
- Maven uses the configured CI/CD variables.

### Version validation

The version string is validated by using the following regex.

```ruby
\A(?!.*\.\.)[\w+.-]+\z
```

You can experiment with the regex and try your version strings on [this regular expression editor](https://rubular.com/r/rrLQqUXjfKEoL6).

### Useful Maven command-line options

There are some [Maven command-line options](https://maven.apache.org/ref/current/maven-embedder/cli.html)
that you can use when performing tasks with GitLab CI/CD.

- File transfer progress can make the CI logs hard to read.
  Option `-ntp,--no-transfer-progress` was added in
  [3.6.1](https://maven.apache.org/docs/3.6.1/release-notes.html#User_visible_Changes).
  Alternatively, look at `-B,--batch-mode`
  [or lower level logging changes.](https://stackoverflow.com/questions/21638697/disable-maven-download-progress-indication)

- Specify where to find the `pom.xml` file (`-f,--file`):

  ```yaml
  package:
    script:
      - 'mvn --no-transfer-progress -f helloworld/pom.xml package'
  ```

- Specify where to find the user settings (`-s,--settings`) instead of
  [the default location](https://maven.apache.org/settings.html). There's also a `-gs,--global-settings` option:

  ```yaml
  package:
    script:
      - 'mvn -s settings/ci.xml package'
  ```

### Supported CLI commands

The GitLab Maven repository supports the following Maven CLI commands:

- `mvn deploy`: Publish your package to the Package Registry.
- `mvn install`: Install packages specified in your Maven project.
- `mvn dependency:get`: Install a specific package.

## Troubleshooting

To improve performance, Maven caches files related to a package. If you encounter issues, clear
the cache with these commands:

```shell
rm -rf ~/.m2/repository
```

If you're using Gradle, run this command to clear the cache:

```shell
rm -rf ~/.gradle/caches # Or replace ~/.gradle with your custom GRADLE_USER_HOME
```

### Review network trace logs

If you are having issues with the Maven Repository, you may want to review network trace logs.

For example, try to run `mvn deploy` locally with a PAT token and use these options:

```shell
mvn deploy \
-Dorg.slf4j.simpleLogger.log.org.apache.maven.wagon.providers.http.httpclient=trace \
-Dorg.slf4j.simpleLogger.log.org.apache.maven.wagon.providers.http.httpclient.wire=trace
```

WARNING:
When you set these options, all network requests are logged and a large amount of output is generated.

### Verify your Maven settings

If you encounter issues within CI/CD that relate to the `settings.xml` file, try adding
an additional script task or job to [verify the effective settings](https://maven.apache.org/plugins/maven-help-plugin/effective-settings-mojo.html).

The help plugin can also provide
[system properties](https://maven.apache.org/plugins/maven-help-plugin/system-mojo.html), including environment variables:

```yaml
mvn-settings:
  script:
    - 'mvn help:effective-settings'

package:
  script:
    - 'mvn help:system'
    - 'mvn package'
```
