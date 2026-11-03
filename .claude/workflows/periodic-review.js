export const meta = {
  name: 'periodic-review',
  description: 'Review the whole codebase at main: the security review, never skipped, and the quality review, findings recorded in the run state for the planner',
  whenToUse: '/review on demand; the delivery workflow runs it every five merged changes and after a change to config loading, file access, plugin boundaries, terminal output, process spawning, the entry point, or the tooling and CI',
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
const SECURITY = {
  type: 'object',
  properties: { ran: { type: 'boolean' }, head: { type: 'string' }, findings: { type: 'array', items: FINDING }, tool_calls: CALLS },
  required: ['ran', 'head', 'findings', 'tool_calls'],
}
const QUALITY = {
  type: 'object',
  properties: { head: { type: 'string' }, blocking: { type: 'array', items: { type: 'string' } }, advisory: { type: 'array', items: { type: 'string' } }, tool_calls: CALLS },
  required: ['head', 'blocking', 'advisory', 'tool_calls'],
}

if (!/^[a-z0-9][a-z0-9-]*$/.test(change || '')) return { ran: false, reason: `no run state named: ${change}` }
const task = `Change \`${change}\`. Mode: periodic. Review the whole tree at origin/main as your Periodic mode section says, record each finding in this run state, and return the result.`

phase('Review')
const [security, quality] = await parallel([
  async () => {
    const s = await agent(task, { agentType: 'security-reviewer', schema: SECURITY, label: 'security-reviewer: periodic' })
    if (s && s.ran) return s
    return agent(`${task} The last periodic security review did not complete; run it again, every part inline.`,
      { agentType: 'security-reviewer', schema: SECURITY, label: 'security-reviewer: periodic retry' })
  },
  () => agent(task, { agentType: 'quality-reviewer', schema: QUALITY, label: 'quality-reviewer: periodic' }),
])
const ran = Boolean(security && security.ran)
const blocking = ran ? security.findings.filter((f) => f.severity !== 'Low' && f.confidence >= 8) : []
// The review lines, each from a schema-checked result: a fixed kind, the
// reviewed commit, and counts.
const lines = []
const record = (kind, passed, head, summary) => {
  if (/^[0-9a-f]{7,40}$/.test(head || '')) lines.push(`sh tools/run_state.sh review ${change} ${kind} ${passed ? 'pass' : 'blocked'} "${summary}" ${head}`)
  else log(`${kind} not recorded: ${head} is not a commit`)
}
if (ran) {
  const count = (severity) => security.findings.filter((f) => f.severity === severity).length
  record('periodic-security', !blocking.length, security.head, `high=${count('High')} medium=${count('Medium')} low=${count('Low')} blocking=${blocking.length}`)
}
if (quality) record('periodic-quality', !quality.blocking.length, quality.head, `blocking=${quality.blocking.length} advisory=${quality.advisory.length}`)
const recorded = lines.length ? await agent(
  `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${lines.join(' && ')}\n\nReturn ok true when it exited 0, and its output.`,
  { schema: { type: 'object', properties: { ok: { type: 'boolean' }, output: { type: 'string' } }, required: ['ok', 'output'] }, effort: 'low', label: 'record' }) : { ok: true }
if (!recorded || !recorded.ok) log(`the periodic review's results were not recorded: ${recorded ? recorded.output : 'no result'}`)
log(`periodic review of ${change}: security ${ran ? `${security.findings.length} finding(s), ${blocking.length} blocking` : 'did not run'}; quality ${quality ? `${quality.blocking.length} blocking, ${quality.advisory.length} advisory` : 'did not run'}`)
return {
  ran,
  recorded: Boolean(recorded && recorded.ok),
  security: ran ? security.findings.map((f) => `${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`) : [],
  security_blocking: blocking.length,
  quality_blocking: quality ? quality.blocking : [],
  quality_advisory: quality ? quality.advisory.length : 0,
  tool_calls: [security, quality].filter(Boolean).reduce((n, r) => n + (r.tool_calls || 0), 0),
}
