---
stage: enablement
group: pods
comments: false
description: 'Pods: Backups'
---

This document is a work-in-progress and represents a very early state of the
Pods design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Pods, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Pods: Backups

Each pods will take its own backups, and consequently have its own isolated
backup / restore procedure.

## 1. Definition

GitLab Backup takes a backup of the PostgreSQL database used by the application,
and also Git repository data.

## 2. Data flow

Each pod has a number of application databases to back up (e.g. `main`, and `ci`).

Additionally, there may be cluster-wide metadata tables (e.g. `users` table)
which is directly accesible via PostgreSQL.

## 3. Proposal

### 3.1. Cluster-wide metadata

It is currently unknown how cluster-wide metadata tables will be accessible. We
may choose to have cluster-wide metadata tables backed up separately, or have
each pod back up its copy of cluster-wide metdata tables.

### 3.2 Consistency

#### 3.2.1 Take backups independently

As each pod will communicate with each other via API, and there will be no joins
to the users table, it should be acceptable for each pod to take a backup
independently of each other.

#### 3.2.2 Enforce snapshots

We can require that each pod take a snapshot for the PostgreSQL databases at
around the same time to allow for a consistent-enough backup.

## 4. Evaluation

As the number of pods increases, it will likely not be feasible to take a
snapshot at the same time for all pods. Hence taking backups independently is
the better option.

## 4.1. Pros

## 4.2. Cons
