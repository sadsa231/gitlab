---
stage: Data Stores
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference
---

# Advanced Search **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

You can use Advanced Search for faster, more efficient search across the entire GitLab
instance. Advanced Search is based on Elasticsearch, a purpose-built full-text search
engine you can horizontally scale to get results in up to a second in most cases.

You can find code you want to update in all projects at once to save
maintenance time and promote innersourcing.

You can use Advanced Search in:

- Projects
- Issues
- Merge requests
- Milestones
- Users
- Epics (in groups only)
- Code
- Comments
- Commits
- Project wikis (not [group wikis](../project/wiki/group.md))

For Advanced Search:

- You can only search files smaller than 1 MB.
  For self-managed GitLab instances, an administrator can
  [change this limit](../../integration/advanced_search/elasticsearch.md#advanced-search-configuration).
- You can't use any of the following characters in the search query:

  ```plaintext
  . , : ; / ` ' = ? $ & ^ | ~ < > ( ) { } [ ] @
  ```

- Only the default branch of a project is indexed for code search.
  In a non-default branch, basic search is used.
- Search results show only the first match in a file,
  but there might be more results in that file.

## Enable Advanced Search

- On GitLab.com, Advanced Search is enabled for groups with paid subscriptions.
- For self-managed GitLab instances, an administrator must
  [enable Advanced Search](../../integration/advanced_search/elasticsearch.md#enable-advanced-search).

## Syntax

Advanced Search uses [Elasticsearch syntax](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-simple-query-string-query.html#simple-query-string-syntax). The syntax supports both exact and fuzzy search queries.

<!-- markdownlint-disable -->

| Syntax        | Description                     | Example                                                                                                                                              |
|--------------|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `"`          | Exact search                    | [`"gem sidekiq"`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=%22gem+sidekiq%22)                                 |
| <code>&#124;</code> | Or                       | [<code>display &#124; banner</code>](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=display+%7C+banner)                                |
| `+`          | And                             | [`display +banner`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=display+%2Bbanner&snippets=)       |
| `-`          | Exclude                         | [`display -banner`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=display+-banner)                                   |
| `*`          | Partial                         | [`bug error 50*`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=bug+error+50%2A&snippets=)         |
| `\`          | Escape                          | [`\*md`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=%5C*md&group_id=9970&project_id=278964)                  |
| `#`          | Issue ID                        | [`#23456`](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=%2323456&group_id=9970&project_id=278964)               |
| `!`          | Merge request ID                | [`!23456`](https://gitlab.com/search?snippets=&scope=merge_requests&repository_ref=&search=%2123456&group_id=9970&project_id=278964)       |

### Code search

| Syntax        | Description                     | Example                                                                                                                                              |
|--------------|---------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| `filename:`  | Filename                        | [`filename:*spec.rb`](https://gitlab.com/search?snippets=&scope=blobs&repository_ref=&search=filename%3A*spec.rb&group_id=9970&project_id=278964)     |
| `path:`      | Repository location             | [`path:spec/workers/`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=path%3Aspec%2Fworkers&snippets=)   |
| `extension:` | File extension without `.`      | [`extension:js`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=extension%3Ajs&snippets=)          |
| `blob:`      | Git object ID                   | [`blob:998707*`](https://gitlab.com/search?snippets=false&scope=blobs&repository_ref=&search=blob%3A998707*&group_id=9970)                       |

`extension:` and `blob:` return exact matches only.

### Examples

| Query                                                                                                                                                                              | Description                                                          |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------|
| [`rails -filename:gemfile.lock`](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=rails+-filename%3Agemfile.lock&snippets=)              | Returns `rails` in all files except the `gemfile.lock` file.          |
| [`RSpec.describe Resolvers -*builder`](https://gitlab.com/search?group_id=9970&project_id=278964&scope=blobs&search=RSpec.describe+Resolvers+-*builder)                              | Returns `RSpec.describe Resolvers` that does not start with `builder`. |
| [<code>bug &#124; (display +banner)</code>](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=bug+%7C+%28display+%2Bbanner%29&group_id=9970&project_id=278964)  | Returns `bug` or both `display` and `banner`.                        |
| [<code>helper -extension:yml -extension:js</code>](https://gitlab.com/search?group_id=9970&project_id=278964&repository_ref=&scope=blobs&search=helper+-extension%3Ayml+-extension%3Ajs&snippets=)  | Returns `helper` in all files except files with a `.yml` or `.js` extension.                        |

<!-- markdownlint-enable -->