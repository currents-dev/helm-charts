# Importing Organization Data (Cloud → Self-Hosted Migration)

When you migrate an organization from Currents Cloud to your self-hosted install,
Currents support runs a one-off export of that org's data and sends you a single
small file, **`download.json`**, over a secure channel (usually Slack).

This guide is everything you do on **your** side to load that data. The whole
import runs inside a temporary, gated **toolbox pod** in your cluster with one
command — `currents-import` — which downloads the artifact, restores it into your
MongoDB and ClickHouse, and verifies the result.

## Before you start

You need:

- The **`download.json`** file from Currents support.
- The **mode**, which support will tell you:
  - **`fresh`** — the organization does **not** exist on your install yet. The
    data is imported under its original organization id.
  - **`merge`** — the organization **already exists** on your install and you want
    the cloud history folded into it. You will also need the **target
    organization id** (24-character hex) on your install; support provides it.
  - **`incremental`** — a follow-up top-up into an **already-migrated** org
    (typically the final sweep at cutover), applied from a smaller Mongo-only
    delta file. Same target organization id. See
    [Follow-up (incremental) imports](#follow-up-incremental-imports).
- `kubectl` and `helm` access to the namespace where Currents is installed.
- Enough free space on the toolbox volume: roughly **1.5×** the export's total
  size. Support can tell you the artifact size; set it with
  `toolbox.persistence.size` (see step 1).

The commands below use `<release>` for your Helm release name and `<ns>` for its
namespace. Set a shell variable for the pod once it exists:

```bash
POD=$(kubectl -n <ns> get pod -l app.kubernetes.io/component=toolbox -o name)
```

## How it works

The import is a single orchestrated command that runs, in order:

**fetch** the artifact (resumable, checksum-verified) → **preflight** safety
checks → **restore MongoDB** → **verify MongoDB** → **restore ClickHouse** →
**verify ClickHouse**.

While it runs, Currents' change-streams service is put into a **maintenance
(restore) mode** so it does not re-derive and double-count the ClickHouse rollups
from the data being restored. You turn that on in step 1 and off in step 4.

---

## Step 1 — Put the chart into import mode

This enables the toolbox pod and puts change-streams into restore mode:

```bash
helm upgrade <release> currents/currents --reuse-values \
  --set toolbox.enabled=true \
  --set maintenance.clickhouseRestoreMode=true
```

If the artifact is large, also size the toolbox volume (≈1.5× the export):

```bash
  --set toolbox.persistence.size=50Gi
```

Wait for change-streams to roll out with restore mode active, and confirm it in
the logs:

```bash
kubectl -n <ns> rollout status deploy/<release>-currents-change-streams
kubectl -n <ns> logs deploy/<release>-currents-change-streams | grep -i restore
# → "CURRENTS_CLICKHOUSE_RESTORE_MODE is ON — change-stream-driven ClickHouse sync is SUPPRESSED"
```

> **Do not skip the log check.** The importer refuses to touch ClickHouse unless
> restore mode is confirmed active — this is what protects your rollup totals.

## Step 2 — Copy in the download file

```bash
POD=$(kubectl get pod -l app.kubernetes.io/component=toolbox -o name)
kubectl cp download.json ${POD#pod/}:/data/download.json
```

`download.json` is the only file you copy in. It carries time-limited download
links; if the links have expired, ask support to re-sign it (that does not change
these steps).

## Step 3 — Run the import

**Fresh** (new organization):

```bash
kubectl exec ${POD#pod/} -- \
  currents-import --mode=fresh --download=/data/download.json
```

**Merge** (into an existing organization — note the target org id):

```bash
kubectl exec ${POD#pod/} -- \
  currents-import --mode=merge --targetOrgId=<24-hex-target-org> --download=/data/download.json
```

It streams progress to the logs — per collection and per ClickHouse table — and
finishes with `import complete`. Depending on size this takes from a few minutes
to a few hours. If it stops with an error, **do not disable import mode yet** —
see [Troubleshooting](#troubleshooting) to resume.

## Step 4 — Return to normal operation

Only after the import reports success:

```bash
helm upgrade <release> currents/currents --reuse-values \
  --set toolbox.enabled=false \
  --set maintenance.clickhouseRestoreMode=false
```

This removes the toolbox pod and takes change-streams out of restore mode. Confirm
the restore-mode log line is gone after the rollout, and the imported org's data
is visible in the app.

---

## Follow-up (incremental) imports

A migration is usually done in two passes: a large **initial** import (above),
done ahead of time, then a small **incremental** import at cutover that sweeps up
everything created in between — so the only "frozen" window is that final delta.

Support sends you a second, smaller download file for the delta. The steps are
**identical** to the initial import (same chart flow, restore mode **on**) — just
use **`--mode=incremental`** with the **same target organization id**:

```bash
kubectl -n <ns> exec ${POD#pod/} -- \
  currents-import --mode=incremental --targetOrgId=<24-hex-target-org> --download=/data/delta.json
```

The delta is imported and verified in full before the command returns, exactly like
the initial import. You can repeat an incremental import as many times as needed;
re-running is safe and will not double-count.

> Support occasionally sends a **Mongo-only** delta (smaller download). Those import
> the same way, but ClickHouse for the delta repopulates in the **background** after
> the command returns — so keep restore mode on for a few minutes and confirm the new
> runs' charts have filled in before the final step. Support will tell you if a delta
> is Mongo-only, and can run a recovery step if anything is slow to appear.

---

## Troubleshooting

### The import is safe to resume — do not start over

Progress is tracked on the toolbox volume (`/data/export/.import-state.json`), and
the download is resumable and checksum-verified. Re-running after a failure
continues where it left off rather than duplicating data. **Leave import mode on**
(step 1) until the import fully succeeds.

### The ClickHouse step timed out or failed

The largest ClickHouse table (`test_metric_v2`) is the most likely place to stall
on a big org. The MongoDB restore has already completed and been verified at this
point, so **resume just the ClickHouse import** — it skips tables that already
loaded and re-runs only what's missing:

```bash
# merge:
kubectl exec ${POD#pod/} -- \
  node /app/packages/scheduler/dist/orgImport/cli.js ch-import \
  --merge --targetOrgId=<24-hex-target-org> --dir=/data/export

# fresh (use the source org id, shown in the import logs / manifest):
kubectlexec ${POD#pod/} -- \
  node /app/packages/scheduler/dist/orgImport/cli.js ch-import \
  --orgId=<24-hex-source-org> --dir=/data/export
```

This is safe to run repeatedly: completed tables are skipped, and the re-inserted
table only adds rows it hasn't already inserted, so the rollup totals stay correct
**without any manual rebuild**.

### Re-running `currents-import` says the org already exists / project already exists

That is an intentional safety check, not a failure to fight. Once the MongoDB
restore has completed, re-running the **whole** `currents-import` is refused so it
can't double-import. To finish a partially-completed import, resume the
**ClickHouse** step directly as shown above rather than re-running the full
command.

### The download links have expired

`download.json`'s links are valid for up to 7 days from when support generated
them. If `fetch` fails with an expired/forbidden error, ask support to **re-sign**
and send a new `download.json`, then repeat from step 2. The rest of the import is
unaffected.

### The change-streams pod is restarting during the import

Some restart activity is expected while a large restore floods the MongoDB oplog.
The service self-heals and resumes on its own. If it enters a persistent
`CrashLoopBackOff`, the MongoDB **oplog is too small** for the restore burst — the
oplog window collapses faster than change-streams can keep up. Increase the
replica set's oplog size (for the MongoDB Community Operator, set
`replication.oplogSizeMB` in `additionalMongodConfig`) and, if the volume can't
hold a larger oplog, grow it too. This does not affect the correctness of the
import; the change-streams pod recovers once restore mode is turned off in step 4.

### Getting help

If you're stuck, send Currents support:

- the **mode** and (for merge) the **target org id** you used,
- the `currents-import` (or `ch-import`) **logs**, and
- the output of `kubectl get pods`.
