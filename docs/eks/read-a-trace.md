# Read a Trace with an Agent

A trace link lets an agent read a failed test's Playwright trace one part at a time: the failing action, the page, the network requests and the screen, without downloading the trace. The API serves trace links at `https://<appHost>/t`, or at `https://<traceLinkHost>/t` when `currents.domains.traceLinkHost` is set; see [Trace Links](./quickstart.md#trace-links) for the settings and sizing.

An agent gets a trace link in one of three ways, then reads the trace summary at `<link>/digest?format=md` and follows the links in it. Links are public: anyone with one can read that one trace, so share them as you would a log.

## With the Currents MCP Server

Connect the agent to `https://<appHost>/mcp`, with OAuth sign-in or an API key, for example in Claude Code:

```bash
claude mcp add --transport http currents https://<appHost>/mcp \
  --header "Authorization: Bearer $CURRENTS_API_KEY"
```

Then ask about a failed test, for example "Why did `<test title>` fail in `https://<appHost>/run/<runId>`? Read the trace." The `currents-get-context` tool answers with the error and steps, and with the trace's links:

```markdown
- trace — [download trace](https://<appHost>/v1/share/…) · [explore trace](https://<appHost>/t/<slug>/digest?format=md)
```

The agent opens `explore trace`. It needs a tool that fetches a URL, such as web fetch or curl.

## From the Dashboard

On the failed test, open the menu next to **Fix**, choose **Share failure context**, and click **Create link**. The link is the failure as Markdown, with an `explore trace` link in it. **Copy as prompt** and **Copy Trace URL** give the trace as a zip download, without the summary.

## With the REST API

Create a link with an organization API key. The IDs are in the test's Recording URL in the CI log, `https://<appHost>/i/<instanceId>/test/<testId>`:

```bash
curl -s -X POST "https://<appHost>/v1/instances/<instanceId>/trace-link" \
  -H "Authorization: Bearer $CURRENTS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"testId": "<testId>"}'
# {"status":"OK","data":{"url":"https://<appHost>/t/<slug>","expiresAt":"…","testId":"<testId>","attemptIndex":0}}

curl -s "https://<appHost>/t/<slug>/digest?format=md"
```

## The Trace Summary

The summary starts with the failing action:

```markdown
# Test attempt trace summary

17 actions, 1 failed · browser: chromium · Playwright 1.65.0 (trace format 10) · 0 network requests · 3 screencast frames

## Failing actions

### Expect "toHaveText" — `internal:role=heading`
Expected: "Welcome"
Received: "Hello"
…
at t=1269ms, duration 2009ms · [frame at failure](./frames/1270) · [page text at failure](./snapshots/3278?format=text)
```

From there the agent reads what it needs: `./snapshots/failure?format=text` for the page's text at the failure, `./frames/failure` for a screenshot, `./requests` for the network requests and `./animation` for a recording of the run.
