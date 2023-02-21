---
stage: Analyze
group: Product Analytics
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Product analytics **(ULTIMATE)**

> - Introduced in GitLab 15.4 as an [Alpha](../../policy/alpha-beta-support.md#alpha-features) feature [with a flag](../../administration/feature_flags.md) named `cube_api_proxy`. Disabled by default.
> - `cube_api_proxy` revised to only reference the [Product Analytics API](../../api/product_analytics.md) in GitLab 15.6.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `cube_api_proxy`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

This page is a work in progress, and we're updating the information as we add more features.
For more information, visit the [Product Analytics group direction page](https://about.gitlab.com/direction/analytics/product-analytics/).

## How Product Analytics works

```mermaid
---
title: Product Analytics flow
---
flowchart TB
    subgraph Adding data
        A([SDK]) --Send user data--> B[Analytics Proxy]
        B --Transform data and pass it through--> C[Jitsu]
        C --Pass the data to the associated database--> D([Clickhouse])
    end
    subgraph Showing dashboards
        E([Dashboards]) --Generated from the YAML definition--> F[Dashboard]
        F --Request data--> G[Product Analytics API]
        G --Run Cube queries with pre-aggregations--> H[Cube.js]
        H --Get data from database--> D
        D --Return results--> H
        H --> G
        G --Transform data to be rendered--> F
    end
```

Product Analytics uses several tools:

- [**Jitsu**](https://jitsu.com/docs) - A web and app event collection platform that provides a consistent API to collect user data and pass it through to Clickhouse.
- [**Clickhouse**](https://clickhouse.com/docs) - A database suited to store, query, and retrieve analytical data.
- [**Cube.js**](https://cube.dev/docs/) - An analytical graphing library that provides an API to run queries against the data stored in Clickhouse.

## Enable product analytics

> - Introduced in GitLab 15.6 behind the [feature flag](../../administration/feature_flags.md) named `cube_api_proxy`. Disabled by default.
> - Moved to be behind the [feature flag](../../administration/feature_flags.md) named `product_analytics_admin_settings` in GitLab 15.7. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `product_analytics_admin_settings`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

You can enable and configure product analytics to track events
within your project applications on a self-managed instance.

Prerequisite:

- You must be an administrator of a self-managed GitLab instance.

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Product analytics** section.
1. Select **Enable product analytics** and enter the configuration values.
   The following table shows the required configuration parameters and example values:

    | Name                         | Value                                                      |
    |------------------------------|------------------------------------------------------------|
    | Jitsu host                   | `https://jitsu.gitlab.com`                                 |
    | Jitsu project ID             | `g0maofw84gx5sjxgse2k`                                     |
    | Jitsu administrator email    | `jitsu.admin@gitlab.com`                                   |
    | Jitsu administrator password | `<your_password>`                                          |
    | Clickhouse URL               | `https://<username>:<password>@clickhouse.gitlab.com:8123` |
    | Cube API URL                 | `https://cube.gitlab.com`                                  |
    | Cube API key                 | `25718201b3e9...ae6bbdc62dbb`                              |

1. Select **Save changes**.

## Product analytics dashboards

> Introduced in GitLab 15.5 behind the [feature flag](../../administration/feature_flags.md) named `product_analytics_internal_preview`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `product_analytics_internal_preview`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

Each project can define an unlimited number of dashboards. These dashboards are defined using our YAML schema and stored
in the `.gitlab/product_analytics/dashboards/` directory of a project repository. The name of the file is the name of the dashboard, and visualizations are shared across dashboards.

Project maintainers can enforce approval rules on dashboard changes using features such as code owners and approval rules. Dashboards are versioned in source control with the rest of a project's code.

### View project dashboards

> Introduced in GitLab 15.9 behind the [feature flag](../../administration/feature_flags.md) named `combined_analytics_dashboards`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `combined_analytics_dashboards`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

To view a list of product analytics dashboards for a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > Dashboards**.

### Define a dashboard

To define a dashboard:

1. In `.gitlab/product_analytics/dashboards/`, create a directory named like the dashboard. Each dashboard should have its own directory.
1. In the new directory, create a `.yaml` file with the same name as the directory. This file contains the dashboard definition, and must conform to the JSON schema defined in `ee/app/validators/json_schemas/product_analytics_dashboard.json`.
1. In the `.gitlab/product_analytics/dashboards/visualizations/` directory, create a `yaml` file. This file defines the visualization type for the dashboard, and must conform to the schema in
 `ee/app/validators/json_schemas/product_analytics_visualization.json`.

The example below includes three dashboards and one visualization that applies to all dashboards.

```plaintext
.gitlab/product_analytics/dashboards
├── conversion_funnels
│  └── conversion_funnels.yaml
├── demographic_breakdown
│  └── demographic_breakdown.yaml
├── north_star_metrics
|  └── north_star_metrics.yaml
├── visualizations
│  └── example_line_chart.yaml
```

## Funnel analysis

Funnel analysis can be used to understand the flow of users through your application and where
users drop out of a predefined flow (for example, a checkout process or ticket purchase).

Each product can also define an unlimited number of funnels.
These funnels are defined using our YAML schema and stored in the `.gitlab/product_analytics/funnels/` directory of a project repository.

Funnel definitions must include the keys `name`, `seconds_to_convert`, and an array of `steps`.

| Key                  | Description                                              |
|----------------------|----------------------------------------------------------|
| `name`               | The name of the funnel.                                  |
| `seconds_to_convert` | The number of seconds a user has to complete the funnel. |
| `steps`              | An array of funnel steps.                                |

Each step must include the keys `name`, `target`, and `action`.

| Key      | Description                                                                              |
|----------|------------------------------------------------------------------------------------------|
| `name`   | The name of the step. This should be a unique slug.                                      |
| `action` | The action performed. (Only `pageview` is supported.)                          |
| `target` | The target of the step. (Because only `pageview` is supported, this should be a path.) |

### Example funnel definition

```yaml
name: completed_purchase
seconds_to_convert: 3600
steps:
  - name: view_page_1
    target: '/page1.html'
    action: 'pageview'
  - name: view_page_2
    target: '/page2.html'
    action: 'pageview'
  - name: view_page_3
    target: '/page3.html'
    action: 'pageview'
```

### Query a funnel

You can [query the funnel data with the REST API](../../api/product_analytics.md#send-query-request-to-cube).
To do this, you can use the example query body below, where you need to replace `FUNNEL_NAME` with your funnel's name.

NOTE:
The `afterDate` filter is not supported. Please use `beforeDate` or `inDateRange`.

```json
{
  "query": {
      "measures": [
        "FUNNEL_NAME.count"
      ],
      "order": {
        "completed_purchase.count": "desc"
      },
      "filters": [
        {
          "member": "FUNNEL_NAME.date",
          "operator": "beforeDate",
          "values": [
            "2023-02-01"
          ]
        }
      ],
      "dimensions": [
        "FUNNEL_NAME.step"
      ]
    }
}
```
