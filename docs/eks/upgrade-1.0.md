# Upgrading to Chart 1.0

This guide covers upgrading from chart `0.8.x` (images `2026-07-26-00x`) to `1.0.x` (images `2026-10-14-00x`). Read it before you upgrade:

- The upgrade builds new MongoDB indexes. On a large database, build them yourself first, in a maintenance window.
- One change breaks SAML SSO sign-in until you update your identity provider.
- The app content bucket has to exist first.

Upgrade to `1.0.1` or later. On `1.0.0` (images `2026-10-14-001`), users who signed in before the upgrade can't sign in again. See [Sign-In After the Upgrade](#sign-in-after-the-upgrade).

For the general upgrade flow, see the [EKS Upgrade Guide](./upgrading.md). The docs for the chart you are upgrading from are at [chart 0.8.x docs](https://currents-dev.github.io/helm-charts/0.8/docs/).

## What Changes

| Change | Action |
|--------|--------|
| [New MongoDB indexes](#mongodb-index-builds) | Size them, and on a large database build them before you upgrade |
| [SAML SSO ACS URL moves](#saml-sso) | Required if you use SSO: update your IdP when you upgrade |
| [SAML assertions must be signed](#saml-sso) | Required if you use SSO: check that your IdP signs the assertion |
| [SAML sign-ins started from the IdP are refused](#saml-sso) | Set `currents.sso.saml.allowIdpInitiated: true` if your users sign in from an IdP tile |
| [App content bucket](#app-content-bucket) | Create a second bucket and set `currents.appContentStorage.bucket` |
| [Remote MCP and OAuth](#remote-mcp-and-oauth) | None: on by default. Set the values to `false` to keep them off |
| [Database migrations](#database-migrations) | None: they run when the scheduler starts. Check they finish |
| [`currents.sso.saml.spCertKey` removed](#removed-values) | Remove it from your values file |
| [Artifact expiry](#artifact-expiry) | Optional: add a lifecycle rule to the artifact bucket |

## Before You Upgrade

1. Back up MongoDB and ClickHouse. The upgrade runs database migrations, and `helm rollback` doesn't undo them.
2. Estimate how long the index builds and migrations take, and plan the upgrade window from that. See [Estimate the Upgrade Time](#estimate-the-upgrade-time).
3. If you use SAML SSO, check that your IdP signs the assertion, and schedule the ACS URL change for the upgrade window. See [SAML SSO](#saml-sso).
4. Create the app content bucket. See [App content bucket](#app-content-bucket).
5. Update your values file:

   ```yaml
   currents:
     appContentStorage:
       bucket: currents-app-content
     # Only to keep them off:
     # mcp:
     #   enabled: false
     # oauth:
     #   enabled: false
     sso:
       saml:
         # Only if users sign in from the IdP's app dashboard:
         # allowIdpInitiated: true
   ```

## Run the Upgrade

In the upgrade window, with `0.8.x` still running:

1. Build the new MongoDB indexes, unless the estimate says they take only a few minutes. See [Build the Indexes Before You Upgrade](#build-the-indexes-before-you-upgrade).
2. Upgrade:

   ```bash
   helm upgrade --install currents currents \
     --repo https://currents-dev.github.io/helm-charts/ \
     --version 1.0.1 \
     -f currents-helm-config.yaml
   ```

3. Follow the scheduler until its startup tasks finish. See [Database Migrations](#database-migrations).

## MongoDB Index Builds

`1.0` adds indexes to collections that grow with your history: `instances`, `runs` and `testRecord`. The scheduler builds any that are missing when it starts, before it runs the migrations:

- **On `instances`, it first drops the two indexes `0.8.x` uses to read a run's spec files** (`runId_1_createdAt_1__id_1` and `instanceId_1_projectId_1_orgId_1__id_-1`), then builds `runId_1_createdAt_1__id_-1` and `createdAt_1`. Until the first build finishes, reading a run's spec files has no index.
- **Each build reads the whole collection on every replica set member**, including the secondaries the API reads from.

On a large database the builds can take hours and keep MongoDB's CPU busy, and sign-in can fail while they run. Plan for them, as below.

### Estimate the Upgrade Time

Run this in `mongosh`, connected to the Currents database:

```js
const gb = (c) => db.getCollection(c).stats().size / 1e9;
const runs = db.runs.estimatedDocumentCount();
const indexGB = 2 * gb('instances') + gb('runs') + gb('testRecord');
print(`runs: ${runs}`);
print(`data the index builds read: ${indexGB.toFixed(1)} GB`);
print(`index builds: ${Math.ceil(indexGB / 60)} to ${Math.ceil(indexGB * 0.6)} minutes`);
print(`migrations: about ${Math.ceil(runs / 100000)} minutes`);
```

How the numbers are worked out:

- **Index builds** take time in proportion to the data they read. Each build reads its whole collection, and `instances` is read twice. The range is:
  - **Low end, about 1 second per GB:** measured on a test install with 100,000 runs, 500,000 `instances` (6.6 GB) and 600,000 `testRecord` documents (5.9 GB), on a fast local disk with nothing else running. All the builds took 13 seconds.
  - **High end, about 0.6 minutes per GB:** measured on a large production database, with the API reading from the secondaries while the indexes built.

  Use the high end to plan unless your MongoDB has fast disks, enough memory to hold the data, and no other load during the window.
- **Migrations** took about a minute per 100,000 runs in testing: about 30 seconds for the run status backfill, 10 to 25 seconds for `070`, and 10 seconds to create the ClickHouse tables. See [Database Migrations](#database-migrations).

If the index builds come to more than a few minutes, build the indexes yourself before you upgrade.

### Build the Indexes Before You Upgrade

With the indexes already built, the upgrade only drops the two old `instances` indexes, and run reads keep an index throughout. `0.8.x` runs normally while they build: they are extra indexes it doesn't use.

1. Start at the beginning of the upgrade window, and allow the time the [estimate](#estimate-the-upgrade-time) gives. Every replica set member, secondaries included, carries the load of the builds while they run.
2. Connect `mongosh` to the Currents database as a user that can create indexes. The user in `currents.mongoConnection` can.
3. Run:

   ```js
   db.runCommand({
     createIndexes: 'instances',
     indexes: [{ key: { runId: 1, createdAt: 1, _id: -1 }, name: 'runId_1_createdAt_1__id_-1' }],
   });
   db.runCommand({
     createIndexes: 'instances',
     indexes: [{ key: { createdAt: 1 }, name: 'createdAt_1' }],
   });
   const prRuns = { 'meta.pr.id': { $type: 'string' }, deletedAt: null };
   db.runCommand({
     createIndexes: 'runs',
     indexes: [
       { key: { orgId: 1, projectId: 1, status: 1, _id: -1 }, name: 'runs_status_recent_by_project' },
       { key: { orgId: 1, projectId: 1, _id: -1, 'meta.pr.id': 1 }, name: 'runs_pr_list_recent_by_project', partialFilterExpression: prRuns },
       {
         key: { orgId: 1, projectId: 1, _id: -1, 'meta.pr.id': 1, status: 1, completionState: 1, 'meta.pr.title': 1, 'meta.pr.source': 1 },
         name: 'runs_pr_list_search_recent_by_project',
         partialFilterExpression: prRuns,
       },
       { key: { orgId: 1, projectId: 1, 'meta.pr.source': 1, _id: -1 }, name: 'runs_pr_source_recent_by_project', partialFilterExpression: prRuns },
     ],
   });
   db.runCommand({
     createIndexes: 'testRecord',
     indexes: [
       { key: { runId: 1 }, name: 'runId_1' },
       { key: { recordId: 1, _t: 1 }, name: 'recordId_1__t_1' },
     ],
   });
   db.runCommand({
     createIndexes: 'instanceStats',
     indexes: [{ key: { 'props.projectId': 1, 'props.spec': 1, date: -1 }, name: 'props.projectId_1_props.spec_1_date_-1' }],
   });
   ```

   Each command returns when its build is done, with `ok: 1`. To follow a build in progress from a second session, run `db.currentOp({ 'command.createIndexes': { $exists: true } })`.
4. Run `helm upgrade` straight after the last build.

**Don't let the `0.8.x` scheduler restart between the builds and `helm upgrade`.** When it starts, it drops the two `instances` indexes above and rebuilds its own, so run reads lose their index again. Before upgrading, check that `db.instances.getIndexes()` lists `runId_1_createdAt_1__id_-1` and `createdAt_1`; if it doesn't, run the two `instances` commands again.

The scheduler builds the remaining new indexes itself, on `usage`, `runTimeouts`, `apiKeys`, `notifications` and `user`. Those collections stay small, and their builds take seconds.

## SAML SSO

The ACS URL moves:

| | URL |
|--|-----|
| `0.8.x` | `https://<appHost>/api/auth/sso/saml2/callback/<providerId>` |
| `1.0.0` | `https://<appHost>/api/auth/sso/saml2/sp/acs/<providerId>` |

The old path answers `404`, so SSO sign-in fails from the upgrade until your IdP sends assertions to the new URL. The root admin's email and password sign-in still works. When the upgrade is done:

1. In your IdP's SAML app, set the Single Sign-On / ACS URL (Entra ID: Reply URL) to the new URL.
2. Set the Recipient and Destination URLs to the new URL as well. In Okta, leave "Use this for Recipient URL and Destination URL" checked (the default) and both follow the Single Sign-On URL. Currents rejects an assertion whose Recipient or Destination is any other URL.
3. Leave the Audience / SP Entity ID as it is. It must still equal `currents.sso.saml.issuer`, which doesn't change.
4. Sign in from the Currents sign-in page.

A sign-in started from the IdP's app dashboard (an Okta tile, the Entra My Apps portal) is refused unless `currents.sso.saml.allowIdpInitiated` is `true`. Currents can't match such a sign-in to a request of its own. If your users don't need the tile, leave it off and have them start from the Currents sign-in page.

Currents also serves its SP metadata at `https://<appHost>/api/auth/sso/saml2/sp/metadata?providerId=<providerId>`, for IdPs that import it.

**The assertion must be signed, not just the response.** `1.0` refuses a SAML response whose `Assertion` element carries no signature, with `SAML_ASSERTION_SIGNATURE_REQUIRED`, even when the response around it is signed. There is no setting to turn this off. Check your IdP before the upgrade: in Okta, set **Assertion Signature** to **Signed**, under the app's Sign On → Advanced Settings.

## Sign-In After the Upgrade

Chart `1.0.0` (images `2026-10-14-001`) looks accounts up by a field that accounts created on `0.8.x` don't have. After upgrading to it, every user who had signed in before could not sign in again:

- SAML users returned to the sign-in page with `account_not_linked`.
- The root admin's password sign-in answered `INVALID_EMAIL_OR_PASSWORD`.

`1.0.1` (images `2026-10-14-002`) finds those accounts again, with no change to the database:

- If you are on `1.0.0`, upgrade to `1.0.1`.
- When the scheduler starts, migration `20261021-drop-account-issuer-index` drops the `account_issuer_accountId_uidx` index that `1.0.0` created. You don't need to drop it by hand.
- If you added an `issuer` field to `account` documents by hand to work around this, leave it: nothing reads it.

## App Content Bucket

Context shares, organization logos and session files go to a second bucket. Without `currents.appContentStorage.bucket`, context sharing and logo editing are off and session file uploads answer `503`.

1. Create the bucket, set its CORS rule and add its lifecycle rules as described in [App content bucket](./dependencies.md#app-content-bucket). The lifecycle rules must be scoped to the share prefixes: the bucket also holds logos and session files.
2. If the pods reach storage through IRSA, add the bucket to the role's policy. See [IRSA](./iam.md#irsa).
3. Set `currents.appContentStorage.bucket`. The other `appContentStorage` values default to the `objectStorage` ones, so the same endpoint and secret serve both buckets.

If you run RustFS in the cluster from [Alternative Object Storage](./dependencies.md#alternative-object-storage-in-cluster), upgrade it to `1.0.1` and run the bucket Job from that section again: it creates the app content bucket and its rules. Delete the earlier Job first: while it exists, applying the file doesn't start a new run.

```bash
kubectl delete job rustfs-create-bucket --ignore-not-found
```

RustFS releases before `1.0.0`, such as `1.0.0-alpha.79`, accept lifecycle rules without enforcing them.

## Remote MCP and OAuth

Remote MCP is served at `https://<appHost>/mcp`, and the OAuth provider lets MCP clients sign in with a Currents account. Both are on by default after the upgrade. OAuth turns on only when `currents.domains.https` is `true` (or `appHost` is `localhost` or a `*.localhost` name).

To keep either off, set `currents.mcp.enabled: false` or `currents.oauth.enabled: false`. See [Remote MCP and OAuth](./quickstart.md#remote-mcp-and-oauth).

To check them after the upgrade:

```bash
# 401 without credentials, 503 when MCP is off
curl -s -o /dev/null -w '%{http_code}\n' -X POST https://<appHost>/mcp
# The OAuth provider's metadata; 404 when OAuth is off
curl -s https://<appHost>/.well-known/oauth-authorization-server
```

## Database Migrations

When the scheduler starts, it first builds any missing indexes (it logs `migrations: syncing indexes`; see [MongoDB Index Builds](#mongodb-index-builds)), then runs this release's migrations:

| Migration | What it does |
|-----------|--------------|
| `20260918-backfill-run-status` | Stores each run's status on its MongoDB document |
| `20260928-drop-non-unique-plans-price-id-index` | Drops a duplicate MongoDB index |
| `20261009-backfill-github-pr-comment-mode` | Stores the pull request comment mode on each GitHub integration |
| `20261021-drop-account-issuer-index` | Drops the index `1.0.0` created on `account` (see [Sign-In After the Upgrade](#sign-in-after-the-upgrade)) |
| `050`, `060` | Add columns to `run_metric_v2` in ClickHouse |
| `070-backfill-run-metric-search-columns` | Re-inserts every run into `run_metric_v2` to fill those columns |

The migrations take about a minute per 100,000 runs: the [estimate](#estimate-the-upgrade-time) prints the figure for your install.

The dashboard, API and run recording keep running while the scheduler builds indexes and migrates, but more slowly:

- The index builds and the run status backfill load MongoDB, including the secondaries the API reads from. On a large database, upgrade in a maintenance window and build the indexes first.
- Until the migrations finish, filtering runs by status can leave out runs recorded before the upgrade.
- The change-streams pod copies every updated run to ClickHouse, during the migrations and for a few minutes after, so new results can take longer to process.

The scheduler pod reports ready while it builds indexes and runs migrations, so a finished rollout doesn't mean they are done. Follow the scheduler's log:

```bash
kubectl logs -n currents deploy/currents-scheduler -f
```

The migrations are done when it logs `Startup tasks complete`. A few `Kept the existing index` warnings on the way are expected. If a migration logs an error instead, such as a ClickHouse `Timeout error.`, restart the scheduler as described in [Database Migrations and Startup Tasks](./upgrading.md#database-migrations-and-startup-tasks).

## Removed Values

`currents.sso.saml.spCertKey` is removed; the API never read the certificate it pointed to. Signed AuthnRequests need only `spKeyKey`; upload the matching certificate to your IdP.

## Artifact Expiry

Currents does not delete artifacts. To limit how long they are kept, add a lifecycle rule to the artifact bucket as described in [Artifact expiry](./dependencies.md#artifact-expiry).

## Rollback

`helm rollback` returns the templates and images to `0.8.x`, but not the database: the migrations stay applied. To return the data to its state before the upgrade, restore the backup you took. Point your IdP back at the old ACS URL as well.

When the `0.8.x` scheduler starts, it drops the two `instances` indexes `1.0` builds and rebuilds its own. That takes as long as the `instances` builds in the [estimate](#estimate-the-upgrade-time), and reading a run's spec files has no index until the first build finishes, so roll back in a maintenance window too.
