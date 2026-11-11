export const meta = {
  name: 'sprint-planning',
  description: 'Close a sprint of five merged changes: the review of its combined diff (security, never skipped, quality and architecture, and the skeptic), the whole-tree sweep every second sprint, the backlog grooming, and the next sprint\'s queue of five, which the next package step applies with its metrics row',
  whenToUse: '/sprint after a merge; it ends at once with "not due" until the sprint\'s five changes have merged',
  phases: [
    { title: 'Due', detail: 'one start runs review-due; not due ends the run' },
    { title: 'Review', detail: 'the security and quality reviewers over the combined diff in their sprint mode, and in an even sprint the whole-tree sweep, in parallel' },
    { title: 'Skeptic', detail: 'the quality reviewer reads both results against the code: records the quality findings it keeps and every security finding, one it disputes as disputed' },
    { title: 'Plan', detail: 'the planner in its sprint mode: the backlog grooming and the next sprint\'s queue under build/plan/' },
    { title: 'Record', detail: 'the review results in the sprint\'s run state' },
  ],
}

// args: none. The sprint is the one tools/run_state.sh review-due counts
// (docs/sprints.tsv): due once its five changes merged, not due while its
// plan waits in build/plan/ for the next package step, which applies it
// with tools/run_state.sh groom. The diff reviewers record nothing; the
// skeptic records the findings it keeps, so a quality finding it drops is
// never recorded and a security finding it disputes is recorded as
// disputed. The sweep, the whole-tree periodic review, records in its own
// run state, <sprint>-sweep.
const CALLS = { type: 'integer', description: 'how many tool calls you made for this task' }
const FINDING = {
  type: 'object',
  properties: {
    severity: { type: 'string', enum: ['High', 'Medium', 'Low'] }, confidence: { type: 'integer', minimum: 1, maximum: 10 },
    file: { type: 'string' }, line: { type: 'integer' }, title: { type: 'string' }, fix: { type: 'string' },
  },
  required: ['severity', 'confidence', 'file', 'title', 'fix'],
}
const DUE = {
  type: 'object',
  properties: { line: { type: 'string', description: 'review-due\'s one line, verbatim' }, initialized: { type: 'boolean' }, tool_calls: CALLS },
  required: ['line', 'initialized', 'tool_calls'],
}
const SECURITY = {
  type: 'object',
  properties: {
    ran: { type: 'boolean' }, head: { type: 'string' }, findings: { type: 'array', items: FINDING },
    not_reviewed: { type: 'array', items: { type: 'string' }, description: 'the files of the combined diff you did not review, empty when none' },
    tool_calls: CALLS,
  },
  required: ['ran', 'head', 'findings', 'not_reviewed', 'tool_calls'],
}
const QUALITY = {
  type: 'object',
  properties: {
    head: { type: 'string' }, blocking: { type: 'array', items: { type: 'string' } }, advisory: { type: 'array', items: { type: 'string' } },
    not_reviewed: { type: 'array', items: { type: 'string' } }, tool_calls: CALLS,
  },
  required: ['head', 'blocking', 'advisory', 'not_reviewed', 'tool_calls'],
}
const SKEPTIC = {
  type: 'object',
  properties: {
    head: { type: 'string' },
    kept_blocking: { type: 'integer', minimum: 0 }, kept_advisory: { type: 'integer', minimum: 0 }, dropped: { type: 'integer', minimum: 0 },
    security_recorded: { type: 'integer', minimum: 0 }, disputed: { type: 'integer', minimum: 0 }, missed: { type: 'integer', minimum: 0 },
    tool_calls: CALLS,
  },
  required: ['head', 'kept_blocking', 'kept_advisory', 'dropped', 'security_recorded', 'disputed', 'missed', 'tool_calls'],
}
const PLAN = {
  type: 'object',
  properties: {
    decisions: { type: 'array', items: { type: 'object', properties: { decision: { type: 'string' }, evidence: { type: 'string' } }, required: ['decision', 'evidence'] } },
    security_first: { type: 'array', items: { type: 'string' } }, paths: { type: 'array', items: { type: 'string' } }, tool_calls: CALLS,
  },
  required: ['decisions', 'security_first', 'paths', 'tool_calls'],
}
// Each start's fixed cap: the reviewers' the periodic review's
// PERIODIC_CAP, the planner's and the skeptic's under their maxTurns.
const CAPS = { due: 5, review: 53, skeptic: 35, plan: 30, record: 3 }
const capLine = (cap) => `\nTool calls: at most ${cap} in this start (a fixed cap). Count them; on reaching the cap, stop and return the schema with what is done, saying the cap stopped you.`
const isCommit = (head) => /^[0-9a-f]{7,40}$/.test(head || '')
const CHANGE = /^[a-z0-9][a-z0-9-]*$/
// review-due's due line, parsed into fixed words; anything else is not due.
// tools/tools_test.sh runs this helper.
function parseDue(line) {
  const m = /^due: (sprint-([0-9]+)) has [0-9]+ changes merged \(([a-z0-9, -]+)\); combined diff ([0-9a-f]{7,40})\.\.([A-Za-z0-9/_.-]+); sweep: (yes|no)$/.exec(line || '')
  if (!m) return null
  const names = m[3].split(', ')
  if (!names.every((n) => CHANGE.test(n))) return null
  return { sprint: m[1], number: Number(m[2]), names, base: m[4], tip: m[5], sweep: m[6] === 'yes' }
}

phase('Due')
const due = await agent(
  `Run \`sh tools/run_state.sh review-due\` with the Bash tool from the repository root and return its one line verbatim as line (exit 1 means not due, not a failure). Only when the line begins with \`due: sprint-N\`, run \`sh tools/run_state.sh init sprint-N main\`, and when it ends with \`sweep: yes\` also \`sh tools/run_state.sh init sprint-N-sweep main\`, N being its number; return initialized true when they exited 0.${capLine(CAPS.due)}`,
  { schema: DUE, effort: 'low', label: 'due' })
const sprint = due ? parseDue(due.line.split('\n')[0]) : null
if (!sprint || !due.initialized) return { due: false, report: `sprint-planning not due: ${due ? due.line.split('\n')[0] : 'no result'}` }

phase('Review')
const scope = `the combined diff \`git diff ${sprint.base} ${sprint.tip}\` of ${sprint.sprint}'s changes (${sprint.names.join(', ')})`
const reviewTask = `Change \`${sprint.sprint}\`. Mode: sprint. Review ${scope} as your Sprint mode section says; record nothing, the skeptic records; return the findings, listing in not_reviewed the files you did not cover.${capLine(CAPS.review)}`
const sweepName = `${sprint.sprint}-sweep`
const [security, quality, sweep] = await parallel([
  () => agent(reviewTask, { agentType: 'security-reviewer', schema: SECURITY, label: 'security-reviewer: sprint' }),
  () => agent(reviewTask, { agentType: 'quality-reviewer', schema: QUALITY, label: 'quality-reviewer: sprint' }),
  async () => {
    try {
      return sprint.sweep ? await workflow({ scriptPath: '.claude/workflows/periodic-review.js' }, { change: sweepName }) : null
    } catch (e) {
      log(`the sweep failed to start: ${e.message}`)
      return null
    }
  },
])
const ran = Boolean(security && security.ran && isCommit(security.head))
const blocking = ran ? security.findings.filter((f) => f.severity !== 'Low' && f.confidence >= 8) : []

phase('Skeptic')
const listed = (xs) => (xs.length ? xs.map((x) => `- ${x}`).join('\n') : '- none')
const securityLines = ran ? security.findings.map((f) => `${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`) : []
const skeptic = await agent(
  `Change \`${sprint.sprint}\`. Mode: skeptic. The reviewers of ${scope} found what follows. Read each against the code at origin/main as your Skeptic mode section says, record what you keep in this run state, and return the counts.\nSecurity findings (record every one; one you dispute as disputed with its reason):\n${listed(securityLines)}\nQuality blocking:\n${listed(quality ? quality.blocking : [])}\nQuality advisory:\n${listed(quality ? quality.advisory : [])}${capLine(CAPS.skeptic)}`,
  { agentType: 'quality-reviewer', schema: SKEPTIC, label: 'quality-reviewer: skeptic' })
const skeptical = Boolean(skeptic && isCommit(skeptic.head))
// The planner starts only after the security review and the skeptic, who
// records its findings: without both no plan and no marker are written, so
// review-due stays due and /sprint again reviews the sprint anew.
const reviewed = ran && skeptical

phase('Plan')
const plan = !reviewed ? null : await agent(
  `Mode: sprint. ${sprint.sprint} closed with ${sprint.names.join(', ')}. Plan sprint-${sprint.number + 1} as your Sprint mode section says, writing \`${sprint.sprint}\` into build/plan/sprint: the sprint review's findings are in the run state \`${sprint.sprint}\`${sprint.sweep ? ` and the sweep's in \`${sweepName}\`` : ''}, the duplicate candidates from \`sh tools/run_state.sh backlog-dups\`.${capLine(CAPS.plan)}`,
  { agentType: 'planner', schema: PLAN, label: 'planner: sprint' })

phase('Record')
// The review lines, of fixed words and counts, as periodic-review.js
// writes them; a partial security review outranks blocked.
const result = (blocked, missed) => (missed ? 'partial' : blocked ? 'blocked' : 'pass')
const lines = []
const record = (kind, word, summary, head) => lines.push(`sh tools/run_state.sh review ${sprint.sprint} ${kind} ${word} "${summary}"${head ? ` ${head}` : ''}`)
if (ran) {
  const count = (severity) => security.findings.filter((f) => f.severity === severity).length
  const missed = security.not_reviewed.length
  record('periodic-security', result(blocking.length, missed), `diff high=${count('High')} medium=${count('Medium')} low=${count('Low')} blocking=${blocking.length} disputed=${skeptical ? skeptic.disputed : 0} not_reviewed=${missed}`, security.head)
} else record('periodic-security', 'not-run', 'no result', '')
if (skeptical) record('periodic-quality', result(skeptic.kept_blocking, quality ? quality.not_reviewed.length : 1), `diff blocking=${skeptic.kept_blocking} advisory=${skeptic.kept_advisory} dropped=${skeptic.dropped} missed=${skeptic.missed}`, skeptic.head)
else record('periodic-quality', 'not-run', 'no skeptic result', '')
const starts = [['security', security], ['quality', quality], ['skeptic', skeptic], ['plan', plan]]
for (const [kind, r] of starts) {
  const cap = kind === 'skeptic' ? CAPS.skeptic : kind === 'plan' ? CAPS.plan : CAPS.review
  if (r && Number.isInteger(r.tool_calls) && r.tool_calls > cap) lines.push(`sh tools/run_state.sh note ${sprint.sprint} overrun "sprint ${kind} made ${r.tool_calls} tool calls in one start, over its cap of ${cap}"`)
}
const recorded = await agent(
  `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${lines.join(' && ')}\n\nReturn ok true when it exited 0, and its output.${capLine(CAPS.record)}`,
  { schema: { type: 'object', properties: { ok: { type: 'boolean' }, output: { type: 'string' } }, required: ['ok', 'output'] }, effort: 'low', label: 'record' })

const report = [
  `${sprint.sprint}: ${sprint.names.join(', ')}`,
  `Security: ${ran ? `${security.findings.length} finding(s), ${blocking.length} blocking${skeptical ? `, ${skeptic.disputed} disputed` : ''}` : 'did not run; run /sprint again'}`,
  `Quality: ${skeptical ? `${skeptic.kept_blocking} blocking and ${skeptic.kept_advisory} advisory kept, ${skeptic.dropped} dropped, ${skeptic.missed} missed by both` : 'the skeptic returned no result; nothing recorded'}`,
  `Sweep: ${sprint.sweep ? (sweep && sweep.ran ? `security ${sweep.security.length} finding(s), ${sweep.security_blocking} blocking; quality ${sweep.quality_blocking.length} blocking` : 'did not run; run /review') : 'not this sprint'}`,
  `Plan: ${plan ? `${plan.paths.join(', ') || 'no file'}; ${plan.decisions.map((d) => `${d.decision} (${d.evidence})`).join('; ')}` : reviewed ? 'the planner returned no result; run /sprint again' : 'not started, the sprint review did not complete; run /sprint again'}`,
  plan && plan.security_first.length ? `Security first: deliver ${plan.security_first.join('; ')} before the sprint` : '',
  recorded && recorded.ok ? '' : `The results were not recorded: ${recorded ? recorded.output : 'no result'}`,
].filter(Boolean).join('\n- ')
log(report)
return { due: true, sprint: sprint.sprint, ran, recorded: Boolean(recorded && recorded.ok), report: `- ${report}` }
