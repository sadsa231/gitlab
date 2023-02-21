---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# RuboCop rule development guide

Our codebase style is defined and enforced by [RuboCop](https://github.com/rubocop-hq/rubocop).

You can check for any offenses locally with `bundle exec rubocop --parallel`.
On the CI, this is automatically checked by the `static-analysis` jobs.

In addition, you can [integrate RuboCop](developing_with_solargraph.md) into
supported IDEs using the [Solargraph](https://github.com/castwide/solargraph) gem.

For RuboCop rules that we have not taken a decision on, follow the [Ruby style guide](backend/ruby_style_guide.md) to write idiomatic Ruby.

Reviewers/maintainers should be tolerant and not too pedantic about style.

Some RuboCop rules are disabled, and for those,
reviewers/maintainers must not ask authors to use one style or the other, as both
are accepted. This isn't an ideal situation because this leaves space for
[bike-shedding](https://en.wiktionary.org/wiki/bikeshedding). Ideally we
should enable all RuboCop rules to avoid style-related
discussions, nitpicking, or back-and-forth in reviews. The
[GitLab Ruby style guide](backend/ruby_style_guide.md) includes a non-exhaustive
list of styles that commonly come up in reviews and are not enforced.

Additionally, we have dedicated
[test-specific style guides and best practices](testing_guide/index.md).

## Creating new RuboCop cops

Typically it is better for the linting rules to be enforced programmatically as it
reduces the aforementioned [bike-shedding](https://en.wiktionary.org/wiki/bikeshedding).

To that end, we encourage creation of new RuboCop rules in the codebase.

Before adding a new cop to enforce a given style, make sure to discuss it with your team.

We maintain cops across several Ruby code bases, and not all of them are
specific to the GitLab application.
When creating a new cop that could be applied to multiple applications, we encourage you
to add it to our [`gitlab-styles`](https://gitlab.com/gitlab-org/gitlab-styles) gem.
If the cop targets rules that only apply to the main GitLab application,
it should be added to [GitLab](https://gitlab.com/gitlab-org/gitlab) instead.

## Cop grace period

A cop is in a _grace period_ if it is enabled and has `Details: grace period` defined in its TODO YAML configuration.

On the default branch, offenses from cops in the [grace period](rake_tasks.md#run-rubocop-in-graceful-mode) do not fail the RuboCop CI job. Instead, the job notifies the `#f_rubocop` Slack channel. However, on other branches, the RuboCop job fails.

A grace period can safely be lifted as soon as there are no warnings for 2 weeks in the `#f_rubocop` channel on Slack.

## Enabling a new cop

1. Enable the new cop in `.rubocop.yml` (if not already done via [`gitlab-styles`](https://gitlab.com/gitlab-org/ruby/gems/gitlab-styles)).
1. [Generate TODOs for the new cop](rake_tasks.md#generate-initial-rubocop-todo-list).
1. [Set the new cop to `grace period`](#cop-grace-period).
1. Create an issue to fix TODOs and encourage community contributions (via ~"good for new contributors" and/or ~"Seeking community contributions"). [See some examples](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=created_date&state=opened&label_name%5B%5D=good%20for%20new%20contributors&label_name%5B%5D=static%20code%20analysis&first_page_size=20).
1. Create an issue to remove `grace period` after 2 weeks of silence in the `#f_rubocop` Slack channel. [See an example](https://gitlab.com/gitlab-org/gitlab/-/issues/374903).

## Silenced offenses

When offenses are silenced for cops in the [grace period](#cop-grace-period),
the `#f_rubocop` Slack channel receives a notification message every 2 hours.

To fix this issue:

1. Find cops with silenced offenses in the linked CI job.
1. [Generate TODOs](rake_tasks.md#generate-initial-rubocop-todo-list) for these cops.

### RuboCop node pattern

When creating [node patterns](https://docs.rubocop.org/rubocop-ast/node_pattern.html) to match
Ruby's AST, you can use [`scripts/rubocop-parse`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/rubocop-parse).
This displays the AST of a Ruby expression to help you create the matcher.
See also [!97024](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97024).

## Resolving RuboCop exceptions

When the number of RuboCop exceptions exceeds the default [`exclude-limit` of 15](https://docs.rubocop.org/rubocop/1.2/usage/basic_usage.html#command-line-flags),
we may want to resolve exceptions over multiple commits. To minimize confusion,
we should track our progress through the exception list.

The preferred way to [generate the initial list or a list for specific RuboCop rules](rake_tasks.md#generate-initial-rubocop-todo-list)
is to run the Rake task `rubocop:todo:generate`:

```shell
# Initial list
bundle exec rake rubocop:todo:generate

# List for specific RuboCop rules
bundle exec rake 'rubocop:todo:generate[Gitlab/NamespacedClass,Lint/Syntax]'
```

This Rake task creates or updates the exception list in `.rubocop_todo/`. For
example, the configuration for the RuboCop rule `Gitlab/NamespacedClass` is
located in `.rubocop_todo/gitlab/namespaced_class.yml`.

Make sure to commit any changes in `.rubocop_todo/` after running the Rake task.

## Reveal existing RuboCop exceptions

To reveal existing RuboCop exceptions in the code that have been excluded via `.rubocop_todo.yml` and
`.rubocop_todo/**/*.yml`, set the environment variable `REVEAL_RUBOCOP_TODO` to `1`.

This allows you to reveal existing RuboCop exceptions during your daily work cycle and fix them along the way.

NOTE:
Define permanent `Exclude`s in `.rubocop.yml` instead of `.rubocop_todo/**/*.yml`.
