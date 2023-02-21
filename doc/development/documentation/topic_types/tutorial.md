---
stage: none
group: Style Guide
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tutorial page type

A tutorial is page that contains an end-to-end walkthrough of a complex workflow or scenario.
In general, you might consider using a tutorial when:

- The workflow requires a number of sequential steps where each step consists
  of sub-steps.
- The steps cover a variety of GitLab features or third-party tools.

Tutorials are learning aids that complement our core documentation.
They do not introduce new features.
Always use the primary [topic types](index.md) to document new features.

## Tutorial format

Tutorials should be in this format:

```markdown
# Title (starts with "Tutorial:" followed by an active verb, like "Tutorial: Create a website")

A paragraph that explains what the tutorial does, and the expected outcome.

To create a website:

1. [Do the first task](#do-the-first-task)
1. [Do the second task](#do-the-second-task)

Prerequisites (optional):

- Thing 1
- Thing 2
- Thing 3

## Do the first task

To do step 1:

1. First step.
1. Another step.
1. Another step.

## Do the second task

Before you begin, make sure you have [done the first task](#do-the-first-task).

To do step 2:

1. First step.
1. Another step.
1. Another step.
```

An example of a tutorial that follows this format is
[Tutorial: Make your first Git commit](../../../tutorials/make_your_first_git_commit.md).

## Tutorial page title

Start the page title with `Tutorial:` followed by an active verb, like `Tutorial: Create a website`.

In the left nav, use the full page title. Do not abbreviate it.
Put the text in quotes so the pipeline will pass. For example,
`"Tutorial: Make your first Git commit"`.

On [the **Learn GitLab with tutorials** page](../../../tutorials/index.md),
do not use `Tutorial` in the title.

## Screenshots

You can include screenshots in a tutorial to illustrate important steps in the process.
In the core product documentation, you should [use screenshots sparingly](../styleguide/index.md#images).
However, in tutorials, screenshots can help users understand where they are in a complex process.

Try to balance the number of screenshots in the tutorial so they don't disrupt
the narrative flow. For example, do not put one large screenshot in the middle of the tutorial.
Instead, put multiple, smaller screenshots throughout.

## Tutorial voice

Use a friendlier tone than you would for other topic types. For example,
you can:

- Add encouraging or congratulatory phrases after tasks.
- Use future tense from time to time, especially when you're introducing
  steps. For example, `Next, you will associate your issues with your epics`.
- Be more conversational. For example, `This task might take a while to complete`.

## Metadata

On pages that are tutorials, add the most appropriate `stage:` and `group:` metadata at the top of the file.
If the majority of the content does not align with a single group, specify `none` for the stage
and `Tutorials` for the group:

```plaintext
stage: none
group: Tutorials
```
