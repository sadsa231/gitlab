---
description: "Learn how long your open merge requests have spent in code review, and what distinguishes the longest-running." # Up to ~200 chars long. They will be displayed in Google Search snippets. It may help to write the page intro first, and then reuse it here.
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---


# Code review analytics **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

Code review analytics displays a table of open merge requests that have at least one non-author comment.
The review time is the amount of time since the first comment by a non-author in a merge request.

You can use code review analytics to view review metrics per merge request
and improve your code review process.

- A high number of comments or commits may indicate:
  - Code that is too complex.
  - Authors who require more training.
- A long review time may indicate:
  - Types of work that move slower than other types.
  - Opportunities to accelerate your development cycle.
- Few comments and approvers may indicate a lack of available team members.

## View code review analytics

Prerequisite:

- You must have at least the Reporter role.

To view code review analytics:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > Code Review**.
1. Optional. Filter results:
   1. Select the filter bar.
   1. Select a parameter. You can filter merge requests by milestone and label.
   1. Select a value for the selected parameter.

The table shows up to 20 merge requests in review per page,
and includes the following information about each merge request:

- Merge request title
- Review time
- Author
- Approvers
- Comments
- Commits
- Line changes
