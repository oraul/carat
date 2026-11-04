export const meta = {
  name: 'deliver-change',
  description: 'Deliver one change to main through fixed phases: plan, scouts, contributor, checker, quality and security review, benchmark, package, CI and merge, retrospective, periodic review, report',
  whenToUse: 'Every change to this repository, started by /deliver with a change name or a brief; it resumes from build/pipeline/CHANGE.json',
  phases: [
    { title: 'Resume', detail: 'branch, toolchain, and the run state' },
    { title: 'Plan', detail: 'planner: the next queue from the metrics history; security findings first' },
    { title: 'Scout', detail: 'one scout per edited map area without a current pack, at most three' },
    { title: 'Implement', detail: 'contributor: propose and apply, committing early' },
    { title: 'Check', detail: 'checker: the canonical stages through make' },
    { title: 'Quality', detail: 'quality reviewer: code-review and the repository rules, beside security on the same commit' },
    { title: 'Security', detail: 'security reviewer on the committed diff, beside quality; never skipped' },
    { title: 'Benchmark', detail: 'allocations and rounds against the figures recorded for main; the agent against main only when they differ' },
    { title: 'Package', detail: 'contributor: archive, gates, one push, pull request' },
    { title: 'Merge', detail: 'merger: wait for CI, red back to the contributor; main\'s merge gates, squash with the trailer, verify main' },
    { title: 'Retrospective', detail: 'retrospective: record the metrics, propose simplifications, decide whether a review is due' },
    { title: 'Review', detail: 'periodic review of the whole codebase: security, never skipped, and quality' },
    { title: 'Report', detail: 'reporter: the fixed report shape' },
  ],
}

// args: { change?, brief?, branch?, packs?: [path], areas?: [string] }, or a
// string that is a change name or a brief. The run state, written only by
// tools/run_state.sh and read through its trusted command (only the records
// at a commit of the branch or of main), decides which phases are already
// done: a phase whose recorded commit is the current one is skipped, so a
// restart resumes and a fix (a new commit) runs every later phase again. The workflow also
// measures the run (output tokens and tool calls per phase, the first
// verdict of each gate, rework rounds, CI minutes, the plan's estimate) and
// stores every figure as metric.* in one metric line (metricLine), so a
// restart seeds them and tools/run_state.sh history builds a whole row;
// the total tokens and wall minutes of each start, which only the session
// that ran the workflow sees, /deliver adds with tools/run_state.sh usage. The
// run state's phase.* and review.* lines and the figures are the script's
// own: it builds each command from a schema-checked result. One agent that
// reads nothing else runs the queued phase and review lines with the
// metric line (flush), twice a run: at the end of verify(), since the
// pre-push gates read the reviews, and at the end, where the package, CI,
// and merge phases wait (a resume reads pushed, pr, and merged instead).
// Between them the checker, the merger, and the retrospective run the
// metric line first, so a fix round is counted before its check.
// tools/agent_guard.sh keeps the other agents off the phase and review
// commands, and the merger's records gate compares the file with what the
// script received.
const input = typeof args === 'string' ? { brief: args } : (args || {})
const ROUNDS = 3
// Map areas scouted per change, and merger calls that may find CI still
// running (each waits up to 30 minutes) before the run stops as stalled.
const MAX_AREAS = 3
const WAITS = 4
const notes = []
let head = ''
let state = {}
let stopped = ''
const usage = {}
const firstPass = {}
let rework = 0
// The fix rounds are counted across starts (rework, from the run state):
// seededRework is what earlier starts spent, extra the rounds granted beyond
// ROUNDS, lastStop the stop word the last start stored (rounds when it
// stopped at the limit), stopKind this start's, and planned 0 when the
// planner was skipped.
let seededRework = 0
let extra = 0
let extraNow = false
let lastStop = ''
let stopKind = 'none'
let planned = null
let ciMinutes = null
const SIZES = ['small', 'medium', 'large']
let estimate = ''

const STATUS = { type: 'string', enum: ['done', 'stopped'] }
const HEAD = { type: 'string', description: 'git rev-parse --short=12 HEAD at the end' }
const LINES = { type: 'array', items: { type: 'string' } }
const RESUME = {
  type: 'object',
  properties: {
    status: STATUS, change: { type: 'string' }, branch: { type: 'string' }, head: HEAD,
    state_json: { type: 'string', description: 'the output of tools/run_state.sh trusted, verbatim' },
    plan: { type: 'string', description: 'the output of tools/run_state.sh plan-needed, verbatim: its first line, then its item: line when it printed one' },
    reason: { type: 'string' },
  },
  required: ['status', 'change', 'branch', 'head', 'state_json'],
}
const SCOUT_PLAN = {
  type: 'object',
  properties: {
    current: LINES,
    needed: { type: 'array', items: { type: 'object', properties: { area: { type: 'string' }, question: { type: 'string' } }, required: ['area', 'question'] } },
  },
  required: ['current', 'needed'],
}
const PACK = { type: 'object', properties: { pack: { type: 'string' } }, required: ['pack'] }
const WORK = {
  type: 'object',
  properties: { status: STATUS, head: HEAD, summary: { type: 'string' }, question: { type: 'string' }, assumptions: LINES, pr: { type: 'integer' } },
  required: ['status', 'head', 'summary'],
}
const CHECK = {
  type: 'object',
  properties: {
    passed: { type: 'boolean' }, head: HEAD, stages: LINES, failed_stage: { type: 'string' }, log_excerpt: { type: 'string' },
    bench_same: { type: 'boolean', description: 'tools/run_state.sh bench exited 0' }, bench_report: LINES,
  },
  required: ['passed', 'head', 'stages'],
}
const FINDING = {
  type: 'object',
  properties: {
    severity: { type: 'string', enum: ['High', 'Medium', 'Low'] }, confidence: { type: 'integer', minimum: 1, maximum: 10 },
    file: { type: 'string' }, line: { type: 'integer' }, in_change: { type: 'boolean' }, title: { type: 'string' }, fix: { type: 'string' },
  },
  required: ['severity', 'confidence', 'file', 'in_change', 'title', 'fix'],
}
const QUALITY = {
  type: 'object',
  properties: { head: HEAD, blocking: LINES, advisory: LINES },
  required: ['head', 'blocking', 'advisory'],
}
const SECURITY = {
  type: 'object',
  properties: { ran: { type: 'boolean' }, head: HEAD, findings: { type: 'array', items: FINDING } },
  required: ['ran', 'head', 'findings'],
}
const BENCH = {
  type: 'object',
  properties: { head: HEAD, blocking: LINES, report: LINES },
  required: ['head', 'blocking', 'report'],
}
const MERGE = {
  type: 'object',
  properties: {
    ci: { type: 'string', enum: ['green', 'red', 'pending', 'stale'] }, head: HEAD, minutes: { type: 'number' },
    waited: { type: 'number', description: 'minutes waited for CI in all' },
    step: { type: 'string' }, log_excerpt: { type: 'string' }, checks: { ...LINES, description: 'each check: name, status, conclusion' },
    merged: { type: 'boolean' }, sha: { type: 'string' }, subject: { type: 'string' }, branch_deleted: { type: 'boolean' }, problem: { type: 'string' },
  },
  required: ['ci', 'head', 'merged'],
}
const REPORT = { type: 'object', properties: { report: { type: 'string' } }, required: ['report'] }
const RECORDED = { type: 'object', properties: { ok: { type: 'boolean' }, output: { type: 'string' } }, required: ['ok', 'output'] }
const PLAN = {
  type: 'object',
  properties: {
    decisions: { type: 'array', items: { type: 'object', properties: { decision: { type: 'string' }, evidence: { type: 'string' } }, required: ['decision', 'evidence'] } },
    security_first: { ...LINES, description: 'unresolved blocking security findings the brief does not fix' },
    notes: { ...LINES, description: 'for the contributor: findings the change only records in docs/backlog.md, and bookkeeping' },
    files: LINES,
    estimate: { type: 'string', enum: SIZES, description: 'the size this change is estimated at' },
  },
  required: ['decisions', 'security_first', 'notes', 'files', 'estimate'],
}
const RETRO = {
  type: 'object',
  properties: {
    proposals: { type: 'array', items: { type: 'object', properties: { proposal: { type: 'string' }, evidence: { type: 'string' } }, required: ['proposal', 'evidence'] } },
    review_due: { type: 'string', description: 'the line tools/run_state.sh review-due printed' },
    due: { type: 'boolean' },
  },
  required: ['proposals', 'review_due', 'due'],
}
const CALLS = { type: 'integer', description: 'how many tool calls you made for this task' }
const withCalls = (schema) => ({ ...schema, properties: { ...schema.properties, tool_calls: CALLS }, required: [...schema.required, 'tool_calls'] })

// The output tokens the runtime has counted so far; the main session is idle
// while the workflow runs, so a difference is what the phase spent.
const spent = () => (typeof budget !== 'undefined' && budget && budget.spent ? budget.spent() : 0)
// Runs fn (agent calls) and adds its output tokens and reported tool calls
// to the phase key.
async function measured(key, fn) {
  const before = spent()
  const result = await fn()
  const u = usage[key] || (usage[key] = { tokens: 0, calls: 0 })
  u.tokens += spent() - before
  for (const r of [].concat(result)) if (r && Number.isInteger(r.tool_calls)) u.calls += r.tool_calls
  return result
}
function verdict(gate, passed) {
  if (!(gate in firstPass)) firstPass[gate] = passed ? 1 : 0
}
// Every figure of the run as one tools/run_state.sh metric line, built from
// what the script holds now, so the run state equals summary() once the
// line has run: fixed names and numbers or size words only, safe for the
// shell and for tools/run_state.sh metric. Empty without a change name.
function metricLine() {
  const pairs = Object.keys(usage).map((k) => `phase.${k}=${Math.round(usage[k].tokens)}/${usage[k].calls}`)
    .concat(Object.keys(firstPass).map((g) => `first.${g}=${firstPass[g]}`), [`rework=${rework}`, `extra=${extra}`, `stop=${stopKind}`])
  if (ciMinutes !== null) pairs.push(`ci_min=${Number(ciMinutes).toFixed(1)}`)
  if (SIZES.includes(estimate)) pairs.push(`estimate=${estimate}`)
  if (planned !== null) pairs.push(`planned=${planned}`)
  const safe = pairs.filter((p) => /^[a-z0-9_.-]+=([0-9./]+|small|medium|large|none|rounds)$/.test(p))
  return CHANGE.test(state.change || '') ? `sh tools/run_state.sh metric ${state.change} ${safe.join(' ')}` : ''
}
// A restart carries on the figures the run state holds.
function seed() {
  for (const key of Object.keys(state)) {
    let m = /^metric\.phase\.([a-z0-9_-]+)$/.exec(key)
    if (m) {
      const [tokens, calls] = String(state[key]).split('/').map(Number)
      usage[m[1]] = { tokens: tokens || 0, calls: calls || 0 }
    }
    m = /^metric\.first\.([a-z]+)$/.exec(key)
    if (m) firstPass[m[1]] = Number(state[key]) ? 1 : 0
  }
  rework = Number(state['metric.rework']) || 0
  seededRework = rework
  extra = Number(state['metric.extra']) || 0
  lastStop = /^[a-z]+$/.test(state['metric.stop'] || '') ? state['metric.stop'] : ''
  if (/^[01]$/.test(state['metric.planned'] || '')) planned = Number(state['metric.planned'])
  if (state['metric.ci_min']) ciMinutes = Number(state['metric.ci_min'])
  if (SIZES.includes(state['metric.estimate'])) estimate = state['metric.estimate']
  // The notes in the order they were recorded. The advisories of every
  // quality review of the run, which its reviewers recorded as
  // quality-advisory notes at each commit; once pushed, the package step
  // has handed them over.
  const noted = Object.keys(state).filter((k) => /^note\.[0-9]+$/.test(k))
    .sort((a, b) => Number(a.slice(5)) - Number(b.slice(5))).map((k) => String(state[k]))
  for (const v of noted) {
    const m = /^quality-advisory [0-9a-f]{7,40} (.+)$/.exec(v)
    if (m) addAdvisories([m[1]])
  }
  if (state.pushed) for (const f of findings()) handed.add(f)
  // The last quality review's blocking findings, recorded as
  // quality-blocking notes; kept only when all of them are there.
  const [result, commit, blockingCount] = at('review.quality')
  if (!COMMIT.test(commit || '')) return
  const prefix = `quality-blocking ${commit} `
  const found = noted.filter((v) => v.startsWith(prefix)).map((v) => v.slice(prefix.length))
  if (result === 'blocked' && found.length && blockingCount === `blocking=${found.length}`) {
    qualityBlocking = found
    qualityAt = commit
    // The files they name scope the next review when the security review
    // passed at the same commit; a blocked one's files were not recorded.
    const [securityResult, securityAt] = at('review.security')
    if (securityResult === 'pass' && securityAt === commit) setBlocked(commit, found.map(qualityFile))
  }
}
// The figures in one line for the retrospective's and the reporter's
// prompts; the run state holds the same.
function summary() {
  const keys = Object.keys(usage)
  const total = (field) => keys.reduce((n, k) => n + usage[k][field], 0)
  const first = Object.keys(firstPass).map((g) => `${g}:${firstPass[g]}`).join(',') || 'none'
  return `output tokens ${Math.round(total('tokens'))}, tool calls ${total('calls')}; per phase ${keys.map((k) => `${k}=${Math.round(usage[k].tokens)}/${usage[k].calls}`).join(',') || 'none'}; first passes ${first}; rework ${rework} of ${ROUNDS + extra}${ciMinutes !== null ? `; CI ${ciMinutes} min` : ''}`
}

// The records the script writes: a phase or a review at a commit, queued as
// command lines of fixed words, commits, and counts, then run by flush().
const COMMIT = /^[0-9a-f]{7,40}$/
const CHANGE = /^[a-z0-9][a-z0-9-]*$/
const pending = []
function queue(line, commit) {
  if (CHANGE.test(state.change || '') && COMMIT.test(commit || '')) pending.push(line)
  else note(`not recorded (change ${state.change}, commit ${commit}): ${line}`)
}
function phaseDone(name, commit) {
  state['phase.' + name] = commit
  queue(`sh tools/run_state.sh phase ${state.change} ${name} ${commit}`, commit)
}
function reviewed(kind, passed, commit, counts) {
  const result = passed ? 'pass' : 'blocked'
  state['review.' + kind] = `${result} ${commit}`
  const summary = Object.keys(counts).map((k) => `${k}=${Number.isInteger(counts[k]) ? counts[k] : 0}`).join(' ')
  queue(`sh tools/run_state.sh review ${state.change} ${kind} ${result} "${summary}" ${commit}`, commit)
}
// Runs the queued records with the metric line through one agent; with no
// record queued no agent starts unless force (a stopped run's stop word),
// and the figures wait for the next line an agent runs. The agent's own
// cost reaches the next line, so the last flush's is the one figure
// recorded nowhere.
async function flush(force) {
  if (!pending.length && !force) return true
  const command = pending.splice(0).concat([metricLine()].filter(Boolean)).join(' && ')
  if (!command) return true
  const r = await measured('record', () => agent(
    `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${command}\n\nReturn ok true when it exited 0, and its output.`,
    { schema: withCalls(RECORDED), effort: 'low', label: 'record' }))
  if (r && r.ok) return true
  if (!stopped) stopped = `the run state records failed: ${r ? r.output : 'no result'}`
  return false
}
// The merge gates with the review and check results the script holds, for
// the merger: those of a fresh worktree of origin/main, which the branch
// cannot have edited, run against the branch. The add fails when anything
// but an earlier worktree stands at the path, and the gates do not run.
const MERGE_GATES = 'tmp/.merge-gates'
function mergeGates() {
  const records = ['security', 'quality', 'bench'].map((k) => `${k}:${at('review.' + k).slice(0, 2).join(':')}`)
    .concat([`check:pass:${state['phase.check'] || ''}`])
    .filter((r) => /^[a-z]+:(pass|blocked):[0-9a-f]{7,40}$/.test(r))
  return `git worktree prune; git worktree remove --force ${MERGE_GATES}; git worktree add -q --detach ${MERGE_GATES} origin/main && CHANGE=${state.change} RECORDS="${records.join(' ')}" sh ${MERGE_GATES}/tools/gates.sh merge build/pipeline/${state.change}.body.md`
}

const at = (key) => (state[key] || '').split(' ')
const doneAtHead = (name) => state['phase.' + name] === head
const reviewedAtHead = (kind) => at('review.' + kind)[0] === 'pass' && at('review.' + kind)[1] === head
const note = (line) => { notes.push(line); log(line) }
const backlog = []
let planNotes = []
// The checker's word on the benchmark at a commit, and the blocking findings
// of the quality review at qualityAt, for the next review of a fix.
let benchSameAt = ''
let benchReport = []
let qualityBlocking = []
let qualityAt = ''
// The files the blocking findings of the reviews at blockedAt name, null
// when one names none, for the scope of the next quality review.
let blockedAt = ''
let blockedFiles = null
// A plain relative path, no parent step: the only form passed to scope.
const PATH = /^[A-Za-z0-9_][A-Za-z0-9_./-]*$/
const plainPath = (p) => PATH.test(p || '') && !/(^|\/)\.\.(\/|$)/.test(p) ? p : null
// The file of a quality finding, "<commit> <file>:<line> ...", or null.
const qualityFile = (f) => {
  const m = /^(?:[0-9a-f]{7,40} )?([^\s:]+):[0-9]+/.exec(f)
  return m ? plainPath(m[1]) : null
}
function setBlocked(commit, files) {
  blockedAt = commit
  blockedFiles = files.every(Boolean) ? [...new Set(files)] : null
}
// The advisories of every quality review of the run, in order and without
// duplicates, for docs/backlog.md; the findings handed to the contributor
// so far, so a CI fix's push gets only those that arrived after them.
let qualityAdvisory = []
const handed = new Set()
// An advisory is kept by its text without the commit of the review that
// found it, as seed reads the notes, so a later round's repeat is one entry.
const addAdvisories = (list) => {
  for (const a of list.map((x) => String(x).replace(/^[0-9a-f]{7,40} /, ''))) if (!qualityAdvisory.includes(a)) qualityAdvisory.push(a)
}
const findings = () => backlog.concat(qualityAdvisory.map((a) => `quality advisory ${a}`))
function handOver() {
  const fresh = findings().filter((f) => !handed.has(f))
  for (const f of fresh) handed.add(f)
  return fresh
}
const intro = () => `Change \`${state.change}\` on branch \`${state.branch}\`.`

async function contributor(mode, detail) {
  if (mode === 'fix') rework++
  const key = mode === 'implement' || mode === 'fix' ? 'implement' : 'package'
  const result = await measured(key, () => agent(
    `${intro()} Mode: ${mode}. ${detail}\nFollow your Modes section for \`${mode}\` and return the schema.`,
    { agentType: 'contributor', schema: withCalls(WORK), label: `contributor: ${mode}` }))
  if (!result || result.status !== 'done') {
    stopped = `contributor (${mode}) stopped: ${result ? result.question || result.summary : 'no result'}`
    return false
  }
  head = result.head
  note(`contributor (${mode}): ${result.summary}`)
  return result
}

// Check, the quality and security reviews in parallel, and benchmark until
// all pass at one commit; whatever blocks goes back to the contributor while
// mayFix allows, both reviews' findings in one round.
async function verify() {
  const passed = await rounds()
  return (await flush()) && passed
}

// The quality reviewer's input after an earlier review: its commit, its
// blocking findings, and the scope command that allows the fix diff alone
// when the fix since that commit changed only the files the blocking
// findings of that round name, tests, and records. Without the findings or
// their files, or at HEAD itself, the whole branch diff is reviewed.
function priorQuality() {
  const [result, commit] = at('review.quality')
  if (!COMMIT.test(commit || '')) return ''
  const last = `\nThe last quality review, at ${commit}, was ${result}.`
  const blocked = result === 'blocked'
  const listed = !blocked ? [] : qualityAt === commit && qualityBlocking.length ? qualityBlocking : null
  const files = blockedAt === commit ? blockedFiles : null
  if (commit === head || !listed || !files) return `${last} Review the whole branch diff.`
  const prior = listed.length ? ` Its blocking findings:\n- ${listed.join('\n- ')}\n` : ' '
  return `${last}${prior}Run \`sh tools/run_state.sh scope ${state.change} ${commit}${files.map((f) => ` ${f}`).join('')}\`: when it prints fix, review only \`git diff ${commit} HEAD\` against ${blocked ? 'those findings and ' : ''}the rules; otherwise review the whole branch diff.`
}

// The fix rounds of the run, review and CI fixes alike, counted across
// starts: at most ROUNDS plus the extra rounds granted. A resume of a run
// that already spent rounds gets one extra round, once per start, when the
// last start did not stop at the limit (a killed stage, a restarted
// container), recorded as an extra-round note with its reason.
function mayFix() {
  if (rework < ROUNDS + extra) return true
  if (!extraNow && seededRework > 0 && lastStop !== 'rounds') {
    extraNow = true
    extra++
    const why = `fix round ${rework + 1} granted beyond ${ROUNDS} on a resume: the last start did not stop at the round limit (stop ${lastStop || 'unrecorded'})`
    note(`extra round: ${why}`)
    queue(`sh tools/run_state.sh note ${state.change} extra-round "${why}"`, head)
    return true
  }
  stopKind = 'rounds'
  return false
}

// The metric line as the first instruction of an agent that may run it.
const figuresFirst = () => {
  const line = metricLine()
  return line ? ` First run this line of the run's figures, exactly as written: \`${line}\`\n` : ''
}

// The quality review at the head, with the scope priorQuality gives.
function qualityReview(scope) {
  return agent(`${intro()} Review the committed diff and return the findings.${scope}`,
    { agentType: 'quality-reviewer', schema: withCalls(QUALITY), phase: 'Quality', label: 'quality-reviewer' })
}
function securityReview(retry) {
  return agent(retry
    ? `${intro()} The last security review did not complete. Run it again, every sub-task inline, and return the result.`
    : `${intro()} Run the security review on the committed diff and return the result.`,
  { agentType: 'security-reviewer', schema: withCalls(SECURITY), phase: 'Security', label: retry ? 'security-reviewer: retry' : 'security-reviewer' })
}

// The reviews not yet passed at the head, quality and security in parallel
// on the same commit, so one fix round answers both. Their output tokens
// cannot be told apart, so a pair is counted under reviews; a single review
// keeps its own key. Returns the blocking message, '' when nothing blocks,
// or null when a review did not run.
async function reviews() {
  const kinds = ['quality', 'security'].filter((k) => !reviewedAtHead(k))
  if (!kinds.length) return ''
  const scope = kinds.includes('quality') ? priorQuality() : ''
  const run = { quality: () => qualityReview(scope), security: () => securityReview(false) }
  if (kinds.length > 1) { phase('Quality'); phase('Security') } else phase(kinds[0] === 'quality' ? 'Quality' : 'Security')
  const results = await measured(kinds.length > 1 ? 'reviews' : kinds[0], () => parallel(kinds.map((k) => run[k])))
  const got = {}
  kinds.forEach((k, i) => { got[k] = results[i] })
  if (kinds.includes('security') && (!got.security || !got.security.ran)) got.security = await measured('security', () => securityReview(true))
  const messages = []
  const files = []
  let commit = head
  if (kinds.includes('security')) {
    const s = got.security
    if (!s || !s.ran) { stopped = 'the security review did not run; it cannot be skipped'; return null }
    const blocking = s.findings.filter((f) => f.severity !== 'Low' && f.confidence >= 8 && f.in_change)
    verdict('security', !blocking.length)
    for (const f of s.findings.filter((f) => !blocking.includes(f))) {
      const line = `security ${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`
      if (!backlog.includes(line)) backlog.push(line)
    }
    note(`security at ${s.head}: ${s.findings.length} finding(s), ${blocking.length} blocking`)
    const count = (severity) => s.findings.filter((f) => f.severity === severity).length
    reviewed('security', !blocking.length, s.head, { high: count('High'), medium: count('Medium'), low: count('Low'), blocking: blocking.length })
    if (blocking.length) messages.push(`Blocking security findings, to fix first:\n- ${blocking.map((f) => `${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`).join('\n- ')}`)
    files.push(...blocking.map((f) => plainPath(f.file)))
    commit = s.head
  }
  if (kinds.includes('quality')) {
    const q = got.quality
    if (!q) { stopped = 'the quality reviewer returned no result'; return null }
    qualityBlocking = q.blocking
    qualityAt = q.head
    addAdvisories(q.advisory)
    verdict('quality', !q.blocking.length)
    note(`quality at ${q.head}: ${q.blocking.length} blocking, ${q.advisory.length} advisory`)
    reviewed('quality', !q.blocking.length, q.head, { blocking: q.blocking.length, advisory: q.advisory.length })
    if (q.blocking.length) messages.push(`Blocking quality findings:\n- ${q.blocking.join('\n- ')}`)
    files.push(...q.blocking.map(qualityFile))
    commit = q.head
  }
  if (messages.length) setBlocked(commit, files)
  return messages.join('\n\n')
}

async function rounds() {
  for (;;) {
    let blocked = ''
    if (!doneAtHead('check')) {
      phase('Check')
      // The check the workflow last recorded: stage records count only at
      // it, so a record at the head that no workflow record backs runs again.
      const backed = COMMIT.test(state['phase.check'] || '') ? state['phase.check'] : ''
      const how = backed ? ` The last check the workflow recorded passed at ${backed}: run \`sh tools/run_state.sh check ${state.change} ${backed}\`.` : ''
      const c = await measured('check', () => agent(`${intro()}${figuresFirst()} Run the checks and report.${how}`, { agentType: 'checker', schema: withCalls(CHECK), effort: 'low' }))
      if (!c) { stopped = 'the checker returned no result'; return false }
      verdict('check', c.passed)
      note(`check at ${c.head}: ${c.passed ? 'passed' : 'failed at ' + c.failed_stage}`)
      if (c.passed) {
        phaseDone('check', c.head)
        benchSameAt = c.bench_same ? c.head : ''
        benchReport = c.bench_report || []
      } else blocked = `The stage ${c.failed_stage} failed; its log:\n${c.log_excerpt || ''}`
    }
    if (!blocked) {
      const r = await reviews()
      if (r === null) return false
      blocked = r
    }
    if (!blocked && !reviewedAtHead('bench')) {
      phase('Benchmark')
      if (benchSameAt && benchSameAt === state['phase.check']) {
        // The check measured the same allocations and rounds as main's
        // recorded figures (the newest merged change without a history row,
        // else the last row): nothing to compare with main.
        verdict('bench', true)
        note(`benchmark at ${benchSameAt}: allocations and rounds equal main's recorded figures; no agent`)
        reviewed('bench', true, benchSameAt, { blocking: 0 })
      } else {
        const b = await measured('bench', () => agent(
          `${intro()} The check's measurement differs from main's recorded figures, or was not compared:\n- ${benchReport.join('\n- ') || 'no comparison'}\nCompare with main and return the result. Build the base with PREFIX=$PWD/tmp/.toolchain SPINEL_CACHE_DIR=$PWD/build/spinel-cache, as your step 1 says.`,
          { agentType: 'benchmark', schema: withCalls(BENCH), effort: 'low' }))
        if (!b) { stopped = 'the benchmark agent returned no result'; return false }
        verdict('bench', !b.blocking.length)
        note(`benchmark at ${b.head}: ${b.report.join('; ')}`)
        reviewed('bench', !b.blocking.length, b.head, { blocking: b.blocking.length })
        if (b.blocking.length) blocked = `Blocking regressions:\n- ${b.blocking.join('\n- ')}`
      }
    }
    if (!blocked) return true
    if (!mayFix()) { stopped = `still blocked after ${rework} fix rounds: ${blocked.split('\n')[0]}`; return false }
    phase('Implement')
    if (!(await contributor('fix', blocked))) return false
  }
}

phase('Resume')
const resume = await agent(
  `Prepare the delivery of one change. Input: ${JSON.stringify(input)}.
1. \`git fetch -q origin\`. The change name is input.change, or an existing change under openspec/changes/ that the brief names, or a kebab-case name of 2 to 5 words derived from the brief.
2. The branch is input.branch, or the one in build/pipeline/<change>.json, or <type>/<change> with the type from CLAUDE.md's Branch naming. Check it out when it exists locally or on origin; otherwise create it from origin/main, which needs a clean tree (stop with the reason when it is not).
3. \`make doctor\`; run \`make toolchain\` when it fails and stop when that fails too.
4. Run \`sh tools/run_state.sh init <change> <branch>\`, then \`sh tools/run_state.sh trusted <change>\`, and return the second command's output verbatim as state_json, with \`git rev-parse --short=12 HEAD\` as head.
5. Run \`sh tools/run_state.sh plan-needed <change>\` and return its output verbatim as plan, both lines when it prints two; its exit 1 means not needed, not a failure.`,
  { schema: RESUME, effort: 'low', label: 'resume' })
if (!resume || resume.status !== 'done') {
  stopped = `resume stopped: ${resume ? resume.reason : 'no result'}`
} else {
  state = JSON.parse(resume.state_json)
  head = resume.head
  seed()
  note(`resumed ${state.change} on ${state.branch} at ${head}`)
  // trusted left out the phase and review records git does not support, so
  // their phases run again.
  if (state.untrusted) note(`not trusted, run again: ${state.untrusted}`)
  if (!CHANGE.test(state.change || '')) stopped = `not a change name: ${state.change}`
}

// The planner orders the queue from the metrics history before a new change
// starts; an unresolved blocking security finding goes first. It runs only
// when the queue needs a decision: plan-needed found one (the change is not
// the queue's head, or a proposal or finding waits), or the brief is a
// request beyond the change's name. Otherwise the head item is taken as
// written, with its size as the estimate. A brief that is only the change
// name gives the scouts and the contributor nothing to work from, so the
// queue item plan-needed printed (its item: line) is their brief.
const planLines = resume && typeof resume.plan === 'string' ? resume.plan.split('\n') : []
const planLine = planLines[0] || ''
const request = typeof input.brief === 'string' && input.brief.trim() !== '' && input.brief.trim() !== state.change
const item = (planLines.find((l) => /^item: /.test(l)) || '').slice(6).trim()
const brief = request ? input.brief : item ? `the item of docs/queue.md for this change, as written: ${item}` : input.brief
if (!stopped && !state.merged && !state['phase.plan'] && !state['phase.implement'] && !request && /^not needed:/.test(planLine)) {
  phase('Plan')
  const size = /estimated (small|medium|large)\b/.exec(planLine)
  if (size) estimate = size[1]
  planned = 0
  note(`plan: skipped, ${planLine}`)
  phaseDone('plan', head)
}
if (!stopped && !state.merged && !state['phase.plan'] && !state['phase.implement']) {
  phase('Plan')
  planned = 1
  const p = await measured('plan', () => agent(
    `${intro()} Plan the queue for this delivery. Brief: ${input.brief || 'the existing OpenSpec change'}.`,
    { agentType: 'planner', schema: withCalls(PLAN) }))
  if (!p) stopped = 'the planner returned no result'
  else {
    note(`plan: ${p.decisions.map((d) => `${d.decision} (${d.evidence})`).join('; ') || 'no change to the queue'}`)
    planNotes = p.notes
    // Stored with the figures, so budget and the history row keep it after
    // the queue item leaves the queue.
    if (SIZES.includes(p.estimate)) estimate = p.estimate
    if (p.security_first.length) stopped = `security first: deliver the fix of ${p.security_first.join('; ')} before this change`
    else phaseDone('plan', head)
  }
}

if (!stopped && !state.merged) {
  if (!state['phase.implement']) {
    phase('Scout')
    let packs = input.packs || []
    if (!packs.length) {
      const plan = await measured('scout', () => agent(
        `List the areas of docs/codebase-map.md (by number and name) whose files this change edits, as the brief says, at most ${MAX_AREAS}: ${brief || state.change}. ${input.areas ? 'Requested areas: ' + input.areas.join(', ') + '.' : ''} Leave out an area the change only reads, and any finding the change only records in docs/backlog.md or other bookkeeping: those reach the contributor through the plan notes, never a scout. For each area, a pack under tmp/scout/ is current when its Commit: is origin/main or \`git diff --quiet <its commit> origin/main -- <its Files read>\` passes; list current packs by path and the areas still needing one, with the question a contributor needs answered about the code it edits.`,
        { schema: withCalls(SCOUT_PLAN), effort: 'low', label: 'scout plan' }))
      const room = plan ? Math.max(0, MAX_AREAS - plan.current.length) : 0
      const needed = plan ? plan.needed.slice(0, room) : []
      if (plan && plan.needed.length > room) note(`not scouted, beyond ${MAX_AREAS} areas: ${plan.needed.slice(room).map((n) => n.area).join(', ')}`)
      const fresh = plan ? await measured('scout', () => parallel(needed.map((n) => () =>
        agent(`Area: ${n.area}. Question: ${n.question}. Write the pack and return its path.`, { agentType: 'scout', schema: withCalls(PACK), label: `scout: ${n.area}` })))) : []
      packs = (plan ? plan.current : []).concat(fresh.filter(Boolean).map((p) => p.pack))
      note(`scout packs: ${packs.join(', ') || 'none'}`)
    }
    phase('Implement')
    const done = await contributor('implement', `Brief: ${brief || 'the existing OpenSpec change'}. Scout packs: ${packs.join(', ') || 'none'}.${planNotes.length ? `\nPlan notes:\n- ${planNotes.join('\n- ')}` : ''}`)
    if (done) phaseDone('implement', head)
  }

  // A second push is refused, so a restart finds the package step done from
  // the push and the pull request it recorded (tools/run_state.sh push and
  // set pr); its phase line waits for the last flush.
  if (!stopped && !(state.pushed && state.pr)) {
    if (await verify()) {
      phase('Package')
      const plan = planned === 0
        ? 'The planner did not run: this change was taken from the head of docs/queue.md as written. Leave build/plan/, which holds an older run\'s files; remove this change\'s item from docs/queue.md and renumber the rest, and append the history of the merged changes as your package step says.'
        : 'Apply the planner\'s files under build/plan/ and append the history of the merged changes as your package step says.'
      const done = await contributor('package', `Non-blocking findings for docs/backlog.md:\n- ${handOver().join('\n- ') || 'none'}\n${plan}`)
      if (done) { state.pr = String(done.pr || ''); phaseDone('package', head) }
    }
  }

  // One agent waits for CI, up to 30 minutes a start, and merges. Pending
  // CI is asked again, at most WAITS times; red CI goes back to the
  // contributor's fix loop. The CI and merge phase lines wait for the last
  // flush; a restart after the merge reads merged, which the merger wrote.
  if (!stopped) {
    phase('Merge')
    let waits = 0
    for (;;) {
      const m = await measured('merge', () => agent(
        `${intro()} First run this line of the run's figures, exactly as written: \`${metricLine()}\`\nThen wait for CI at the pushed head${waits ? ' (it was still running when you last returned; keep waiting)' : ''}, and merge the pull request if CI is green and every merge gate passes. The merge gates: \`${mergeGates()}\``,
        { agentType: 'merger', schema: withCalls(MERGE), effort: 'low' }))
      if (!m) { stopped = 'the merger returned no result'; break }
      const checks = (m.checks || []).join('; ')
      note(`CI at ${m.head}: ${m.ci}${m.minutes ? ` in ${m.minutes} min` : ''}${m.ci === 'pending' && checks ? ` (${checks})` : ''}`)
      if (m.ci === 'pending' && !(m.waited >= 30)) note(`the merger returned pending after waiting ${Number.isFinite(m.waited) ? m.waited : 'unknown'} of 30 minutes`)
      if (m.ci === 'pending') {
        if (++waits < WAITS) continue
        stopped = `CI stalled at ${m.head} after ${WAITS} waits of up to 30 minutes: ${checks || 'no check state returned'}`
        break
      }
      waits = 0
      if (m.ci === 'green' || m.ci === 'red') verdict('ci', m.ci === 'green')
      if (Number.isFinite(m.minutes) && m.minutes > 0) ciMinutes = m.minutes
      if (m.ci === 'green') { state.ci = `green ${m.head}`; phaseDone('ci', m.head) }
      if (m.merged) {
        state.merged = m.sha
        phaseDone('merge', m.sha)
        note(`merged ${m.sha}: ${m.subject}${m.branch_deleted ? '' : ' (branch deletion refused)'}`)
        break
      }
      if (m.ci !== 'red' || !mayFix()) {
        stopped = m.ci === 'green' ? `not merged: ${m.problem || 'no reason given'}` : `CI ${m.ci}${m.step ? ' at ' + m.step : ''}${m.problem ? ': ' + m.problem : ''}${m.ci === 'red' ? ` after ${rework} fix rounds` : ''}`
        break
      }
      if (!(await contributor('fix', `CI failed at ${m.step}; its log:\n${m.log_excerpt || ''}`))) break
      if (!(await verify())) break
      phase('Merge')
      const fresh = handOver()
      if (!(await contributor('push', `Push the CI fix.${fresh.length ? `\nNon-blocking findings for docs/backlog.md, which arrived after the package step:\n- ${fresh.join('\n- ')}` : ''}`))) break
    }
  }
}

// After the merge: record the run's figures, learn from them, and review the
// whole codebase when five changes merged since the last review or this one
// touched a sensitive area. What they find waits in the run state for the
// next change's planner.
if (!stopped && state.merged && !state['phase.retro']) {
  phase('Retrospective')
  // The line and the summary are built from the same figures at once, so
  // once the line has run the run state's totals equal the summary's.
  const line = metricLine()
  const figures = summary()
  const r = await measured('retro', () => agent(
    `${intro()} The change merged. First run this line, which stores the figures below in the run state, exactly as written: \`${line}\`\nIts figures: ${figures}.\nWorkflow notes:\n- ${notes.join('\n- ')}`,
    { agentType: 'retrospective', schema: withCalls(RETRO) }))
  if (!r) stopped = 'the retrospective returned no result'
  else {
    phaseDone('retro', state.merged)
    note(`retrospective: ${r.proposals.map((x) => `${x.proposal} (${x.evidence})`).join('; ') || 'no proposal'}; ${r.review_due}`)
    if (r.due) {
      phase('Review')
      let p = null
      try {
        p = await measured('review', () => workflow({ scriptPath: '.claude/workflows/periodic-review.js' }, { change: state.change }))
      } catch (e) {
        note(`the periodic review failed to start: ${e.message}`)
      }
      if (!p || !p.ran) stopped = 'the periodic security review did not run; run /review'
      else note(`periodic review: security ${p.security.length} finding(s), ${p.security_blocking} blocking (to the front of the queue); quality ${p.quality_blocking.length} blocking, ${p.quality_advisory} advisory${p.recorded === false ? '; the results were not recorded in the run state' : ''}`)
    }
  }
}

phase('Report')
const report = await measured('report', () => agent(
  `Change \`${state.change || input.change || 'unknown'}\`. Write the report. Figures: ${summary()}.\nWorkflow notes:\n- ${notes.join('\n- ')}\n${stopped ? 'The run stopped: ' + stopped : 'The run finished.'}`,
  { agentType: 'reporter', schema: withCalls(REPORT), effort: 'low' }))
// Everything the script decided since the last flush: the retrospective,
// the report, and a stopped run's records, so a restart does not repeat them.
if (state.change) {
  if (report) phaseDone('report', state.merged || head)
  if (!(await flush(Boolean(stopped)))) note(stopped)
}
return report ? report.report : `No report; notes:\n${notes.join('\n')}${stopped ? '\nStopped: ' + stopped : ''}`
