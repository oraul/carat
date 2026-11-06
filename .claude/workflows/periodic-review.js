export const meta = {
  name: 'periodic-review',
  description: 'Review the whole codebase at main: the security review, never skipped, and the quality review, findings recorded in the run state for the planner',
  whenToUse: '/review on demand; the delivery workflow runs it every five merged changes and after a change to config loading, file access, plugin boundaries, terminal output, process spawning, the entry point, or the agent guard and the gates',
  phases: [
    { title: 'Review', detail: 'security and quality reviewers in their periodic mode, in parallel' },
  ],
}

// args: { change } or a string naming the run state the reviews are recorded
// in: the merged change that made the review due, or review-<date> for
// /review. The reviewers record every finding with tools/run_state.sh note;
// this script records the two results, as the delivery workflow does, from
// what the reviewers return (tools/agent_guard.sh keeps them off the
// command), and returns them.
const change = typeof args === 'string' ? args : (args || {}).change
const CALLS = { type: 'integer', description: 'how many tool calls you made for this task' }
const FINDING = {
  type: 'object',
  properties: {
    severity: { type: 'string', enum: ['High', 'Medium', 'Low'] }, confidence: { type: 'integer', minimum: 1, maximum: 10 },
    file: { type: 'string' }, line: { type: 'integer' }, title: { type: 'string' }, fix: { type: 'string' },
  },
  required: ['severity', 'confidence', 'file', 'title', 'fix'],
}
// The areas a capped review did not cover, by fixed names (the security
// reviewer's step 3) or by map area number (docs/codebase-map.md), never
// free text, since the record line carries them into a shell command.
const SECURITY_AREAS = ['config', 'files', 'plugins', 'terminal', 'processes', 'shell-tools', 'ci', 'agents']
const SECURITY = {
  type: 'object',
  properties: {
    ran: { type: 'boolean' }, head: { type: 'string' }, findings: { type: 'array', items: FINDING },
    not_reviewed: { type: 'array', items: { type: 'string', enum: SECURITY_AREAS }, description: 'the areas of your step 2 you did not cover, empty when you covered them all' },
    tool_calls: CALLS,
  },
  required: ['ran', 'head', 'findings', 'not_reviewed', 'tool_calls'],
}
const QUALITY = {
  type: 'object',
  properties: {
    head: { type: 'string' }, blocking: { type: 'array', items: { type: 'string' } }, advisory: { type: 'array', items: { type: 'string' } },
    not_reviewed: { type: 'array', items: { type: 'integer', minimum: 1, maximum: 99 }, description: 'the numbers of the docs/codebase-map.md areas your step 2 meant to read and you did not, empty when none' },
    tool_calls: CALLS,
  },
  required: ['head', 'blocking', 'advisory', 'not_reviewed', 'tool_calls'],
}
// Each reviewer start's cap: the large diff-review cap of the delivery
// workflow's CALL_CAPS, which leaves the return margin of 5 under the
// reviewers' maxTurns (tools/tools_test.sh compares them); the record
// start's is its FIXED_CAPS record cap.
const PERIODIC_CAP = 53
const RECORD_CAP = 3
const capLine = (cap) => `\nTool calls: at most ${cap} in this start (a fixed cap). Count them; on reaching the cap, stop and return the schema with what is done, saying the cap stopped you.`

if (!/^[a-z0-9][a-z0-9-]*$/.test(change || '')) return { ran: false, reason: `no run state named: ${change}` }
const task = `Change \`${change}\`. Mode: periodic. Review the whole tree at origin/main as your Periodic mode section says, record each finding in this run state, and return the result; list in not_reviewed what you did not cover.${capLine(PERIODIC_CAP)}`
const isCommit = (head) => /^[0-9a-f]{7,40}$/.test(head || '')

phase('Review')
const starts = []
const counted = (kind, r) => {
  if (r && Number.isInteger(r.tool_calls)) starts.push({ kind, tool_calls: r.tool_calls })
  return r
}
const [security, quality] = await parallel([
  async () => {
    const s = counted('security', await agent(task, { agentType: 'security-reviewer', schema: SECURITY, label: 'security-reviewer: periodic' }))
    if (s && s.ran && isCommit(s.head)) return s
    return counted('security retry', await agent(task.replace('Mode: periodic.', 'Mode: periodic. The last periodic security review did not complete; run it again, every part inline.'),
      { agentType: 'security-reviewer', schema: SECURITY, label: 'security-reviewer: periodic retry' }))
  },
  async () => counted('quality', await agent(task, { agentType: 'quality-reviewer', schema: QUALITY, label: 'quality-reviewer: periodic' })),
])
// A security result counts only with ran true and a commit as its head;
// without one the review is recorded as not run, never as passed.
const ran = Boolean(security && security.ran && isCommit(security.head))
const blocking = ran ? security.findings.filter((f) => f.severity !== 'Low' && f.confidence >= 8) : []
const gotQuality = Boolean(quality && isCommit(quality.head))
// The review lines, each from a schema-checked result or its absence: a
// fixed kind, a fixed result word, counts, and the areas not reviewed. A
// partial result outranks blocked, so a partial review keeps the next one
// due (tools/run_state.sh review-due).
const result = (blocked, missed) => (missed.length ? 'partial' : blocked ? 'blocked' : 'pass')
const missedOf = (r) => (r && Array.isArray(r.not_reviewed) ? r.not_reviewed.filter((a) => SECURITY_AREAS.includes(a) || Number.isInteger(a)) : [])
const tail = (missed) => (missed.length ? ` not_reviewed=${missed.join(',')}` : '')
const lines = []
const record = (kind, word, summary, head) => lines.push(`sh tools/run_state.sh review ${change} ${kind} ${word} "${summary}"${head ? ` ${head}` : ''}`)
if (ran) {
  const count = (severity) => security.findings.filter((f) => f.severity === severity).length
  record('periodic-security', result(blocking.length, missedOf(security)), `high=${count('High')} medium=${count('Medium')} low=${count('Low')} blocking=${blocking.length}${tail(missedOf(security))}`, security.head)
} else record('periodic-security', 'not-run', 'no result after the retry', '')
if (gotQuality) record('periodic-quality', result(quality.blocking.length, missedOf(quality)), `blocking=${quality.blocking.length} advisory=${quality.advisory.length}${tail(missedOf(quality))}`, quality.head)
else record('periodic-quality', 'not-run', 'no result', '')
// A start over its cap leaves an overrun note for the planner, of fixed
// words and numbers, as the delivery workflow's overCap does.
const over = starts.filter((r) => r.tool_calls > PERIODIC_CAP).map((r) => `periodic ${r.kind} made ${r.tool_calls} tool calls in one start, over its cap of ${PERIODIC_CAP}`)
for (const text of over) lines.push(`sh tools/run_state.sh note ${change} overrun "${text}"`)
const recorded = await agent(
  `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${lines.join(' && ')}\n\nReturn ok true when it exited 0, and its output.${capLine(RECORD_CAP)}`,
  { schema: { type: 'object', properties: { ok: { type: 'boolean' }, output: { type: 'string' } }, required: ['ok', 'output'] }, effort: 'low', label: 'record' })
if (!recorded || !recorded.ok) log(`the periodic review's results were not recorded: ${recorded ? recorded.output : 'no result'}`)
log(`periodic review of ${change}: security ${ran ? `${security.findings.length} finding(s), ${blocking.length} blocking${tail(missedOf(security))}` : 'did not run'}; quality ${gotQuality ? `${quality.blocking.length} blocking, ${quality.advisory.length} advisory${tail(missedOf(quality))}` : 'did not run'}`)
return {
  ran,
  recorded: Boolean(recorded && recorded.ok),
  security: ran ? security.findings.map((f) => `${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`) : [],
  security_blocking: blocking.length,
  security_not_reviewed: ran ? missedOf(security) : [],
  quality_blocking: gotQuality ? quality.blocking : [],
  quality_advisory: gotQuality ? quality.advisory.length : 0,
  quality_not_reviewed: gotQuality ? missedOf(quality) : [],
  over,
  tool_calls: starts.reduce((n, r) => n + r.tool_calls, 0),
}
