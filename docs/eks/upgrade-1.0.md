# Upgrading to Chart 1.0

This guide covers upgrading from chart `0.8.x` (images `2026-07-26-00x`) to `1.0.0` (images `2026-10-14-001`). Read it before you upgrade: one change breaks SAML SSO sign-in until you update your identity provider, and the app content bucket has to exist first.

For the general upgrade flow, see the [EKS Upgrade Guide](./upgrading.md). The docs for the chart you are upgrading from are at [chart 0.8.x docs](https://currents-dev.github.io/helm-charts/0.8/docs/).

## What Changes

| Change | Action |
|--------|--------|
| [SAML SSO ACS URL moves](#saml-sso) | Required if you use SSO: update your IdP when you upgrade |
| [SAML sign-ins started from the IdP are refused](#saml-sso) | Set `currents.sso.saml.allowIdpInitiated: true` if your users sign in from an IdP tile |
| [App content bucket](#app-content-bucket) | Create a second bucket and set `currents.appContentStorage.bucket` |
| [Remote MCP and OAuth](#remote-mcp-and-oauth) | None: on by default. Set the values to `false` to keep them off |
| [Database migrations](#database-migrations) | None: they run when the scheduler starts. Check they finish |
| [`currents.sso.saml.spCertKey` removed](#removed-values) | Remove it from your values file |
| [Artifact expiry](#artifact-expiry) | Optional: add a lifecycle rule to the artifact bucket |

## Before You Upgrade

1. Back up MongoDB and ClickHouse. The upgrade runs database migrations, and `helm rollback` doesn't undo them.
2. If you use SAML SSO, schedule the IdP change for the upgrade window. See [SAML SSO](#saml-sso).
3. Create the app content bucket. See [App content bucket](#app-content-bucket).
4. Update your values file:

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

```bash
helm upgrade --install currents currents \
  --repo https://currents-dev.github.io/helm-charts/ \
  --version 1.0.0 \
  -f currents-helm-config.yaml
```

Then follow the scheduler until its migrations finish. See [Database migrations](#database-migrations).

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

The scheduler runs this release's migrations when it starts:

| Migration | What it does |
|-----------|--------------|
| `20260918-backfill-run-status` | Stores each run's status on its MongoDB document |
| `20260928-drop-non-unique-plans-price-id-index` | Drops a duplicate MongoDB index |
| `050`, `060` | Add columns to `run_metric_v2` in ClickHouse |
| `070-backfill-run-metric-search-columns` | Re-inserts every run into `run_metric_v2` to fill those columns |

With 100,000 runs, the scheduler's startup took under a minute in testing: about 25 seconds for the run status backfill and 10 seconds for `070`. They scale with the number of runs, so expect several minutes for a million.

This is not downtime: the dashboard, API and run recording keep working while the scheduler migrates. Until the migrations finish, filtering runs by status can leave out runs recorded before the upgrade. The change-streams pod also copies every updated run to ClickHouse, during the migrations and for a few minutes after, so new results can take longer to process.

The scheduler pod reports ready while the migrations run, so a finished rollout doesn't mean they are done. Follow the scheduler's log:

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
