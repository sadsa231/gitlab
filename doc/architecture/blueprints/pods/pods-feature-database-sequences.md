---
stage: enablement
group: pods
comments: false
description: 'Pods: Database Sequences'
---

DISCLAIMER:
This page may contain information related to upcoming products, features and
functionality. It is important to note that the information presented is for
informational purposes only, so please do not rely on the information for
purchasing or planning purposes. Just like with all projects, the items
mentioned on the page are subject to change or delay, and the development,
release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

This document is a work-in-progress and represents a very early state of the
Pods design. Significant aspects are not documented, though we expect to add
them in the future. This is one possible architecture for Pods, and we intend to
contrast this with alternatives before deciding which approach to implement.
This documentation will be kept even if we decide not to implement this so that
we can document the reasons for not choosing this approach.

# Pods: Database Sequences

GitLab today ensures that every database row create has unique ID, allowing
to access Merge Request, CI Job or Project by a known global ID.

Pods will use many distinct and not connected databases, each of them having
a separate IDs for most of entities.

It might be desirable to retain globally unique IDs for all database rows
to allow migrating resources between Pods in the future.

## 1. Definition

## 2. Data flow

## 3. Proposal

This are some preliminary ideas how we can retain unique IDs across the system.

### 3.1. UUID

Instead of using incremental sequences use UUID (128 bit) that is stored in database.

- This might break existing IDs and requires adding UUID column for all existing tables.
- This makes all indexes larger as it requires storing 128 bit instead of 32/64 bit in index.

### 3.2. Use Pod index encoded in ID

Since significant number of tables already use 64 bit ID numbers we could use MSB to encode
Pod ID effectively enabling

- This might limit amount of Pods that can be enabled in system, as we might decide to only
  allocate 1024 possible Pod numbers.
- This might make IDs to be migratable between Pods, since even if entity from Pod 1 is migrated to Pod 100
  this ID would still be unique.
- If resources are migrated the ID itself will not be enough to decode Pod number and we would need
  lookup table.
- This requires updating all IDs to 32 bits.

### 3.3. Allocate sequence ranges from central place

Each Pod might receive its own range of the sequences as they are consumed from a centrally managed place.
Once Pod consumes all IDs assigned for a given table it would be replenished and a next range would be allocated.
Ranges would be tracked to provide a faster lookup table if a random access pattern is required.

- This might make IDs to be migratable between Pods, since even if entity from Pod 1 is migrated to Pod 100
  this ID would still be unique.
- If resources are migrated the ID itself will not be enough to decode Pod number and we would need
  much more robust lookup table as we could be breaking previously assigned sequence ranges.
- This does not require updating all IDs to 64 bits.
- This adds some performance penalty to all `INSERT` statements in Postgres or at least from Rails as we need to check for the sequence number and potentially wait for our range to be refreshed from the ID server
- The available range will need to be stored and incremented in a centralized place so that concurrent transactions cannot possibly get the same value.

### 3.4. Define only some tables to require unique IDs

Maybe this is acceptable only for some tables to have a globally unique IDs. It could be projects, groups
and other top-level entities. All other tables like `merge_requests` would only offer Pod-local ID,
but when referenced outside it would rather use IID (an ID that is monotonic in context of a given resource, like project).

- This makes the ID 10000 for `merge_requests` be present on all Pods, which might be sometimes confusing
  as for uniqueness of the resource.
- This might make random access by ID (if ever needed) be impossible without using composite key, like: `project_id+merge_request_id`.
- This would require us to implement a transformation/generation of new ID if we need to migrate records to another pod. This can lead to very difficult migration processes when these IDs are also used as foreign keys for other records being migrated.
- If IDs need to change when moving between pods this means that any links to records by ID would no longer work even if those links included the `project_id`.
- If we plan to allow these ids to not be unique and change the unique constraint to be based on a composite key then we'd need to update all foreign key references to be based on the composite key

## 4. Evaluation

## 4.1. Pros

## 4.2. Cons
