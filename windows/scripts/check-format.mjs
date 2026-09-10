import assert from "node:assert/strict";
import { tokenSummary, escapeHtml } from "../src/format.ts";

assert.deepEqual(tokenSummary([
  { startDate: "2026-09-10", tokens: 30 },
  { startDate: "2026-09-01", tokens: 999 },
  { startDate: "2026-09-09", tokens: 20 },
  { startDate: "2026-09-08", tokens: 10 },
  { startDate: "2026-09-11", tokens: 999 },
], new Date(2026, 8, 10, 12)), { yesterday: 20, week: 60 });
assert.equal(tokenSummary(null), undefined);
assert.deepEqual(tokenSummary([]), { yesterday: 0, week: 0 });
assert.equal(escapeHtml('<img src="x" onerror=\'alert(1)\'>&'), '&lt;img src=&quot;x&quot; onerror=&#039;alert(1)&#039;&gt;&amp;');
console.log("Date-based token totals, unavailable data and HTML escaping: passed");
