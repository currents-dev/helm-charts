# Changelog

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
