---
stage: Secure
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
---

# DAST browser-based analyzer **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/323423) in GitLab 13.12 as a Beta feature.
> - [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/9023) in GitLab 15.7 (GitLab DAST v3.0.50).

WARNING:
Do not run DAST scans against a production server. Not only can it perform *any* function that
a user can, such as clicking buttons or submitting forms, but it may also trigger bugs, leading to modification or loss of production data. Only run DAST scans against a test server.

The DAST browser-based analyzer was built by GitLab to scan modern-day web applications for vulnerabilities.
Scans run in a browser to optimize testing applications heavily dependent on JavaScript, such as single-page applications.
See [how DAST scans an application](#how-dast-scans-an-application) for more information.

To add the analyzer to your CI/CD pipeline, see [getting started](#getting-started).

## How DAST scans an application

A scan performs the following steps:

1. [Authenticate](authentication.md), if configured.
1. [Crawl](#crawling-an-application) the target application to discover the surface area of the application by performing user actions such as following links, clicking buttons, and filling out forms.
1. [Passive scan](#passive-scans) to search for vulnerabilities in HTTP messages and pages discovered while crawling.
1. [Active scan](#active-scans) to search for vulnerabilities by injecting payloads into HTTP requests recorded during the crawl phase.

### Crawling an application

A "navigation" is an action a user might take on a page, such as clicking buttons, clicking anchor links, opening menu items, or filling out forms.
A "navigation path" is a sequence of navigation actions representing how a user might traverse an application.
DAST discovers the surface area of an application by crawling pages and content and identifying navigation paths.

Crawling is initialized with a navigation path containing one navigation that loads the target application URL in a specially-instrumented Chromium browser.
DAST then crawls navigation paths until all have been crawled.

To crawl a navigation path, DAST opens a browser window and instructs it to perform all the navigation actions in the navigation path.
When the browser has finished loading the result of the final action, DAST inspects the page for actions a user might take,
creates a new navigation for each found, and adds them to the navigation path to form new navigation paths. For example:

- DAST processes navigation path `LoadURL[https://example.com]`.
- DAST finds two user actions, `LeftClick[class=menu]` and `LeftClick[id=users]`.
- DAST creates two new navigation paths, `LoadURL[https://example.com] -> LeftClick[class=menu]` and `LoadURL[https://example.com] -> LeftClick[id=users]`.
- Crawling begins on the two new navigation paths.

It's common for an HTML element to exist in multiple places in an application, such as a menu visible on every page.
Duplicate elements can cause crawlers to crawl the same pages again or become stuck in a loop.
DAST uses an element uniqueness calculation based on HTML attributes to discard new navigation actions it has previously crawled.

### Passive scans

Passive scans check for vulnerabilities in the pages discovered during the crawl phase of the scan.
Passive scans are enabled by default.

The checks search HTTP messages, cookies, storage events, console events, and DOM for vulnerabilities.
Examples of passive checks include searching for exposed credit cards, exposed secret tokens, missing content security policies, and redirection to untrusted locations.

See [checks](checks/index.md) for more information about individual checks.

### Active scans

Active scans check for vulnerabilities by injecting attack payloads into HTTP requests recorded during the crawl phase of the scan.
Active scans are disabled by default due to the nature of their probing attacks.

DAST analyzes each recorded HTTP request for injection locations, such as query values, header values, cookie values, form posts, and JSON string values.
Attack payloads are injected into the injection location, forming a new request.
DAST sends the request to the target application and uses the HTTP response to determine attack success.

Active scans run two types of active check:

- A match response attack analyzes the response content to determine attack success. For example, if an attack attempts to read the system password file, a finding is created when the response body contains evidence of the password file.
- A timing attack uses the response time to determine attack success. For example, if an attack attempts to force the target application to sleep, a finding is created when the application takes longer to respond than the sleep time. Timing attacks are repeated multiple times with different attack payloads to minimize false positives.

A simplified timing attack works as follows:

1. The crawl phase records the HTTP request `https://example.com?search=people`.
1. DAST analyzes the URL and finds a URL parameter injection location `https://example.com?search=[INJECT]`.
1. The active check defines a payload, `sleep 10`, that attempts to get a Linux host to sleep.
1. DAST send a new HTTP request to the target application with the injected payload `https://example.com?search=sleep%2010`.
1. The target application is vulnerable if it executes the query parameter value as a system command without validation, for example, `system(params[:search])`
1. DAST creates a finding if the response time takes longer than 10 seconds.

## Getting started

To run a DAST scan:

- Read the [prerequisite](index.md#prerequisites) conditions for running a DAST scan.
- Create a [DAST job](#create-a-dast-cicd-job) in your CI/CD pipeline.
- [Authenticate](#authentication) as a user if your application requires it.

### Create a DAST CI/CD job

> - This template was [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62597) to DAST_VERSION: 2 in
    GitLab 14.0.
> - This template was [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87183) to DAST_VERSION: 3 in
    GitLab 15.0.

To add DAST scanning to your application, use the DAST job defined
in the GitLab DAST CI/CD template file. Updates to the template are provided with GitLab
upgrades, allowing you to benefit from any improvements and additions.

To create the CI/CD job:

1. Include the appropriate CI/CD template:

    - [`DAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.gitlab-ci.yml):
      Stable version of the DAST CI/CD template.
    - [`DAST.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.latest.gitlab-ci.yml):
      Latest version of the DAST template. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/254325)
      in GitLab 13.8).

   WARNING:
   The latest version of the template may include breaking changes. Use the
   stable template unless you need a feature provided only in the latest template.

   For more information about template versioning, see the
   [CI/CD documentation](../../../development/cicd/templates.md#latest-version).

1. Add a `dast` stage to your GitLab CI/CD stages configuration.

1. Define the URL to be scanned by DAST by using one of these methods:

    - Set the `DAST_WEBSITE` [CI/CD variable](../../../ci/yaml/index.md#variables).
      If set, this value takes precedence.

    - Adding the URL in an `environment_url.txt` file at your project's root is great for testing in
      dynamic environments. To run DAST against an application dynamically created during a GitLab CI/CD
      pipeline, write the application URL to an `environment_url.txt` file. DAST automatically reads the
      URL to find the scan target.

      You can see an [example of this in our Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml).

1. Set the `DAST_BROWSER_SCAN` [CI/CD variable](../../../ci/yaml/index.md#variables) to `"true"`.

For example:

```yaml
stages:
  - build
  - test
  - deploy
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_WEBSITE: "https://example.com"
    DAST_BROWSER_SCAN: "true"
```

### Authentication

The browser-based analyzer can authenticate a user prior to a scan. See [Authentication](authentication.md) for
configuration instructions.

### Available CI/CD variables

These CI/CD variables are specific to the browser-based DAST analyzer. They can be used to customize the behavior of
DAST to your requirements.
For authentication CI/CD variables, see [Authentication](authentication.md).

| CI/CD variable                              | Type                                                     | Example                                | Description                                                                                                                                                                                                                                                                   |
|:--------------------------------------------|:---------------------------------------------------------|----------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `DAST_ADVERTISE_SCAN`                       | boolean                                                  | `true`                                 | Set to `true` to add a `Via` header to every request sent, advertising that the request was sent as part of a GitLab DAST scan. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/334947) in GitLab 14.1.                                                            |
| `DAST_BROWSER_ACTION_STABILITY_TIMEOUT`     | [Duration string](https://pkg.go.dev/time#ParseDuration) | `800ms`                                | The maximum amount of time to wait for a browser to consider a page loaded and ready for analysis after completing an action.                                                                                                                                                 |
| `DAST_BROWSER_ACTION_TIMEOUT`               | [Duration string](https://pkg.go.dev/time#ParseDuration) | `7s`                                   | The maximum amount of time to wait for a browser to complete an action.                                                                                                                                                                                                       |
| `DAST_BROWSER_ALLOWED_HOSTS`                | List of strings                                          | `site.com,another.com`                 | Hostnames included in this variable are considered in scope when crawled. By default the `DAST_WEBSITE` hostname is included in the allowed hosts list. Headers set using `DAST_REQUEST_HEADERS` are added to every request made to these hostnames. |
| `DAST_BROWSER_COOKIES`                      | dictionary                                               | `abtesting_group:3,region:locked`      | A cookie name and value to be added to every request.                                                                                                                                                                                                                         |
| `DAST_BROWSER_CRAWL_GRAPH`                  | boolean                                                  | `true`                                 | Set to `true` to generate an SVG graph of navigation paths visited during crawl phase of the scan.                                                                                                                                                                            |
| `DAST_BROWSER_DEVTOOLS_LOG`                 | string                                                   | `Default:messageAndBody,truncate:2000` | Set to log protocol messages between DAST and the Chromium browser.                                                                                                                                                                                                           |                                                                                                                                                                                                                                                                               |
| `DAST_BROWSER_ELEMENT_TIMEOUT`              | [Duration string](https://pkg.go.dev/time#ParseDuration) | `600ms`                                | The maximum amount of time to wait for an element before determining it is ready for analysis.                                                                                                                                                                                |
| `DAST_BROWSER_EXCLUDED_ELEMENTS`            | selector                                                 | `a[href='2.html'],css:.no-follow`      | Comma-separated list of selectors that are ignored when scanning.                                                                                                                                                                                                             |
| `DAST_BROWSER_EXCLUDED_HOSTS` | List of strings | `site.com,another.com` | Hostnames included in this variable are considered excluded and connections are forcibly dropped. |
| `DAST_BROWSER_EXTRACT_ELEMENT_TIMEOUT`      | [Duration string](https://pkg.go.dev/time#ParseDuration) | `5s`                                   | The maximum amount of time to allow the browser to extract newly found elements or navigations.                                                                                                                                                                               |
| `DAST_BROWSER_FILE_LOG`                     | List of strings                                          | `brows:debug,auth:debug`               | A list of modules and their intended logging level for use in the file log.                                                                                                                                                                                                   |
| `DAST_BROWSER_FILE_LOG_PATH`                | string                                                   | `/output/browserker.log`               | Set to the path of the file log.                                                                                                                                                                                                                                              |
| `DAST_BROWSER_IGNORED_HOSTS`                | List of strings                                          | `site.com,another.com`                 | Hostnames included in this variable are accessed, not attacked, and not reported against.                                                                                                                                                                                     |
| `DAST_BROWSER_INCLUDE_ONLY_RULES`           | List of strings                                          | `16.1,16.2,16.3`                       | Comma-separated list of check identifiers to use for the scan.                                                                                                                                                                                                                |
| `DAST_BROWSER_LOG`                          | List of strings                                          | `brows:debug,auth:debug`               | A list of modules and their intended logging level for use in the console log.                                                                                                                                                                                                |
| `DAST_BROWSER_LOG_CHROMIUM_OUTPUT`          | boolean                                                  | `true`                                 | Set to `true` to log Chromium `STDOUT` and `STDERR`.                                                                                                                                                                                                                          |
| `DAST_BROWSER_MAX_ACTIONS`                  | number                                                   | `10000`                                | The maximum number of actions that the crawler performs. For example, selecting a link, or filling a form.                                                                                                                                                                    |
| `DAST_BROWSER_MAX_DEPTH`                    | number                                                   | `10`                                   | The maximum number of chained actions that the crawler takes. For example, `Click -> Form Fill -> Click` is a depth of three.                                                                                                                                                 |
| `DAST_BROWSER_MAX_RESPONSE_SIZE_MB`         | number                                                   | `15`                                   | The maximum size of a HTTP response body. Responses with bodies larger than this are blocked by the browser. Defaults to 10 MB.                                                                                                                                               |
| `DAST_BROWSER_NAVIGATION_STABILITY_TIMEOUT` | [Duration string](https://pkg.go.dev/time#ParseDuration) | `7s`                                   | The maximum amount of time to wait for a browser to consider a page loaded and ready for analysis after a navigation completes.                                                                                                                                               |
| `DAST_BROWSER_NAVIGATION_TIMEOUT`           | [Duration string](https://pkg.go.dev/time#ParseDuration) | `15s`                                  | The maximum amount of time to wait for a browser to navigate from one page to another.                                                                                                                                                                                        |
| `DAST_BROWSER_NUMBER_OF_BROWSERS`           | number                                                   | `3`                                    | The maximum number of concurrent browser instances to use. For shared runners on GitLab.com, we recommended a maximum of three. Private runners with more resources may benefit from a higher number, but are likely to produce little benefit after five to seven instances. |
| `DAST_BROWSER_PAGE_LOADING_SELECTOR`          | selector                                                 | `css:#page-is-loading`                   | Selector that when is no longer visible on the page, indicates to the analyzer that the page has finished loading and the scan can continue. Cannot be used with `DAST_BROWSER_PAGE_READY_SELECTOR`                                                                                                                            |
| `DAST_BROWSER_PAGE_READY_SELECTOR`          | selector                                                 | `css:#page-is-ready`                   | Selector that when detected as visible on the page, indicates to the analyzer that the page has finished loading and the scan can continue. Cannot be used with `DAST_BROWSER_PAGE_LOADING_SELECTOR`                                                                                                                                   |
| `DAST_BROWSER_SCAN`                         | boolean                                                  | `true`                                 | Required to be `true` to run a browser-based scan.                                                                                                                                                                                                                            |
| `DAST_BROWSER_SEARCH_ELEMENT_TIMEOUT`       | [Duration string](https://pkg.go.dev/time#ParseDuration) | `3s`                                   | The maximum amount of time to allow the browser to search for new elements or user actions.                                                                                                                                                                                   |
| `DAST_BROWSER_STABILITY_TIMEOUT`            | [Duration string](https://pkg.go.dev/time#ParseDuration) | `7s`                                   | The maximum amount of time to wait for a browser to consider a page loaded and ready for analysis.                                                                                                                                                                            |
| `DAST_EXCLUDE_RULES`                        | string                                                   | `10020,10026`                          | Set to a comma-separated list of ZAP Vulnerability Rule IDs to exclude them from running during the scan. Rule IDs are numbers and can be found from the DAST log or on the [ZAP project](https://www.zaproxy.org/docs/alerts/).                                              |
| `DAST_EXCLUDE_URLS`                         | URLs                                                     | `https://example.com/.*/sign-out`      | The URLs to skip during the authenticated scan; comma-separated. Regular expression syntax can be used to match multiple URLs. For example, `.*` matches an arbitrary character sequence.                                                                                     |
| `DAST_FULL_SCAN_ENABLED`                    | boolean                                                  | `true`                                 | Set to `true` to run both passive and active checks. Default: `false`                                                                                                                                                                                                         |
| `DAST_PATHS`                                | string                                                   | `/page1.html,/category1/page3.html`    | Set to a comma-separated list of URL paths relative to `DAST_WEBSITE` for DAST to scan.                                                                                                                                                                                       |
| `DAST_PATHS_FILE`                           | string                                                   | `/builds/project/urls.txt`             | Set to a file path containing a list of URL paths relative to `DAST_WEBSITE` for DAST to scan. The file must be plain text with one path per line.                                                                                                                            |
| `DAST_PKCS12_CERTIFICATE_BASE64`            | string                                                   | `ZGZkZ2p5NGd...`                       | The PKCS12 certificate used for sites that require Mutual TLS. Must be encoded as base64 text.                                                                                                                                                                                |
| `DAST_PKCS12_PASSWORD`                      | string                                                   | `password`                             | The password of the certificate used in `DAST_PKCS12_CERTIFICATE_BASE64`. Create sensitive [custom CI/CI variables](../../../ci/variables/index.md#define-a-cicd-variable-in-the-ui) using the GitLab UI.                                                                                |
| `DAST_REQUEST_HEADERS`                      | string                                                   | `Cache-control:no-cache`               | Set to a comma-separated list of request header names and values. |
| `DAST_SKIP_TARGET_CHECK`                    | boolean                                                  | `true`                                 | Set to `true` to prevent DAST from checking that the target is available before scanning. Default: `false`.                                                                                                                                                                   |
| `DAST_TARGET_AVAILABILITY_TIMEOUT`          | number                                                   | `60`                                   | Time limit in seconds to wait for target availability.                                                                                                                                                                                                                        |
| `DAST_WEBSITE`                              | URL                                                      | `https://example.com`                  | The URL of the website to scan.                                                                                                                                                                                                                                               |
| `SECURE_ANALYZERS_PREFIX`                   | URL                                                      | `registry.organization.com`            | Set the Docker registry base address from which to download the analyzer.                                                                                                                                                                                                     |

## Vulnerability detection

Vulnerability detection is gradually being migrated from the default Zed Attack Proxy (ZAP) solution
to the browser-based analyzer. For details of the vulnerability detection already migrated, see
[browser-based vulnerability checks](checks/index.md).

The crawler runs the target website in a browser with DAST/ZAP configured as the proxy server. This
ensures that all requests and responses made by the browser are passively scanned by DAST/ZAP. When
running a full scan, active vulnerability checks executed by DAST/ZAP do not use a browser. This
difference in how vulnerabilities are checked can cause issues that require certain features of the
target website to be disabled to ensure the scan works as intended.

For example, for a target website that contains forms with Anti-CSRF tokens, a passive scan works as
intended because the browser displays pages and forms as if a user is viewing the page. However,
active vulnerability checks that run in a full scan cannot submit forms containing Anti-CSRF tokens.
In such cases, we recommend you disable Anti-CSRF tokens when running a full scan.

## Managing scan time

It is expected that running the browser-based crawler results in better coverage for many web applications, when compared to the standard GitLab DAST solution.
This can come at a cost of increased scan time.

You can manage the trade-off between coverage and scan time with the following measures:

- Limit the number of actions executed by the browser with the [variable](#available-cicd-variables) `DAST_BROWSER_MAX_ACTIONS`. The default is `10,000`.
- Limit the page depth that the browser-based crawler checks coverage on with the [variable](#available-cicd-variables) `DAST_BROWSER_MAX_DEPTH`. The crawler uses a breadth-first search strategy, so pages with smaller depth are crawled first. The default is `10`.
- Vertically scale the runner and use a higher number of browsers with [variable](#available-cicd-variables) `DAST_BROWSER_NUMBER_OF_BROWSERS`. The default is `3`.

## Timeouts

Due to poor network conditions or heavy application load, the default timeouts may not be applicable to your application.

Browser-based scans offer the ability to adjust various timeouts to ensure it continues smoothly as it transitions from one page to the next. These values are configured using a [Duration string](https://pkg.go.dev/time#ParseDuration), which allow you to configure durations with a prefix: `m` for minutes, `s` for seconds, and `ms` for milliseconds.

Navigations, or the act of loading a new page, usually require the most amount of time because they are
loading multiple new resources such as JavaScript or CSS files. Depending on the size of these resources, or the speed at which they are returned, the default `DAST_BROWSER_NAVIGATION_TIMEOUT` may not be sufficient.

Stability timeouts, such as those configurable with `DAST_BROWSER_NAVIGATION_STABILITY_TIMEOUT`, `DAST_BROWSER_STABILITY_TIMEOUT`, and `DAST_BROWSER_ACTION_STABILITY_TIMEOUT` can also be configured. Stability timeouts determine when browser-based scans consider
a page fully loaded. Browser-based scans consider a page loaded when:

1. The [DOMContentLoaded](https://developer.mozilla.org/en-US/docs/Web/API/Window/DOMContentLoaded_event) event has fired.
1. There are no open or outstanding requests that are deemed important, such as JavaScript and CSS. Media files are usually deemed unimportant.
1. Depending on whether the browser executed a navigation, was forcibly transitioned, or action:

   - There are no new Document Object Model (DOM) modification events after the `DAST_BROWSER_NAVIGATION_STABILITY_TIMEOUT`, `DAST_BROWSER_STABILITY_TIMEOUT`, or `DAST_BROWSER_ACTION_STABILITY_TIMEOUT` durations.

After these events have occurred, browser-based scans consider the page loaded and ready, and attempt the next action.

If your application experiences latency or returns many navigation failures, consider adjusting the timeout values such as in this example:

```yaml
include:
  - template: DAST.gitlab-ci.yml

dast:
  variables:
    DAST_WEBSITE: "https://my.site.com"
    DAST_BROWSER_NAVIGATION_TIMEOUT: "25s"
    DAST_BROWSER_ACTION_TIMEOUT: "10s"
    DAST_BROWSER_STABILITY_TIMEOUT: "15s"
    DAST_BROWSER_NAVIGATION_STABILITY_TIMEOUT: "15s"
    DAST_BROWSER_ACTION_STABILITY_TIMEOUT: "3s"
```

NOTE:
Adjusting these values may impact scan time because they adjust how long each browser waits for various activities to complete.

## Artifacts

Using the latest version of the DAST [template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.latest.gitlab-ci.yml) these artifacts are exposed for download by default.

The list of artifacts includes the following files:

- `gl-dast-debug-auth-report.html`
- `gl-dast-debug-crawl-report.html`
- `gl-dast-crawl-graph.svg`

## Troubleshooting

See [troubleshooting](browser_based_troubleshooting.md) for more information.
