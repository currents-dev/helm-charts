# Changelog

## [Unreleased]

### Security
- The `2026-10-14-002` images run Node.js 24.22.1, which fixes [CVE-2026-111497](https://nvd.nist.gov/vuln/detail/CVE-2026-111497): an out-of-bounds write in the Brotli decoder of `node:zlib`, through which crafted Brotli data can corrupt memory and possibly run code. Chart `1.0.0` defaults to `2026-10-14-001`, which runs Node.js 24.22.0 without the fix; on `1.0.0`, set `currents.imageTag: 2026-10-14-002` to get it.


## [currents-1.0.0](https://github.com/currents-dev/helm-charts/releases/tag/currents-1.0.0) - 2026-10-14

Images `2026-10-14-001`, the first Currents on-prem feature release since `2026-07-26`, and the chart's first major version. It breaks SAML SSO sign-in until you update your identity provider, so read [Upgrading to Chart 1.0](docs/eks/upgrade-1.0.md) before you upgrade. From 1.0.0 the chart follows semantic versioning (see [Chart Versions](docs/README.md#chart-versions)).

### Breaking Changes
- **The SAML SSO ACS URL moves** from `https://<appHost>/api/auth/sso/saml2/callback/<providerId>` to `https://<appHost>/api/auth/sso/saml2/sp/acs/<providerId>`. The old path answers `404`, so SSO sign-in fails from the upgrade until your IdP sends assertions to the new URL. In your IdP's SAML app:
  - set the Single Sign-On / ACS URL (Entra ID: Reply URL) to the new URL;
  - set the Recipient and Destination URLs to the same URL, since Currents rejects an assertion addressed to any other. In Okta, leaving "Use this for Recipient URL and Destination URL" checked does this;
  - leave the Audience / SP Entity ID as it is: it still equals `currents.sso.saml.issuer`.

  The root admin's email and password sign-in keeps working throughout.
- **SAML sign-ins started from the IdP are refused** (an Okta tile, the Entra My Apps portal) unless `currents.sso.saml.allowIdpInitiated` is `true`. Sign-ins started from the Currents sign-in page work either way.
- **`currents.sso.saml.spCertKey` is removed.** The API never read the certificate it pointed to. Signed AuthnRequests need only `spKeyKey`; upload the matching certificate to your IdP. Remove the value from your values file.

### Upgrade Notes
- **Create the app content bucket first** and set `currents.appContentStorage.bucket`. Without it, context sharing and logo editing are off and session file uploads answer `503`. Its lifecycle rules must be scoped to the share prefixes, because the bucket also holds logos and session files. See [App content bucket](docs/eks/dependencies.md#app-content-bucket).
- **The scheduler builds new MongoDB indexes, then runs migrations, when it starts.**
  - On `instances` it first drops the indexes `0.8.x` reads a run's spec files with, so those reads have no index until the build finishes.
  - The builds load every replica set member, and on a large database they take hours.
  - Estimate the time for your install, and on a large database build the indexes before upgrading, in a maintenance window. See [MongoDB Index Builds](docs/eks/upgrade-1.0.md#mongodb-index-builds).
  - The migrations take about a minute per 100,000 runs.
  - The scheduler pod reports ready before all this finishes, so wait for `Startup tasks complete` in its log, and restart it if a migration logs an error (see [Database Migrations and Startup Tasks](docs/eks/upgrading.md#database-migrations-and-startup-tasks)).
- **SAML SSO requires a signed assertion.** A response whose `Assertion` isn't signed is refused with `SAML_ASSERTION_SIGNATURE_REQUIRED`, even when the response itself is signed. In Okta, set Assertion Signature to Signed. See [SAML SSO](docs/eks/upgrade-1.0.md#saml-sso).
- **Upgrade to `1.0.1` or later.** On `1.0.0`, users who signed in before the upgrade can't sign in. See [Sign-In After the Upgrade](docs/eks/upgrade-1.0.md#sign-in-after-the-upgrade).
- **Back up MongoDB and ClickHouse before upgrading.** `helm rollback` returns the chart and images to `0.8.x` but doesn't undo the migrations.

### Added
- `currents.appContentStorage.*`: the app content bucket for context shares, organization logos and session files. Unset fields fall back to `currents.objectStorage`, so one endpoint and secret can serve both buckets.
- `currents.mcp.enabled`, `currents.mcp.origins`: remote MCP at `https://<appHost>/mcp`, for coding agents using a Currents API key, a personal access token or an OAuth sign-in.
- `currents.oauth.enabled`, `currents.oauth.dynamicClientRegistration`, `currents.oauth.clientIdMetadataDocuments`: the OAuth provider that lets MCP clients sign in with a Currents account.
- `currents.sso.saml.allowIdpInitiated`: accept SAML sign-ins started from the IdP.
- The images add remote MCP, personal access tokens, context sharing, session files and run attachments. See the [Docker Compose changelog](https://github.com/currents-dev/docker/blob/on-prem/2026-10-14-001/on-prem/CHANGELOG.md#2026-10-14-001---2026-10-14) for everything in `2026-10-14-001`.

### Changed
- **Remote MCP and the OAuth provider are on after the upgrade.** `/mcp` answers `401` without a valid credential. OAuth turns on only with `currents.domains.https: true`, or an `appHost` of `localhost` or a `*.localhost` name. Set `currents.mcp.enabled: false` or `currents.oauth.enabled: false` to keep either off.
- **Dependency guidance:** the in-cluster MongoDB, ClickHouse and RustFS setups in the dependencies guide are for evaluation. The Redis the chart can install suits installs up to about 100 runs a day; above that, run your own, and drain its queues before switching (see [Redis](docs/eks/dependencies.md#redis)).
- The docs for chart `0.8.x` stay published at [0.8/docs](https://currents-dev.github.io/helm-charts/0.8/docs/).

### Commits
- [`4da2922`](https://github.com/currents-dev/helm-charts/commit/4da29225402946cf068bd2ebadcaa547730c7e53) feat: expose the app-content bucket, MCP and OAuth [ENG-1740] (#59)
- [`f64819e`](https://github.com/currents-dev/helm-charts/commit/f64819e303516c1cff5cc60f58d2e16c9760e68b) feat: add currents.sso.saml.allowIdpInitiated, the new SAML ACS URL and a 1.0 upgrade guide [ENG-1736] (#61)


## [currents-0.8.1](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.8.1) - 2026-10-07


### Bug Fixes
- [`a2ee577`](https://github.com/currents-dev/helm-charts/commit/a2ee577c872c5b75728427c4dde63e9c1961d24b) fix: update the images to 2026-07-26-006, so the director returns an error instead of restarting when Redis rejects a write, the writer no longer fills its PM2_HOME volume with log files, the dashboard no longer sends errors to Currents' Sentry, and two Redis caches expire sooner
- [`a2ee577`](https://github.com/currents-dev/helm-charts/commit/a2ee577c872c5b75728427c4dde63e9c1961d24b) fix: keep the bundled Redis accepting writes when a snapshot fails [ENG-1707] (#56)


## [currents-0.8.0](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.8.0) - 2026-09-16


### Features
- [`dc36a35`](https://github.com/currents-dev/helm-charts/commit/dc36a35b3ee48a9545d5d68600e9c987bf2e4ef7) feat: allow an external Redis, with credentials from a secret (#54)


## [currents-0.7.5](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.7.5) - 2026-09-09


### Bug Fixes
- [`910a572`](https://github.com/currents-dev/helm-charts/commit/910a572f324aed82806971258599a311615671a5) fix: Bring in new patched images to fix a IRSA memory leak
- [`910a572`](https://github.com/currents-dev/helm-charts/commit/910a572f324aed82806971258599a311615671a5) fix: stop the default probes and pm2 log storage from restarting pods (#52)


## [currents-0.7.4](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.7.4) - 2026-08-13


### Bug Fixes
- [`a999e30`](https://github.com/currents-dev/helm-charts/commit/a999e301c82246f5ab35aae77e13427a97fe1b25) fix: bump version to 0.7.4 and update app version to 2026-07-26-003 (#50)


## [currents-0.7.3](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.7.3) - 2026-08-12


### Other
- [`e1eb2c1`](https://github.com/currents-dev/helm-charts/commit/e1eb2c10bfed1a4dbb5a1329f99c2945453242ed) chore: bump version to 0.7.3 and update app version to 2026-07-26-002 (#48)


## [currents-0.7.2](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.7.2) - 2026-08-02


### Bug Fixes
- [`cd03b76`](https://github.com/currents-dev/helm-charts/commit/cd03b761370a9f75a0d52cb98f5012eedf79a935) fix: expose the ses email transporter so smtp isn't hardcoded (#46)


## [currents-0.7.1](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.7.1) - 2026-07-28


### Features
- [`00cb7eb`](https://github.com/currents-dev/helm-charts/commit/00cb7eb80bfda08281269a3bdde4874520d1282f) feat: Add a data importer for bringing cloud data into onPrem (#44)
- [`021d5b5`](https://github.com/currents-dev/helm-charts/commit/021d5b52677ab563e35b74e2ee5a9cb999181de4) feat: bump image to the July 26 2026 release to include data importer


## [currents-0.7.0](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.7.0) - 2026-07-15


### Features
- [`ad3c86d`](https://github.com/currents-dev/helm-charts/commit/ad3c86d398787e36f790457c8a72edbde2acbe5c) [ENG-715] feat: Update workflows and add SAML SSO support (#42)
- Bump to the July 15 2026 image release of Currents


## [currents-0.6.0](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.6.0) - 2026-03-26


### Features
- [`5b1e3f9`](https://github.com/currents-dev/helm-charts/commit/5b1e3f91c7e2de4f7e93823dd596010136d5cbed) Replace elasticsearch with clickhouse in the EKS setup docs (#38)
- [`be331f0`](https://github.com/currents-dev/helm-charts/commit/be331f0f74091f1240c7a06a3542f801588f3f8f) Swap minio for rustfs (#39)
- [`6b5ff24`](https://github.com/currents-dev/helm-charts/commit/6b5ff24b89ec2696b5fbc8ea6da79f69fabe60c9) Better auth (#40)


## [currents-0.5.0](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.5.0) - 2025-10-02

- [`4857485`](https://github.com/currents-dev/helm-charts/commit/485748546cfbcd966b73feb951cd24f3d224f3fd) fix: typo in iam doc permissions (#35)
- [`dfc5f11`](https://github.com/currents-dev/helm-charts/commit/dfc5f112de338861878399548529f9a56f0c5d46) feat: Update the image tag to 2025-10-02-001 (#36)
  - Support for Tagging tests in Currents Actions ([details](https://currents.featurebase.app/changelog/action-engine-update-label-add-tags-error-condition))
  - A refreshed, more polished UI that brings consistent components, fonts and sizing among all the pages
  - Security updates to dependencies

## [currents-0.4.0](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.4.0) - 2025-06-10

- Update to the `2025-06-10-001` image version. Bringing in May 2025 updates.
  - Batched Orchestration support ([details]((https://changelog.currents.dev/changelog/more-effective-ci-orchestration-currentsplaywright1130)))
  - Error Explorer Improvements ([details](https://changelog.currents.dev/changelog/error-explorer-improvements))
  - Improved Integrations UI ([details](https://changelog.currents.dev/changelog/improved-integrations))

## [currents-0.3.0](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.3.0) - 2025-04-23

New release supports using IAM service account roles for EKS

- [`9032de5`](https://github.com/currents-dev/helm-charts/commit/9032de5fa3bd814cb1cfe4600d4d747feafe01b2) feat: Update the image tag to 2025-04-23-001 (#29)

## [currents-0.2.1](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.2.1) - 2025-04-17

- [`6572449`](https://github.com/currents-dev/helm-charts/commit/65724496022119dd21084e36a2ea57d69275e2cb) fix: enable s3 region to be configured (#25)

## [currents-0.2.0](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.2.0) - 2025-04-09

- [`f45ae1d`](https://github.com/currents-dev/helm-charts/commit/f45ae1d6b3239ba9e6b2383c8e30b507dc7e1670) fix: Point to the director url in the dashboard (#17)
- [`1412b80`](https://github.com/currents-dev/helm-charts/commit/1412b80a26c12f854b94261341c70bfe0c8caa78) [CSR-2410] feat: Simplify number of places domains need to be specified (#15)

## [currents-0.1.1](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.1.1) - 2025-04-04

- [`5e4279e`](https://github.com/currents-dev/helm-charts/commit/5e4279e1344e8e5ec47812ffd1891ff0cd1630ea) feat: Expose the SMTP settings (#8)
- [`720d9fb`](https://github.com/currents-dev/helm-charts/commit/720d9fb255867ff3201322ffa215a2a0e7ff4793) fix: Assign the es indexes (#7)
- [`173734c`](https://github.com/currents-dev/helm-charts/commit/173734cfab8b4f35667d9df0c8388be6d1d2a33a) fix: add webhooks service to heml chart (#5)
- [`3eeca3c`](https://github.com/currents-dev/helm-charts/commit/3eeca3c217fa9af7d5ed8205572faa2b334be0ea) Merge pull request #4 from currents-dev/chore/move-user-config

## [currents-0.1.0](https://github.com/currents-dev/helm-charts/releases/tag/currents-0.1.0) - 2025-03-27

- [`ece5a9d`](https://github.com/currents-dev/helm-charts/commit/ece5a9dbe3b3402503a6b73cee75e692bb7ec6f1) feat: initial chart
