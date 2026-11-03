export const meta = {
  name: 'periodic-review',
  description: 'Review the whole codebase at main: the security review, never skipped, and the quality review, findings recorded in the run state for the planner',
  whenToUse: '/review on demand; the delivery workflow runs it every five merged changes and after a change to config loading, file access, plugin boundaries, terminal output, or process spawning',
  phases: [
    { title: 'Review', detail: 'security and quality reviewers in their periodic mode, in parallel' },
  ],
}

// args: { change } or a string naming the run state the reviews are recorded
// in: the merged change that made the review due, or review-<date> for
// /review. The reviewers record the results and every finding with
// tools/run_state.sh; this script returns them.
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
  required: ['ran', 'head', 'findings'],
}
const QUALITY = {
  type: 'object',
  properties: { head: { type: 'string' }, blocking: { type: 'array', items: { type: 'string' } }, advisory: { type: 'array', items: { type: 'string' } }, tool_calls: CALLS },
  required: ['head', 'blocking', 'advisory'],
}

if (!change) return { ran: false, reason: 'no run state named' }
const task = `Change \`${change}\`. Mode: periodic. Review the whole tree at origin/main as your Periodic mode section says and record the result in this run state.`

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
log(`periodic review of ${change}: security ${ran ? `${security.findings.length} finding(s), ${blocking.length} blocking` : 'did not run'}; quality ${quality ? `${quality.blocking.length} blocking, ${quality.advisory.length} advisory` : 'did not run'}`)
return {
  ran,
  security: ran ? security.findings.map((f) => `${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`) : [],
  security_blocking: blocking.length,
  quality_blocking: quality ? quality.blocking : [],
  quality_advisory: quality ? quality.advisory.length : 0,
  tool_calls: [security, quality].filter(Boolean).reduce((n, r) => n + (r.tool_calls || 0), 0),
}
