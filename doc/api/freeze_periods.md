---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: concepts, howto
---

# Freeze Periods API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/29382) in GitLab 13.0.

You can use the Freeze Periods API to manipulate GitLab [Freeze Period](../user/project/releases/index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze) entries.

## Permissions and security

Only users with Maintainer [permissions](../user/permissions.md) can
interact with the Freeze Period API endpoints.

## List freeze periods

Paginated list of freeze periods, sorted by `created_at` in ascending order.

```plaintext
GET /projects/:id/freeze_periods
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
```

Example response:

```json
[
   {
      "id":1,
      "freeze_start":"0 23 * * 5",
      "freeze_end":"0 8 * * 1",
      "cron_timezone":"UTC",
      "created_at":"2020-05-15T17:03:35.702Z",
      "updated_at":"2020-05-15T17:06:41.566Z"
   }
]
```

## Get a freeze period by a `freeze_period_id`

Get a freeze period for the given `freeze_period_id`.

```plaintext
GET /projects/:id/freeze_periods/:freeze_period_id
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `freeze_period_id`    | integer         | yes      | The ID of the freeze period.                                     |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```

Example response:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 8 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:06:41.566Z"
}
```

## Create a freeze period

Create a freeze period.

```plaintext
POST /projects/:id/freeze_periods
```

| Attribute          | Type            | Required                    | Description                                                                                                                      |
| -------------------| --------------- | --------                    | -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | integer or string  | yes                         | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding).                                              |
| `freeze_start`     | string          | yes                         | Start of the freeze period in [cron](https://crontab.guru/) format.                                                              |
| `freeze_end`       | string          | yes                         | End of the freeze period in [cron](https://crontab.guru/) format.                                                                |
| `cron_timezone`    | string          | no                          | The time zone for the cron fields, defaults to UTC if not provided.                                                               |

Example request:

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "freeze_start": "0 23 * * 5", "freeze_end": "0 7 * * 1", "cron_timezone": "UTC" }' \
     --request POST "https://gitlab.example.com/api/v4/projects/19/freeze_periods"
```

Example response:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 7 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:03:35.702Z"
}
```

## Update a freeze period

Update a freeze period for the given `freeze_period_id`.

```plaintext
PUT /projects/:id/freeze_periods/:freeze_period_id
```

| Attribute     | Type            | Required | Description                                                                                                 |
| ------------- | --------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `id`          | integer or string  | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding).                         |
| `freeze_period_id`    | integer          | yes      | The ID of the freeze period.                                                              |
| `freeze_start`     | string          | no                         | Start of the freeze period in [cron](https://crontab.guru/) format.                                                              |
| `freeze_end`       | string          | no                         | End of the freeze period in [cron](https://crontab.guru/) format.                                                                |
| `cron_timezone`    | string          | no                          | The time zone for the cron fields.                                                               |

Example request:

```shell
curl --header 'Content-Type: application/json' --header "PRIVATE-TOKEN: <your_access_token>" \
     --data '{ "freeze_end": "0 8 * * 1" }' \
     --request PUT "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"
```

Example response:

```json
{
   "id":1,
   "freeze_start":"0 23 * * 5",
   "freeze_end":"0 8 * * 1",
   "cron_timezone":"UTC",
   "created_at":"2020-05-15T17:03:35.702Z",
   "updated_at":"2020-05-15T17:06:41.566Z"
}
```

## Delete a freeze period

Delete a freeze period for the given `freeze_period_id`.

```plaintext
DELETE /projects/:id/freeze_periods/:freeze_period_id
```

| Attribute     | Type           | Required | Description                                                                         |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------- |
| `id`          | integer or string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `freeze_period_id`    | integer         | yes      | The ID of the freeze period.                                     |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/19/freeze_periods/1"

```
