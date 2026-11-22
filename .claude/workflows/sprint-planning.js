export const meta = {
  name: 'sprint-planning',
  description: 'Close a sprint of six merged changes (five before sprint-17): the review of its combined diff (security, never skipped, quality and architecture, and the skeptic), the whole-tree sweep every second sprint, the backlog grooming, and the next sprint\'s queue of six, which its records change, sprint-N-records, applies once with the sprint\'s row',
  whenToUse: '/sprint after a merge; it ends at once with "not due" until the sprint\'s six changes (five before sprint-17) have merged',
  phases: [
    { title: 'Due', detail: 'one start runs review-due; not due ends the run' },
    { title: 'Review', detail: 'the security and quality reviewers over the combined diff in their sprint mode, each once more over the files it left, and in an even sprint the whole-tree sweep, in parallel' },
    { title: 'Notes', detail: 'each security finding of the reviewer\'s result in the sprint\'s run state, before the skeptic' },
    { title: 'Skeptic', detail: 'the quality reviewer reads both results against the code and returns the quality findings it keeps, each security finding it disputes, as disputed, and each one both reviewers missed; the workflow records them, each one single-quoted shell word' },
    { title: 'Plan', detail: 'the planner in its sprint mode: the backlog grooming with its one-time triage, and the next sprint\'s queue under build/plan/, its three backlog items from backlog-pick' },
    { title: 'Record', detail: 'the review results in the sprint\'s run state' },
    { title: 'Records', detail: 'the sprint\'s records change, sprint-N-records, delivered through deliver-change.js unless a blocking security finding or the plan\'s security first holds it: history and groom write the backlog fold, the lane queues, and the sprints row once' },
  ],
}

// args: none. The sprint is the one tools/run_state.sh review-due counts
// (docs/sprints.tsv): due once its six changes (five before sprint-17) merged, not due while its
// plan waits in build/plan/ for its records change, sprint-N-records, which
// this workflow delivers last and which alone applies it with
// tools/run_state.sh groom, never a lane's package step. The diff reviewers
// record nothing: this workflow records each security finding of the
// reviewer's result before the skeptic, so a capped skeptic loses none, and
// the skeptic returns the quality findings it keeps and the security
// findings it disputes, as disputed, which this workflow records, so a
// quality finding it drops is never recorded. The sweep, the whole-tree periodic review, records in its own
// run state, <sprint>-sweep; one that failed to start is recorded there as
// not-run, which holds the sprint (groom and review-due).
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
    security_missed: { type: 'array', items: FINDING, description: 'each security finding both reviewers missed, empty when none; the workflow records them' },
    notes: {
      type: 'array',
      description: 'each note to record: a quality finding kept or missed by both (kind quality), a security finding disputed ("disputed: REASON; FINDING", kind security); the workflow records them',
      items: { type: 'object', properties: { kind: { type: 'string', enum: ['quality', 'security'] }, text: { type: 'string' } }, required: ['kind', 'text'] },
    },
    tool_calls: CALLS,
  },
  required: ['head', 'kept_blocking', 'kept_advisory', 'dropped', 'security_recorded', 'disputed', 'missed', 'security_missed', 'notes', 'tool_calls'],
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
const RAN = { type: 'object', properties: { ok: { type: 'boolean' }, output: { type: 'string' } }, required: ['ok', 'output'] }
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
// Each sprint review gets one more start over the files its first start
// left, or over the whole diff when the first returned no result, as the
// periodic review does; the two merge into one result whose not_reviewed
// is what the second left, so a diff larger than one start still closes.
// A file the second names left is matched to the first's list by its
// pathKey, quotes and blanks trimmed, a leading ./, doubled slashes, and a
// trailing slash or :line[:column] dropped, a prefix (a worktree or an
// absolute path) matched at a path boundary, the first's spelling kept: a
// file is never dropped for its spelling (sprint-close-lows), and one the
// first start reviewed by its own account stays dropped.
// tools/tools_test.sh runs these helpers.
function securityDone(r) {
  return Boolean(r && r.ran && isCommit(r.head) && Array.isArray(r.findings) && Array.isArray(r.not_reviewed))
}
function qualityDone(r) {
  return Boolean(r && isCommit(r.head) && Array.isArray(r.blocking) && Array.isArray(r.advisory) && Array.isArray(r.not_reviewed))
}
function pathKey(p) {
  return String(p).trim().replace(/^[`'"]+|[`'"]+$/g, '').replace(/:[0-9]+(:[0-9]+)?$/, '').replace(/\/{2,}/g, '/').replace(/^(\.\/)+/, '').replace(/\/$/, '')
}
function stillLeft(first, again) {
  const keys = again.map(pathKey).filter(Boolean)
  return first.filter((f) => {
    const k = pathKey(f)
    return Boolean(k) && keys.some((a) => a === k || a.endsWith(`/${k}`) || k.endsWith(`/${a}`))
  })
}
function mergeSecurity(first, again) {
  if (!securityDone(again)) return securityDone(first) ? first : null
  if (!securityDone(first)) return again
  return { ran: true, head: first.head, findings: first.findings.concat(again.findings), not_reviewed: stillLeft(first.not_reviewed, again.not_reviewed), tool_calls: first.tool_calls }
}
function mergeQuality(first, again) {
  if (!qualityDone(again)) return qualityDone(first) ? first : null
  if (!qualityDone(first)) return again
  return { head: first.head, blocking: first.blocking.concat(again.blocking), advisory: first.advisory.concat(again.advisory), not_reviewed: stillLeft(first.not_reviewed, again.not_reviewed), tool_calls: first.tool_calls }
}
// A finding blocks the sprint at High or Medium and confidence 8 or above.
function blockingOf(findings) {
  return findings.filter((f) => f.severity !== 'Low' && f.confidence >= 8)
}

// Each security finding as one note of the sprint's run state, the line
// the skeptic reads, run through Bash by the record start: every control
// character a space and the text one single-quoted shell word, so no
// finding text the reviewer returned is read by the shell.
// tools/tools_test.sh runs these helpers.
function shellWord(s) {
  return `'${String(s).replace(/[\x00-\x1f\x7f]+/g, ' ').replace(/'/g, "'\\''")}'`
}
function findingLine(f) {
  return `${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`
}
function securityNotes(change, findings, prefix = '') {
  return findings.map((f) => `sh tools/run_state.sh note ${change} security ${shellWord(prefix + findingLine(f))}`)
}
// The security findings both reviewers missed, which the skeptic returns
// in security_missed (sprint-close-lows): only findings of the reviewer's
// shape count, each recorded as a security note "missed by both: ..." and
// blocking by blockingOf, as the reviewer's own would.
function missedSecurity(skeptic) {
  const xs = skeptic && Array.isArray(skeptic.security_missed) ? skeptic.security_missed : []
  return xs.filter((f) => f && ['High', 'Medium', 'Low'].includes(f.severity) && Number.isInteger(f.confidence) && typeof f.file === 'string' && typeof f.title === 'string')
}
// The skeptic's notes (pipeline-lows-a): it records nothing itself, since
// a finding quoting reviewed code inside a double-quoted argument would
// let the shell expand it; each note of kind quality or security becomes
// one command whose text is one single-quoted shell word, any other kind
// or an empty text dropped.
function skepticNotes(change, notes) {
  return (Array.isArray(notes) ? notes : [])
    .filter((n) => n && (n.kind === 'quality' || n.kind === 'security') && String(n.text || '').trim())
    .map((n) => `sh tools/run_state.sh note ${change} ${n.kind} ${shellWord(n.text)}`)
}
// The report's Security line: a partial review names the files it left
// and asks for /sprint again, as one that did not run does.
// tools/tools_test.sh runs this helper.
function securityLine(r, blocking, disputed) {
  if (!securityDone(r)) return 'did not run; run /sprint again'
  const counts = `${r.findings.length} finding(s), ${blocking} blocking${disputed === null ? '' : `, ${disputed} disputed`}`
  if (!r.not_reviewed.length) return counts
  const left = r.not_reviewed.slice(0, 5).join(', ') + (r.not_reviewed.length > 5 ? ', ...' : '')
  return `partial, ${r.not_reviewed.length} file(s) not reviewed (${left}); ${counts}; run /sprint again`
}
// The report's whole Security line: securityLine, the findings both
// reviewers missed, and, when the review ran but its findings were not
// recorded, that suffix. tools/tools_test.sh runs this helper.
function securityReport(r, blocking, disputed, bothMissed, noted) {
  return `Security: ${securityLine(r, blocking, disputed)}${bothMissed ? `; ${bothMissed} missed by both reviewers` : ''}${securityDone(r) && !noted ? '; its findings were not recorded' : ''}`
}
// The report's sweep line from periodic-review.js's result: its counts,
// the security and quality areas a partial sweep left, and whether its
// results were recorded, without which the planner does not start.
function sweepLine(on, r) {
  if (!on) return 'not this sprint'
  if (!r || !r.ran) return 'did not run; run /sprint again'
  const counts = `security ${r.security.length} finding(s), ${r.security_blocking} blocking; quality ${r.quality_blocking.length} blocking`
  const left = [
    r.security_not_reviewed.length ? `security partial, not reviewed: ${r.security_not_reviewed.join(', ')}` : '',
    r.quality_not_reviewed.length ? `quality partial, areas not reviewed: ${r.quality_not_reviewed.join(', ')}` : '',
  ].filter(Boolean)
  const unrecorded = r.recorded ? [] : ['its results were not recorded; run /sprint again']
  return [counts].concat(left, unrecorded).join('; ')
}

// The sprint's records change: a delivery of its own, started through
// deliver-change.js as the sweep starts periodic-review.js, whose
// contributor runs history (every lane's rows) and groom in its implement
// step, so the backlog fold, the sprint's lane queues, and its sprints row
// are written once and pass the checker, the reviews, and the merge gates.
// Every start of this workflow's own carries a label beginning "sprint:" or
// naming a sprint, skeptic, or periodic review, so tools/run_state.sh tokens
// keys it sprint and the records change's budget counts only its own work.
// tools/tools_test.sh runs this helper.
function recordsRun(sprint) {
  const change = `${sprint.sprint}-records`
  return {
    change, branch: `chore/${change}`,
    brief: `${change}: apply the plan of ${sprint.sprint} waiting in build/plan/, sprint-planning's records change (T0 records, estimated small). In your implement step run \`sh tools/run_state.sh history ${change}\`, which appends every lane's pending rows, then \`sh tools/run_state.sh groom ${change}\`, which files each findings entry into the backlog file of its first named path under docs/backlog/, copies the sprint's two lane queues, and appends the sprint's row to docs/sprints.tsv; commit them with this change's OpenSpec change (skip_specs: true), no code and no other file. When groom applies nothing (the plan waits or stands applied), stop and say so.`,
  }
}

// The records change applies the next queue, so it waits while the sprint
// holds a blocking security finding, the reviewer's or one both missed,
// or the plan names security_first (sprint-close-lows): the reason, or ''
// when nothing holds it. tools/tools_test.sh runs this helper.
function recordsHeld(blocking, securityFirst) {
  if (blocking) return `${blocking} blocking sprint security finding(s)`
  if (securityFirst.length) return `the plan's security first: ${securityFirst.join('; ')}`
  return ''
}

// The report's line for the records change: deliver-change.js returns a
// report whether or not it merged, so only the merged commit its run state
// records counts as finished; anything else gets the resume hint
// .claude/commands/sprint.md acts on. tools/tools_test.sh runs this helper.
function recordsLine(name, merged, delivered) {
  if (!isCommit(merged)) return `${name} did not finish; resume it with /deliver ${name}`
  return `${name}: merged as ${merged}${delivered ? `; ${String(delivered).split('\n')[0]}` : ''}`
}

phase('Due')
// The bookkeeping starts (due, notes, skeptic notes, record, records-merged)
// run as the runner agent, the cheapest tier at low effort, under its guard
// profile (cheap-tier).
const due = await agent(
  `Run \`sh tools/run_state.sh review-due\` with the Bash tool from the repository root and return its one line verbatim as line (exit 1 means not due, not a failure). Only when the line begins with \`due: sprint-N\`, run \`sh tools/run_state.sh init sprint-N main\`, and when it ends with \`sweep: yes\` also \`sh tools/run_state.sh init sprint-N-sweep main\`, N being its number; return initialized true when they exited 0.${capLine(CAPS.due)}`,
  { agentType: 'runner', schema: DUE, effort: 'low', label: 'sprint: due' })
const sprint = due ? parseDue(due.line.split('\n')[0]) : null
if (!sprint || !due.initialized) return { due: false, report: `sprint-planning not due: ${due ? due.line.split('\n')[0] : 'no result'}` }

phase('Review')
const scope = `the combined diff \`git diff ${sprint.base} ${sprint.tip}\` of ${sprint.sprint}'s changes (${sprint.names.join(', ')})`
const reviewTaskOf = (what, these) => `Change \`${sprint.sprint}\`. Mode: sprint. Review ${what} as your Sprint mode section says; record nothing, the workflow records; return the findings, listing in not_reviewed the files${these} you did not cover.${capLine(CAPS.review)}`
const reviewTask = reviewTaskOf(scope, '')
const sweepName = `${sprint.sprint}-sweep`
const reviewStarts = []
// Either diff reviewer, then one more start of it over what it left.
async function reviewContinued(kind, schema, done, merge) {
  const first = await agent(reviewTask, { agentType: `${kind}-reviewer`, schema, label: `${kind}-reviewer: sprint` })
  reviewStarts.push([kind, first])
  if (done(first) && !first.not_reviewed.length) return first
  const what = done(first) ? `the files ${first.not_reviewed.join(', ')} of ${scope}, which the last start over it left at its cap` : `${scope}; the last start over it returned no result`
  const again = await agent(reviewTaskOf(what, done(first) ? ' of these' : ''), { agentType: `${kind}-reviewer`, schema, label: `${kind}-reviewer: sprint, continued` })
  reviewStarts.push([`${kind} continued`, again])
  return merge(first, again)
}
const [security, quality, sweep] = await parallel([
  () => reviewContinued('security', SECURITY, securityDone, mergeSecurity),
  () => reviewContinued('quality', QUALITY, qualityDone, mergeQuality),
  async () => {
    try {
      return sprint.sweep ? await workflow({ scriptPath: '.claude/workflows/periodic-review.js' }, { change: sweepName }) : null
    } catch (e) {
      log(`the sweep failed to start: ${e.message}`)
      return null
    }
  },
])
const ran = securityDone(security)
const blocking = ran ? blockingOf(security.findings) : []
const missed = ran ? security.not_reviewed.length : 0

phase('Notes')
// Each security finding reaches the run state from the reviewer's own
// result, before the skeptic, so a skeptic stopped at its cap leaves none
// unrecorded; without them recorded the planner does not start. The
// texts quote reviewed code, so the start is the runner agent, whose hook
// runs tools/agent_guard.sh's runner profile, as
// for the skeptic's notes below.
const notes = ran ? securityNotes(sprint.sprint, security.findings) : []
const notesRun = !notes.length ? null : await agent(
  `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${notes.join(' && ')}\n\nReturn ok true when it exited 0, and its output.${capLine(CAPS.record)}`,
  { agentType: 'runner', schema: RAN, effort: 'low', label: 'sprint: notes' })
const noted = !notes.length || Boolean(notesRun && notesRun.ok)

phase('Skeptic')
const listed = (xs) => (xs.length ? xs.map((x) => `- ${x}`).join('\n') : '- none')
const securityLines = ran ? security.findings.map(findingLine) : []
const skeptic = await agent(
  `Change \`${sprint.sprint}\`. Mode: skeptic. The reviewers of ${scope} found what follows. Read each against the code at origin/main as your Skeptic mode section says; record nothing: return each note you keep in notes, which the workflow records in this run state, and the counts.\nSecurity findings (each already recorded from the reviewer's result; return again only one you dispute, as disputed with its reason, never dropping one, and each security finding both reviewers missed in security_missed):\n${listed(securityLines)}\nQuality blocking:\n${listed(quality ? quality.blocking : [])}\nQuality advisory:\n${listed(quality ? quality.advisory : [])}${capLine(CAPS.skeptic)}`,
  { agentType: 'quality-reviewer', schema: SKEPTIC, label: 'quality-reviewer: skeptic' })
const skeptical = Boolean(skeptic && isCommit(skeptic.head))
// The skeptic's notes reach the run state before the planner, which reads
// them there; each text one single-quoted shell word (skepticNotes). The
// texts quote reviewed code, so the start is the runner agent, whose hook
// runs tools/agent_guard.sh's runner profile: text
// that leads it astray runs no command but that profile's.
const missedBoth = skeptical ? missedSecurity(skeptic) : []
const sprintBlocking = blocking.concat(blockingOf(missedBoth))
const kept = skeptical ? skepticNotes(sprint.sprint, skeptic.notes).concat(securityNotes(sprint.sprint, missedBoth, 'missed by both: ')) : []
const keptRun = !kept.length ? null : await agent(
  `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${kept.join(' && ')}\n\nReturn ok true when it exited 0, and its output.${capLine(CAPS.record)}`,
  { agentType: 'runner', schema: RAN, effort: 'low', label: 'sprint: skeptic notes' })
const skepticNoted = !kept.length || Boolean(keptRun && keptRun.ok)
// The planner starts only after a complete security review (not partial)
// with its findings recorded, the skeptic with its notes recorded, and in an even sprint the
// sweep: without them no plan and no marker are written, which groom
// would only hold, so review-due stays due and /sprint again reviews the
// sprint anew.
const swept = !sprint.sweep || Boolean(sweep && sweep.ran && sweep.recorded)
const reviewed = ran && !missed && noted && skeptical && skepticNoted && swept

phase('Plan')
const plan = !reviewed ? null : await agent(
  `Mode: sprint. ${sprint.sprint} closed with ${sprint.names.join(', ')}. Plan sprint-${sprint.number + 1} as your Sprint mode section says, writing \`${sprint.sprint}\` into build/plan/sprint: the sprint review's findings are in the run state \`${sprint.sprint}\`${sprint.sweep ? ` and the sweep's in \`${sweepName}\`` : ''}, the duplicate candidates from \`sh tools/run_state.sh backlog-dups\` (a near-same note merged, never dropped), the oldest entries to check against HEAD from \`sh tools/run_state.sh backlog-oldest docs/backlog docs/findings/*.md\`, the three backlog items from \`sh tools/run_state.sh backlog-pick docs/backlog docs/findings/*.md\` (its one caller with the real files), and the one-time backlog triage unless done.${capLine(CAPS.plan)}`,
  { agentType: 'planner', schema: PLAN, label: 'planner: sprint' })

phase('Record')
// The review lines, of fixed words and counts, as periodic-review.js
// writes them; a partial security review outranks blocked.
const result = (blocked, missed) => (missed ? 'partial' : blocked ? 'blocked' : 'pass')
const lines = []
const record = (kind, word, summary, head) => lines.push(`sh tools/run_state.sh review ${sprint.sprint} ${kind} ${word} "${summary}"${head ? ` ${head}` : ''}`)
if (ran) {
  const count = (severity) => security.findings.concat(missedBoth).filter((f) => f.severity === severity).length
  record('periodic-security', result(sprintBlocking.length, missed), `diff high=${count('High')} medium=${count('Medium')} low=${count('Low')} blocking=${sprintBlocking.length} disputed=${skeptical ? skeptic.disputed : 0} not_reviewed=${missed}`, security.head)
} else record('periodic-security', 'not-run', 'no result', '')
if (skeptical) record('periodic-quality', result(skeptic.kept_blocking, quality ? quality.not_reviewed.length : 1), `diff blocking=${skeptic.kept_blocking} advisory=${skeptic.kept_advisory} dropped=${skeptic.dropped} missed=${skeptic.missed}`, skeptic.head)
else record('periodic-quality', 'not-run', 'no skeptic result', '')
// A sweep that failed to start leaves its run state without a record;
// this one says why, and holds the sprint as none does.
if (sprint.sweep && !sweep) lines.push(`sh tools/run_state.sh review ${sweepName} periodic-security not-run "the sweep failed to start"`)
const starts = [...reviewStarts, ['skeptic', skeptic], ['plan', plan]]
for (const [kind, r] of starts) {
  const cap = kind === 'skeptic' ? CAPS.skeptic : kind === 'plan' ? CAPS.plan : CAPS.review
  if (r && Number.isInteger(r.tool_calls) && r.tool_calls > cap) lines.push(`sh tools/run_state.sh note ${sprint.sprint} overrun "sprint ${kind} made ${r.tool_calls} tool calls in one start, over its cap of ${cap}"`)
}
const recorded = await agent(
  `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${lines.join(' && ')}\n\nReturn ok true when it exited 0, and its output.${capLine(CAPS.record)}`,
  { agentType: 'runner', schema: RAN, effort: 'low', label: 'sprint: record' })

phase('Records')
// Only a plan written after a complete review, with the results recorded,
// gets its records change; otherwise the plan does not exist or waits for
// /sprint again. A blocking security finding or the plan's security first
// holds it: the plan waits for /deliver once the fix merged.
let delivered = null
let merged = ''
const recordsName = recordsRun(sprint).change
const held = plan ? recordsHeld(sprintBlocking.length, plan.security_first) : ''
if (plan && recorded && recorded.ok && !held) {
  try {
    delivered = await workflow({ scriptPath: '.claude/workflows/deliver-change.js' }, recordsRun(sprint))
  } catch (e) {
    log(`the records change failed to start: ${e.message}`)
  }
  // Whether it merged is read from its run state, never from its report.
  const read = await agent(
    `Run \`sh tools/run_state.sh get ${recordsName} merged\` with the Bash tool from the repository root, exactly as written, and nothing else. Return its output, trimmed, as merged (empty when it printed nothing or failed).${capLine(CAPS.record)}`,
    { agentType: 'runner', schema: { type: 'object', properties: { merged: { type: 'string' } }, required: ['merged'] }, effort: 'low', label: 'sprint: records-merged' })
  merged = read ? read.merged.trim() : ''
}

const report = [
  `${sprint.sprint}: ${sprint.names.join(', ')}`,
  skeptical && !skepticNoted ? `The skeptic's notes were not recorded: ${keptRun ? keptRun.output : 'no result'}` : '',
  securityReport(security, sprintBlocking.length, skeptical ? skeptic.disputed : null, missedBoth.length, noted),
  `Quality: ${skeptical ? `${skeptic.kept_blocking} blocking and ${skeptic.kept_advisory} advisory kept, ${skeptic.dropped} dropped, ${skeptic.missed} missed by both` : 'the skeptic returned no result; nothing recorded'}`,
  `Sweep: ${sweepLine(sprint.sweep, sweep)}`,
  `Plan: ${plan ? `${plan.paths.join(', ') || 'no file'}; ${plan.decisions.map((d) => `${d.decision} (${d.evidence})`).join('; ')}` : reviewed ? 'the planner returned no result; run /sprint again' : 'not started, the sprint review did not complete; run /sprint again'}`,
  plan && plan.security_first.length ? `Security first: deliver ${plan.security_first.join('; ')} before the sprint` : '',
  recorded && recorded.ok ? '' : `The results were not recorded: ${recorded ? recorded.output : 'no result'}`,
  plan && recorded && recorded.ok ? `Records: ${held ? `${recordsName} held by ${held}; deliver the security fix first, then resume it with /deliver ${recordsName}` : recordsLine(recordsName, merged, delivered)}` : '',
].filter(Boolean).join('\n- ')
log(report)
return { due: true, sprint: sprint.sprint, ran, recorded: Boolean(recorded && recorded.ok), report: `- ${report}` }
