export const meta = {
  name: 'sprint-planning',
  description: 'Close a sprint of six merged changes (five before sprint-17): the security review of its combined diff, never skipped, the whole-tree sweep every second sprint, and the planner, which reviews the diff\'s quality and architecture, reads the security findings against the code, grooms the backlog, and writes the next sprint\'s queue of six, which the next delivery\'s package step applies with the sprint\'s row',
  whenToUse: '/sprint after a merge; it ends at once with "not due" until the sprint\'s six changes (five before sprint-17) have merged',
  phases: [
    { title: 'Due', detail: 'one start runs review-due; not due ends the run' },
    { title: 'Review', detail: 'the security reviewer over the combined diff in its sprint mode, once more over the files it left, and in an even sprint the whole-tree sweep, in parallel' },
    { title: 'Notes', detail: 'each security finding of the reviewer\'s result in the sprint\'s run state, before the planner' },
    { title: 'Plan', detail: 'the planner in its sprint mode: the quality review of the combined diff, once more by the quality reviewer over the files that start left, with the security findings read against the code, the backlog grooming with its one-time triage, and the next sprint\'s queue under build/plan/, its three backlog items from backlog-pick; the workflow records the quality findings it keeps, each security finding it disputes, as disputed, and each one the reviewer missed, each one single-quoted shell word' },
    { title: 'Record', detail: 'the review results, and the plan\'s security-first hold, in the sprint\'s run state; the next delivery\'s package step applies the plan with groom' },
  ],
}

// args: none. The sprint is the one tools/run_state.sh review-due counts
// (docs/sprints.tsv): due once its six changes (five before sprint-17) merged, not due while its
// plan waits in build/plan/ for the next delivery's package step, which
// applies it with tools/run_state.sh groom in that delivery's own pull
// request (planner-loop), unless a blocking sprint security finding or the
// plan's security first holds it. The security reviewer and the planner
// record nothing: this workflow records each security finding of the
// reviewer's result before the planner, so a capped planner loses none, and
// the planner returns the quality findings it keeps and the security
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
// The quality reviewer's continued start over the files the planner's review
// left: the planner's counts and notes over those files only.
const QUALITY = {
  type: 'object',
  properties: {
    head: { type: 'string', description: 'the tip your review read, from git rev-parse --short=12' },
    quality_blocking: { type: 'integer', minimum: 0 }, quality_advisory: { type: 'integer', minimum: 0 },
    not_reviewed: { type: 'array', items: { type: 'string' }, description: 'the files you were given and did not review, empty when none' },
    notes: {
      type: 'array', description: 'each quality finding you keep, the workflow records it',
      items: { type: 'object', properties: { kind: { type: 'string', enum: ['quality'] }, text: { type: 'string' } }, required: ['kind', 'text'] },
    },
    tool_calls: CALLS,
  },
  required: ['head', 'quality_blocking', 'quality_advisory', 'not_reviewed', 'notes', 'tool_calls'],
}
const PLAN = {
  type: 'object',
  properties: {
    decisions: { type: 'array', items: { type: 'object', properties: { decision: { type: 'string' }, evidence: { type: 'string' } }, required: ['decision', 'evidence'] } },
    security_first: { type: 'array', items: { type: 'string' } }, paths: { type: 'array', items: { type: 'string' } },
    head: { type: 'string', description: 'the tip your quality review read, from git rev-parse --short=12' },
    quality_blocking: { type: 'integer', minimum: 0 }, quality_advisory: { type: 'integer', minimum: 0 },
    not_reviewed: { type: 'array', items: { type: 'string' }, description: 'the files of the combined diff your quality review did not cover, empty when none' },
    disputed: { type: 'integer', minimum: 0 },
    security_missed: { type: 'array', items: FINDING, description: 'each security finding the security reviewer missed, empty when none; the workflow records them' },
    notes: {
      type: 'array',
      description: 'each note to record: a quality finding you keep (kind quality), a security finding you dispute ("disputed: REASON; FINDING", kind security); the workflow records them, a quality finding you drop is in none',
      items: { type: 'object', properties: { kind: { type: 'string', enum: ['quality', 'security'] }, text: { type: 'string' } }, required: ['kind', 'text'] },
    },
    tool_calls: CALLS,
  },
  required: ['decisions', 'security_first', 'paths', 'head', 'quality_blocking', 'quality_advisory', 'not_reviewed', 'disputed', 'security_missed', 'notes', 'tool_calls'],
}
// Each start's fixed cap: the security reviewer's the periodic review's
// PERIODIC_CAP, the planner's, which reviews quality too, under its maxTurns.
const CAPS = { due: 5, review: 53, plan: 80, record: 3 }
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
// The sprint security review gets one more start over the files its first start
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
// A finding blocks the sprint at High or Medium and confidence 8 or above.
function blockingOf(findings) {
  return findings.filter((f) => f.severity !== 'Low' && f.confidence >= 8)
}

// Each security finding as one note of the sprint's run state, the line
// the planner reads, run through Bash by the record start: every control
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
// The security findings the reviewer missed, which the planner returns in
// security_missed (sprint-close-lows): only findings of the reviewer's
// shape count, each recorded as a security note "missed by the reviewer:
// ..." and blocking by blockingOf, as the reviewer's own would.
function missedSecurity(plan) {
  const xs = plan && Array.isArray(plan.security_missed) ? plan.security_missed : []
  return xs.filter((f) => f && ['High', 'Medium', 'Low'].includes(f.severity) && Number.isInteger(f.confidence) && typeof f.file === 'string' && typeof f.title === 'string')
}
// The planner's notes (pipeline-lows-a): it records nothing itself, since
// a finding quoting reviewed code inside a double-quoted argument would
// let the shell expand it; each note of kind quality or security becomes
// one command whose text is one single-quoted shell word, any other kind
// or an empty text dropped.
function reviewNotes(change, notes) {
  return (Array.isArray(notes) ? notes : [])
    .filter((n) => n && (n.kind === 'quality' || n.kind === 'security') && String(n.text || '').trim())
    .map((n) => `sh tools/run_state.sh note ${change} ${n.kind} ${shellWord(n.text)}`)
}
// Whether the planner returned its quality review: a commit as head and
// its counts and lists in their shapes.
function qualityReviewed(plan) {
  return Boolean(plan && isCommit(plan.head) && Number.isInteger(plan.quality_blocking) && Number.isInteger(plan.quality_advisory) && Array.isArray(plan.not_reviewed))
}
// The planner's quality review gets one more start of the quality reviewer
// over the files it left (sprint-review-coverage), merged as the security
// review's is: counts added, notes joined, and not_reviewed what the
// second start still names (stillLeft), so a missing continuation leaves
// every file left and the review partial, never passed.
// tools/tools_test.sh runs these helpers.
function mergeQuality(first, again) {
  if (!qualityReviewed(again)) return first
  const more = Array.isArray(again.notes) ? again.notes : []
  return {
    head: first.head, quality_blocking: first.quality_blocking + again.quality_blocking, quality_advisory: first.quality_advisory + again.quality_advisory,
    not_reviewed: stillLeft(first.not_reviewed, again.not_reviewed), notes: (Array.isArray(first.notes) ? first.notes : []).concat(more),
  }
}
// The report's Quality line names the coverage: the files the first start
// left, how many the continued start reviewed, and those still left.
function qualityLine(q, firstLeft) {
  const kept = `the planner kept ${q.quality_blocking} blocking and ${q.quality_advisory} advisory`
  if (!firstLeft) return `${kept}; every file of the diff reviewed`
  const left = q.not_reviewed.length
  const names = q.not_reviewed.slice(0, 5).join(', ') + (left > 5 ? ', ...' : '')
  return `${kept}; coverage: ${firstLeft - left} of ${firstLeft} file(s) the first start left reviewed in a continued start${left ? `, ${left} still not reviewed (${names}); partial` : ''}`
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
// The report's whole Security line: securityLine, the findings the
// reviewer missed, and, when the review ran but its findings were not
// recorded, that suffix. tools/tools_test.sh runs this helper.
function securityReport(r, blocking, disputed, missedCount, noted) {
  return `Security: ${securityLine(r, blocking, disputed)}${missedCount ? `; ${missedCount} missed by the reviewer` : ''}${securityDone(r) && !noted ? '; its findings were not recorded' : ''}`
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

// The next queue waits while the sprint holds a blocking security finding,
// the reviewer's or one it missed, or the plan names security_first
// (sprint-close-lows): the reason, or '' when nothing holds it. groom holds
// the plan for the same reasons from the run state: the blocked review,
// and the hold security-first the record start sets before it.
// tools/tools_test.sh runs these helpers.
function queueHeld(blocking, securityFirst) {
  if (blocking) return `${blocking} blocking sprint security finding(s)`
  if (securityFirst.length) return `the plan's security first: ${securityFirst.join('; ')}`
  return ''
}
// The report's line for the next queue: no records run (planner-loop); the
// next delivery's package step carries the sprint's records.
function queueLine(held) {
  return held
    ? `held by ${held}; deliver the security fix first: the first delivery planned after it merged applies the plan in its package step (groom)`
    : 'the next delivery\'s package step applies the plan (groom), the sprint\'s records in its own pull request'
}

phase('Due')
// The bookkeeping starts (due, record) run as the runner agent, the
// cheapest tier at low effort, under its guard profile (cheap-tier). The
// notes and plan notes starts, whose texts quote reviewed code, run as the
// security reviewer in record mode, under the read profile, which records
// notes and no review or phase.
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
// The security reviewer, then one more start of it over what it left.
async function reviewContinued(kind, schema, done, merge) {
  const first = await agent(reviewTask, { agentType: `${kind}-reviewer`, schema, label: `${kind}-reviewer: sprint` })
  reviewStarts.push([kind, first])
  if (done(first) && !first.not_reviewed.length) return first
  const what = done(first) ? `the files ${first.not_reviewed.join(', ')} of ${scope}, which the last start over it left at its cap` : `${scope}; the last start over it returned no result`
  const again = await agent(reviewTaskOf(what, done(first) ? ' of these' : ''), { agentType: `${kind}-reviewer`, schema, label: `${kind}-reviewer: sprint, continued` })
  reviewStarts.push([`${kind} continued`, again])
  return merge(first, again)
}
const [security, sweep] = await parallel([
  () => reviewContinued('security', SECURITY, securityDone, mergeSecurity),
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

// A record start: the one command, run by the security reviewer in its
// record mode, whose hook runs tools/agent_guard.sh's read profile, which
// records notes and no review or phase: text quoting reviewed code that
// leads it astray runs no command but that profile's (cheap-tier security
// Medium). null when there is nothing to record.
async function recordNotes(lines, label) {
  if (!lines.length) return null
  return agent(
    `Mode: record. Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${lines.join(' && ')}\n\nReturn ok true when it exited 0, and its output.${capLine(CAPS.record)}`,
    { agentType: 'security-reviewer', schema: RAN, effort: 'low', label })
}

phase('Notes')
// Each security finding reaches the run state from the reviewer's own
// result, before the planner, so a planner stopped at its cap leaves none
// unrecorded; without them recorded the planner does not start.
const notes = ran ? securityNotes(sprint.sprint, security.findings) : []
const notesRun = await recordNotes(notes, 'sprint: notes')
const noted = !notes.length || Boolean(notesRun && notesRun.ok)
// The planner starts only after a complete security review (not partial)
// with its findings recorded and, in an even sprint, the sweep: without
// them no plan and no marker are written, which groom would only hold, so
// review-due stays due and /sprint again reviews the sprint anew.
const swept = !sprint.sweep || Boolean(sweep && sweep.ran && sweep.recorded)
const reviewed = ran && !missed && noted && swept

phase('Plan')
const listed = (xs) => (xs.length ? xs.map((x) => `- ${x}`).join('\n') : '- none')
const securityLines = ran ? security.findings.map(findingLine) : []
const plan = !reviewed ? null : await agent(
  `Mode: sprint. ${sprint.sprint} closed with ${sprint.names.join(', ')}. First review ${scope} for quality as your Sprint mode section says, and read each security finding below against the code at origin/main; record nothing: return each quality finding you keep and each security finding you dispute in notes, each security finding the reviewer missed in security_missed, and the counts, which the workflow records in the run state \`${sprint.sprint}\`.\nSecurity findings (each already recorded from the reviewer's result; return again only one you dispute, as disputed with its reason, never dropping one):\n${listed(securityLines)}\nThen plan sprint-${sprint.number + 1} as your Sprint mode section says, writing \`${sprint.sprint}\` into build/plan/sprint: the security findings are in the run state \`${sprint.sprint}\`${sprint.sweep ? ` and the sweep's in \`${sweepName}\`` : ''}, the quality findings are those you keep, the duplicate candidates from \`sh tools/run_state.sh backlog-dups\` (a near-same note merged, never dropped), the oldest entries to check against HEAD from \`sh tools/run_state.sh backlog-oldest docs/backlog docs/findings/*.md\`, the three backlog items from \`sh tools/run_state.sh backlog-pick docs/backlog docs/findings/*.md\` (its one caller with the real files), and the one-time backlog triage unless done.${capLine(CAPS.plan)}`,
  { agentType: 'planner', schema: PLAN, label: 'planner: sprint' })
const planned = qualityReviewed(plan)
// The planner's quality review, capped with files left, gets one more start
// of the quality reviewer over them, merged into one review (mergeQuality):
// a review that still leaves files is recorded partial below, never passed.
const firstLeft = planned ? plan.not_reviewed.length : 0
let quality = plan
if (firstLeft) {
  const again = await agent(reviewTaskOf(`the files ${plan.not_reviewed.join(', ')} of ${scope}, which the planner's quality review left at its cap`, ' of these'), { agentType: 'quality-reviewer', schema: QUALITY, label: 'quality-reviewer: sprint, continued' })
  reviewStarts.push(['quality continued', again])
  quality = mergeQuality(plan, again)
}
// The planner's notes and the security findings it found the reviewer
// missed reach the run state through a record start of the read profile;
// each text one single-quoted shell word (reviewNotes).
const missedReviewer = planned ? missedSecurity(plan) : []
const sprintBlocking = blocking.concat(blockingOf(missedReviewer))
const kept = planned ? reviewNotes(sprint.sprint, quality.notes).concat(securityNotes(sprint.sprint, missedReviewer, 'missed by the reviewer: ')) : []
const keptRun = await recordNotes(kept, 'sprint: plan notes')
const planNoted = !kept.length || Boolean(keptRun && keptRun.ok)

phase('Record')
// The review lines, of fixed words and counts, as periodic-review.js
// writes them; a partial security review outranks blocked. The plan's
// security first is set as the hold before the security review line, so
// no package step sees the plan reviewed and not held.
const result = (blocked, missed) => (missed ? 'partial' : blocked ? 'blocked' : 'pass')
const lines = []
if (plan && Array.isArray(plan.security_first) && plan.security_first.length) lines.push(`sh tools/run_state.sh set ${sprint.sprint} hold security-first`)
const record = (kind, word, summary, head) => lines.push(`sh tools/run_state.sh review ${sprint.sprint} ${kind} ${word} "${summary}"${head ? ` ${head}` : ''}`)
if (ran) {
  const count = (severity) => security.findings.concat(missedReviewer).filter((f) => f.severity === severity).length
  record('periodic-security', result(sprintBlocking.length, missed), `diff high=${count('High')} medium=${count('Medium')} low=${count('Low')} blocking=${sprintBlocking.length} disputed=${planned ? plan.disputed : 0} not_reviewed=${missed}`, security.head)
} else record('periodic-security', 'not-run', 'no result', '')
if (planned && planNoted) record('periodic-quality', result(quality.quality_blocking, quality.not_reviewed.length), `diff blocking=${quality.quality_blocking} advisory=${quality.quality_advisory} missed=${missedReviewer.length} not_reviewed=${quality.not_reviewed.length}`, plan.head)
else record('periodic-quality', 'not-run', planned ? 'the planner notes were not recorded' : 'no planner review', '')
// A sweep that failed to start leaves its run state without a record;
// this one says why, and holds the sprint as none does.
if (sprint.sweep && !sweep) lines.push(`sh tools/run_state.sh review ${sweepName} periodic-security not-run "the sweep failed to start"`)
const starts = [...reviewStarts, ['plan', plan]]
for (const [kind, r] of starts) {
  const cap = kind === 'plan' ? CAPS.plan : CAPS.review
  if (r && Number.isInteger(r.tool_calls) && r.tool_calls > cap) lines.push(`sh tools/run_state.sh note ${sprint.sprint} overrun "sprint ${kind} made ${r.tool_calls} tool calls in one start, over its cap of ${cap}"`)
}
const recorded = await agent(
  `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${lines.join(' && ')}\n\nReturn ok true when it exited 0, and its output.${capLine(CAPS.record)}`,
  { agentType: 'runner', schema: RAN, effort: 'low', label: 'sprint: record' })
const held = plan ? queueHeld(sprintBlocking.length, plan.security_first || []) : ''

const report = [
  `${sprint.sprint}: ${sprint.names.join(', ')}`,
  planned && !planNoted ? `The planner's notes were not recorded: ${keptRun ? keptRun.output : 'no result'}` : '',
  securityReport(security, sprintBlocking.length, planned ? plan.disputed : null, missedReviewer.length, noted),
  `Quality: ${planned ? qualityLine(quality, firstLeft) : 'the planner returned no review; nothing recorded'}`,
  `Sweep: ${sweepLine(sprint.sweep, sweep)}`,
  `Plan: ${plan ? `${plan.paths.join(', ') || 'no file'}; ${plan.decisions.map((d) => `${d.decision} (${d.evidence})`).join('; ')}` : reviewed ? 'the planner returned no result; run /sprint again' : 'not started, the sprint review did not complete; run /sprint again'}`,
  plan && plan.security_first.length ? `Security first: deliver ${plan.security_first.join('; ')} before the sprint` : '',
  recorded && recorded.ok ? '' : `The results were not recorded: ${recorded ? recorded.output : 'no result'}`,
  plan && recorded && recorded.ok ? `Next queue: ${queueLine(held)}` : '',
].filter(Boolean).join('\n- ')
log(report)
return { due: true, sprint: sprint.sprint, ran, recorded: Boolean(recorded && recorded.ok), report: `- ${report}` }
