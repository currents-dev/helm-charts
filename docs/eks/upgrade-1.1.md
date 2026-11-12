# Upgrading to Chart 1.1

This guide covers upgrading from chart `1.0.x` (images `2026-10-14-00x`) to `1.1.x` (images `2026-11-10-00x`). From `0.8.x`, follow [Upgrading to Chart 1.0](./upgrade-1.0.md) as well: its changes still apply.

For the general upgrade flow, see the [EKS Upgrade Guide](./upgrading.md).

## What Changes

| Change | Action |
|--------|--------|
| [New MongoDB indexes](#mongodb-index-builds) | None on most installs: they build in seconds. If the pre-upgrade index check stops the upgrade, build them first |
| [Database migrations](#database-migrations) | None: they run when the scheduler starts |
| [Stored key hashes](#keys-left-without-a-hash) | Resolve any keys the scheduler reports as shared |

## MongoDB Index Builds

The `2026-11-10` scheduler builds six MongoDB indexes and runs five migrations when it starts. None of the indexes is on `instances`, `runs` or `testRecord`, and the migrations read only keys and secrets, so there is nothing to build ahead of the upgrade. On a test install with 3.1 million `instances` (41 GB), 310,000 runs and 124,000 orchestration sessions, the scheduler logged `Startup tasks complete` 18 seconds after it started.

The chart's pre-upgrade index check, described in [Index Builds Before an Upgrade](./upgrading.md#index-builds-before-an-upgrade), passes on an install like that one: the command it runs estimated 25 seconds there, and the builds took 1 second.

Of the new indexes, only the one on `orchestrationSession` grows with your history, and only if you use orchestration. At the check's default rate the collection would need about 18 GB to pass the 600-second threshold. If the check stops the upgrade and its log names `orchestrationSession`, build the index first as in [Ways Forward](./upgrading.md#ways-forward).

| Index | Collection |
|---|---|
| `orchestrationSession` `{ runId: 1 }` | Grows with orchestrated runs. |
| `oauthRefreshToken` `{ rotationReplayExpiresAt: 1 }` | Small: refresh tokens of MCP clients. |
| `orgStorageDaily` `{ date: 1, orgId: 1, bytes: 1 }` | Empty on-prem. |
| `scimPendingUsers` `{ orgId: 1, email: 1 }` (unique) | Written only by SCIM provisioning. |
| `customerRequests`, two indexes | Empty on-prem. |

## Database Migrations

| Migration | What it does | Time in testing |
|---|---|---|
| `20261028-drop-superseded-instances-indexes` | Drops two `instances` indexes that newer ones replace, once the replacements exist. Chart `1.0` already dropped them, so it finds nothing. | 3 ms |
| `20261103-redact-audit-log-secrets` | Masks credentials in stored audit log records. On-prem doesn't store audit records in MongoDB, so it usually finds none. | 553 ms for 10,000 records |
| `20261109-backfill-api-key-hashes` | Stores a hash and the last 4 characters of each organization API key. | 202 ms for 3,000 keys |
| `20261110-backfill-record-key-hashes` | Stores a hash and the last 4 characters of each record key. | 25 ms for 400 keys |
| `20261110-backfill-scim-secret-hashes` | Stores a hash and the last 4 characters of the SCIM secret. | 2 ms |

## Keys Left Without a Hash

The two key migrations leave a key without a hash when another document holds the same value, and log a warning with the documents' ids:

- `left N organization API key(s) in M group(s) without a hash`: API keys that share a value already fail to authenticate. Delete the extra copies.
- `left N record key(s) without a hash`: a record key shared by two organizations. Have all but one of them rotate their record key; deleting a copy breaks that organization's CI.

## Rollback

Rolling back to the `2026-10-14` images builds and drops nothing: their scheduler keeps the new indexes, and the stored hashes are fields it doesn't read.
