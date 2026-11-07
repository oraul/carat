export const meta = {
  name: 'deliver-change',
  description: 'Deliver one change to main through fixed phases: plan, scouts, contributor, checker, quality and security review, benchmark, package, CI and merge, close (records, retrospective, and report in one start), periodic review',
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
    { title: 'Close', detail: 'retrospective: the last records, the proposals, the budget and review-due lines, and the report, in one start' },
    { title: 'Review', detail: 'periodic review of the whole codebase: security, never skipped, and quality' },
  ],
}

// args: { change?, brief?, branch?, packs?: [path], areas?: [string] }, or a
// string that is a change name or a brief. The run state, written only by
// tools/run_state.sh and read through its trusted command (only the records
// at a commit of the branch or of main), decides which phases are already
// done: a phase whose recorded commit is the current one is skipped, so a
// restart resumes and a fix (a new commit) runs every later phase again;
// the check, the reviews, and the benchmark are skipped only on a pass this
// start recorded (ran), so a resume runs them again. The workflow also
// measures the run (output tokens and tool calls per phase, the first
// verdict of each gate, rework rounds, CI minutes, the plan's estimate) and
// stores every figure as metric.* in one metric line (metricLine), so a
// restart seeds them and tools/run_state.sh history builds a whole row;
// the total tokens and wall minutes of each start, which only the session
// that ran the workflow sees, /deliver adds with tools/run_state.sh usage. The
// run state's phase.* and review.* lines and the figures are the script's
// own: it builds each command from a schema-checked result. One agent that
// reads nothing else runs the queued phase and review lines with the
// metric line (flush) at the end of verify(), since the pre-push gates
// read the reviews; the closing start runs those left at the end, where
// the package, CI, and merge phases wait (a resume reads pushed, pr, and
// merged instead), under the guard's close profile, which allows only the
// phases no merge gate reads. The checker and the merger run the metric
// line first, so a fix round is counted before its check.
// tools/agent_guard.sh keeps the other agents off the phase and review
// commands, and the merger's records gate compares the file with what the
// script received. Each start's model tier and effort come from
// CALIBRATION, and the run state records them beside its figures.
const input = typeof args === 'string' ? { brief: args } : (args || {})
const ROUNDS = 3
// Map areas scouted per change, and merger calls that may find CI still
// running (each waits up to 30 minutes) before the run stops as stalled.
const MAX_AREAS = 3
const WAITS = 4
// Checker starts in a row that may end without a verdict at the head (a
// killed, superseded, or unfinished check) before the run stops; such a
// start is rerun with no fix round.
const RERUNS = 2
const notes = []
let head = ''
let state = {}
// The phase and review records this start made. A skip and the merge
// gates' records read only these, never the run state's, which branch code
// run by the checks can write: a resume runs the check and the reviews
// again at the head.
const ran = {}
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
// Tool calls per agent start. CALL_CAPS holds a start's cap at a medium
// estimate, from the history's calls per phase; CALL_SCALE scales it by the
// estimate, rounded up, the medium figure applying while no estimate exists
// (the planner's start). FIXED_CAPS holds the starts whose work does not
// grow with the change (areas is the scout plan); the merger's grows by 2
// for each CI wait beyond the second (mergerCap). The prompt states the cap
// (capLine) and the agent stops at it; a start that reports more calls is
// noted and leaves an overrun note for the planner (measured). The hard
// ceiling is each agent file's maxTurns, its largest cap at a large
// estimate plus a return margin of 5 turns (the merger's: its cap, which
// holds two waits, 2 for each of the other five of its 30 minutes, and the
// margin), so a start
// whose capped calls take one turn each can still commit, back up, and
// return the schema; tools/tools_test.sh compares them with these lines.
const CALL_CAPS = { planner: 20, scout: 30, implement: 90, fix: 40, package: 30, push: 15, checker: 20, quality: 35, security: 35, bench: 20, close: 25 }
const CALL_SCALE = { small: 0.5, medium: 1, large: 1.5 }
const FIXED_CAPS = { resume: 12, areas: 10, record: 3, merger: 12 }
const sizeWord = () => (SIZES.includes(estimate) ? estimate : 'medium')
const callCap = (kind) => (kind in FIXED_CAPS ? FIXED_CAPS[kind] : Math.ceil(CALL_CAPS[kind] * CALL_SCALE[sizeWord()]))
const capLine = (kind) => `\nTool calls: at most ${callCap(kind)} in this start (${kind in FIXED_CAPS ? 'a fixed cap' : `the ${kind} cap at ${SIZES.includes(estimate) ? `the ${estimate} estimate` : 'the medium figure, with no estimate yet'}`}). Count them; on reaching the cap, stop and return the schema with what is done, saying the cap stopped you.`
// The merger's waits are 3, 4, then 5 minutes (.claude/agents/merger.md), so
// the minutes it waited give the waits beyond the second.
const mergerCap = (r) => FIXED_CAPS.merger + 2 * (Number(r.waited) > 7 ? Math.ceil((Number(r.waited) - 7) / 5) : 0)
// The model tier and reasoning effort of each kind of agent start, as
// TIER/EFFORT, set from the history's figures (docs/goals.md, Calibration).
// The tier is cheap, the model: line of the agent's file, the only place a
// tier is named (tools/tools_test.sh compares them), or session, the
// session's model; the effort is low, or session, none passed. One kind
// moves at a time, kept only when the first-pass rates and the rework do
// not get worse over the next runs; the security reviewer never moves.
// calibrate gives a start its options and records its profile, which the
// metric line stores as calib.KIND beside the tokens, calls, and verdicts.
const CALIBRATION = { resume: 'session/low', planner: 'session/session', areas: 'session/low', scout: 'cheap/low', contributor: 'session/session', checker: 'cheap/low', quality: 'session/session', security: 'session/session', bench: 'cheap/low', record: 'session/low', merger: 'cheap/low', close: 'session/session' }
const calibrated = {}
function calibrate(kind, opts) {
  calibrated[kind] = CALIBRATION[kind]
  const effort = CALIBRATION[kind].split('/')[1]
  return effort === 'session' ? opts : Object.assign({}, opts, { effort })
}
// A restart carries on the profiles an earlier start recorded as
// metric.calib.KIND, for the kinds this start has not used yet; a value
// outside the table's form is dropped.
function restoreCalibration(saved, used) {
  for (const key of Object.keys(saved)) {
    const m = /^metric\.calib\.([a-z]+)$/.exec(key)
    if (m && !(m[1] in used) && /^(cheap|session)\/(low|session)$/.test(saved[key])) used[m[1]] = saved[key]
  }
  return used
}

const STATUS = { type: 'string', enum: ['done', 'stopped'] }
const WORK_STATUS = { type: 'string', enum: ['done', 'partial', 'stopped'], description: 'partial: the cap stopped you with the work committed and backed up' }
const HEAD = { type: 'string', description: 'git rev-parse --short=12 HEAD at the end' }
const LINES = { type: 'array', items: { type: 'string' } }
const RESUME = {
  type: 'object',
  properties: {
    status: STATUS, change: { type: 'string' }, branch: { type: 'string' }, head: HEAD,
    state_json: { type: 'string', description: 'the output of tools/run_state.sh trusted, verbatim' },
    plan: { type: 'string', description: 'the output of tools/run_state.sh plan-needed, verbatim: its one line' },
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
  properties: {
    status: WORK_STATUS, head: HEAD, summary: { type: 'string' }, question: { type: 'string' }, assumptions: LINES, pr: { type: 'integer' },
    remaining: { ...LINES, description: 'with status partial: each task or step left, one line each' },
    pushed: { type: 'string', description: 'after a push: the full sha it recorded, sh tools/run_state.sh get <change> pushed' },
  },
  required: ['status', 'head', 'summary'],
}
const CHECK = {
  type: 'object',
  properties: {
    passed: { type: 'boolean' }, head: HEAD, stages: LINES, failed_stage: { type: 'string' }, log_excerpt: { type: 'string' },
    verdict: { type: 'string', description: 'the last line tools/run_state.sh check printed, verbatim; empty when it printed none' },
    bench_same: { type: 'boolean', description: 'tools/run_state.sh bench exited 0' }, bench_report: LINES,
    budget: { type: 'string', description: 'the line tools/run_state.sh spent printed, verbatim; empty when the check did not pass' },
  },
  required: ['passed', 'head', 'stages', 'verdict'],
}
const FINDING = {
  type: 'object',
  properties: {
    severity: { type: 'string', enum: ['High', 'Medium', 'Low'] }, confidence: { type: 'integer', minimum: 1, maximum: 10 },
    file: { type: 'string' }, line: { type: 'integer' }, in_change: { type: 'boolean' }, title: { type: 'string' }, fix: { type: 'string' },
  },
  required: ['severity', 'confidence', 'file', 'in_change', 'title', 'fix'],
}
const NOT_REVIEWED = { ...LINES, description: 'the files of the diff you did not review when the cap stopped you, empty when none' }
const QUALITY = {
  type: 'object',
  properties: { head: HEAD, blocking: LINES, advisory: LINES, not_reviewed: NOT_REVIEWED },
  required: ['head', 'blocking', 'advisory'],
}
const SECURITY = {
  type: 'object',
  properties: { ran: { type: 'boolean' }, head: HEAD, findings: { type: 'array', items: FINDING }, not_reviewed: NOT_REVIEWED },
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
const CLOSE = {
  type: 'object',
  properties: {
    proposals: { type: 'array', items: { type: 'object', properties: { proposal: { type: 'string' }, evidence: { type: 'string' } }, required: ['proposal', 'evidence'] } },
    review_due: { type: 'string', description: 'the line tools/run_state.sh review-due printed, empty without the retrospective steps' },
    due: { type: 'boolean' },
    recorded: { type: 'boolean', description: 'the record line exited 0' },
    record_output: { type: 'string' },
    report: { type: 'string' },
  },
  required: ['proposals', 'due', 'recorded', 'report'],
}
const CALLS = { type: 'integer', description: 'how many tool calls you made for this task' }
const withCalls = (schema) => ({ ...schema, properties: { ...schema.properties, tool_calls: CALLS }, required: [...schema.required, 'tool_calls'] })

// A start that reaches its stated cap returns what it left; one that
// reaches its agent file's maxTurns returns nothing. Either is continued by
// another start told what is left, at most CONTINUES in a row, so the run
// resumes from the committed work instead of failing; a result that
// stopped on its own (a contributor's question) stops the run. rest is the
// kind's list of what is left: empty when nothing is, null when the start
// stopped on its own. tools/tools_test.sh runs these helpers.
const CONTINUES = 2
function continuation(result, rest, count) {
  if (result && rest && !rest.length) return { next: 'done', left: [] }
  if (result && !rest) return { next: 'stop', left: [] }
  return { next: count < CONTINUES ? 'continue' : 'stop', left: result ? rest : [] }
}
// A contributor's work left: its remaining tasks when partial (the
// unchecked tasks when it named none), null when it stopped.
function workLeft(r) {
  if (r.status === 'done') return []
  if (r.status !== 'partial') return null
  const rest = Array.isArray(r.remaining) ? r.remaining.filter(Boolean) : []
  return rest.length ? rest : ['the unchecked tasks of tasks.md']
}
// A review's files left; a security review that did not run is left whole.
function reviewLeft(r) {
  if ('ran' in r && !r.ran) return ['the whole diff']
  return Array.isArray(r.not_reviewed) ? r.not_reviewed.filter(Boolean) : []
}
// A continued review's result: the later start's head and coverage, the
// findings of both without duplicates.
function combineReviews(a, b) {
  if (!a || !b) return b || a
  const out = { ...b }
  for (const key of ['findings', 'blocking', 'advisory']) {
    if (!Array.isArray(a[key]) || !Array.isArray(b[key])) continue
    const seen = new Set()
    out[key] = a[key].concat(b[key]).filter((f) => { const k = JSON.stringify(f); return seen.has(k) ? false : seen.add(k) })
  }
  return out
}
// The full sha the push recorded, kept only when it is 40 digits beginning
// with the head the contributor reported; '' otherwise, which stops the
// merge before the merger starts.
function pushedHead(pushed, head) {
  const full = String(pushed || '')
  return /^[0-9a-f]{40}$/.test(full) && /^[0-9a-f]{7,40}$/.test(head || '') && full.startsWith(head) ? full : ''
}
// The pushed sha after one start of a package or push call: the start's own
// when it reported one, else the one kept from an earlier start, so a start
// capped after its push keeps it when the continuation, refused a second
// push, reports none.
function keepPushed(mode, pushed, result) {
  return (mode === 'package' || mode === 'push') && result && result.pushed ? result.pushed : pushed
}

// The output tokens the runtime has counted so far; the main session is idle
// while the workflow runs, so a difference is what the phase spent.
const spent = () => (typeof budget !== 'undefined' && budget && budget.spent ? budget.spent() : 0)
// Runs fn (agent calls) and adds its output tokens and reported tool calls
// to the phase key; a result reporting more calls than cap (a number, or a
// function of the result) is an overrun.
async function measured(key, fn, cap) {
  const before = spent()
  const result = await fn()
  const u = usage[key] || (usage[key] = { tokens: 0, calls: 0 })
  u.tokens += spent() - before
  for (const r of [].concat(result)) {
    if (!r || !Number.isInteger(r.tool_calls)) continue
    u.calls += r.tool_calls
    const limit = typeof cap === 'function' ? cap(r) : cap
    if (Number.isInteger(limit) && r.tool_calls > limit) overCap(key, r.tool_calls, limit)
  }
  return result
}
// An overrun of a start's cap: a workflow note, and a run state note of
// fixed words and numbers for the planner.
function overCap(key, calls, cap) {
  const text = `${key} made ${calls} tool calls in one start, over its cap of ${cap} with the estimate ${SIZES.includes(estimate) ? estimate : 'none'}`
  note(`over the call cap: ${text}`)
  queue(`sh tools/run_state.sh note ${state.change} overrun "${text}"`, head)
}
// The line tools/run_state.sh spent prints, which the checker returns after
// a pass; tools/tools_test.sh matches the script's output with it.
const SPENT_LINE = /^(under|over): ([0-9]+) output tokens so far, budget ([0-9]+) output tokens for (small|medium|large) \([0-9]+ total tokens at [0-9]+ per output token\); ([0-9]+) total tokens recorded by earlier starts, budget ([0-9]+)$/
const NO_ESTIMATE_LINE = /^no estimate: [0-9]+ output tokens so far; [0-9]+ total tokens recorded by earlier starts; /
// Notes the checker's budget line at a pass, and an overrun note on over:,
// built from its numbers; never a stop.
function budgetAtCheck(line, at) {
  const text = String(line || '').trim()
  const m = SPENT_LINE.exec(text)
  if (!m && !NO_ESTIMATE_LINE.test(text)) { note(`budget at the check pass ${at}: no spent line returned`); return }
  note(`budget at the check pass ${at}: ${text}`)
  if (m && m[1] === 'over') queue(`sh tools/run_state.sh note ${state.change} overrun "the check passed at ${at} with ${m[2]} output tokens spent against the ${m[4]} output budget of ${m[3]}, and ${m[5]} total tokens recorded by earlier starts against ${m[6]}"`, at)
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
  for (const k of Object.keys(calibrated)) pairs.push(`calib.${k}=${calibrated[k]}`)
  const safe = pairs.filter((p) => /^[a-z0-9_.-]+=([0-9./]+|small|medium|large|none|rounds|(cheap|session)\/(low|session))$/.test(p))
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
  restoreCalibration(state, calibrated)
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
// The figures in one line for the closing start's prompt; the run state
// holds the same.
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
const phaseLine = (name, commit) => `sh tools/run_state.sh phase ${state.change} ${name} ${commit}`
function phaseDone(name, commit) {
  state['phase.' + name] = commit
  ran['phase.' + name] = commit
  queue(phaseLine(name, commit), commit)
}
// The queued lines the closing start may run under the guard's close
// profile: the phases no merge gate reads, and notes.
const CLOSABLE = /^sh tools\/run_state\.sh (phase [a-z0-9-]+ (plan|implement|package|ci|merge|retro|report) [0-9a-f]{7,40}|note [a-z0-9-]+ [a-z-]+ "[^"]*")$/
function reviewed(kind, passed, commit, counts) {
  const result = passed ? 'pass' : 'blocked'
  state['review.' + kind] = `${result} ${commit}`
  ran['review.' + kind] = `${result} ${commit}`
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
    `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${command}\n\nReturn ok true when it exited 0, and its output.${capLine('record')}`,
    calibrate('record', { schema: withCalls(RECORDED), label: 'record' })), callCap('record'))
  if (r && r.ok) return true
  if (!stopped) stopped = `the run state records failed: ${r ? r.output : 'no result'}`
  return false
}
// The merger's two record lines at the pushed head, each one Bash call that
// starts with the run's figures. green records CI green and runs the merge
// gates with the review and check results the script holds: those of a
// fresh worktree of origin/main, which the branch cannot have edited, run
// against the branch, after a fetch, so origin/main is origin's main (the
// merge gates' origin gate compares the two). The removal of an earlier
// worktree stays outside the && chain, since it fails when none stands; in
// the chain a failed record runs no gate, and the add fails when anything
// but an earlier worktree stands at the path. red records CI red. The
// fetch and the add read no global or system configuration and run no
// hook, both of which branch code run by the checks can write: a global
// insteadOf would fetch a forged main, a hook would rewrite the copy.
// Before the fetch, originCheck holds origin to the hosted repository.
const MERGE_GATES = 'tmp/.merge-gates'
const PINNED_GIT = 'GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c core.hooksPath=/dev/null'
// The green line's origin check, before its fetch: origin's url, as git
// resolves it (insteadOf included) and with its lines joined, is REPO
// (owner/name, the run state's, no part only dots) on GitHub over https
// or ssh.
// Branch code run by the checks can point remote.origin.url at a local
// repository or a server of its own, whose main the forced fetch would
// make origin/main, bringing its own gates and the guard the merge hook
// reads; the check is the script's, which no fetch replaces. A REPO of
// another form matches nothing (a^b).
function originCheck(repo) {
  const valid = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repo || '') && !/(^|\/)\.+(\/|$)/.test(repo)
  const name = valid ? repo.replace(/\./g, '[.]') : 'a^b'
  return `${PINNED_GIT} remote get-url origin | tr -d '\\n' | grep -q -x -E '(https[:]//([^/@]+@)?github[.]com/|(ssh[:]//)?git@github[.]com[:/])${name}([.]git)?/?'`
}
function mergeLines() {
  const records = mergeRecords(ran)
  const first = (line) => [metricLine(), line].filter(Boolean).join(' && ')
  const ci = (result) => `sh tools/run_state.sh set ${state.change} ci "${result} ${head}"`
  return {
    green: `git worktree prune; git worktree remove --force ${MERGE_GATES}; ${first(ci('green'))} && ${originCheck(state.repo)} && ${PINNED_GIT} fetch -q --prune origin && ${PINNED_GIT} worktree add -q --detach ${MERGE_GATES} origin/main && CHANGE=${state.change} RECORDS="${records.join(' ')}" sh ${MERGE_GATES}/tools/gates.sh merge build/pipeline/${state.change}.body.md`,
    red: first(ci('red')),
  }
}
// Whether RECORDS (this start's, ran) hold a pass of KEY at HEAD: a
// phase.NAME record is the commit, a review.KIND record "RESULT COMMIT".
function passedAt(records, key, head) {
  const [result, commit] = String(records[key] || '').split(' ')
  return key.startsWith('phase.') ? !!head && result === head : result === 'pass' && !!head && commit === head
}
// Whether RECORDS (this start's, ran) hold a check and every review of
// this start, whatever their commit or result.
function ranAll(records) {
  return ['quality', 'security', 'bench'].every((k) => !!records['review.' + k]) && !!records['phase.check']
}
// The merge gates' RECORDS words, KIND:RESULT:COMMIT, from this start's
// records alone, so no record branch code wrote in the run state reaches
// the records gate.
function mergeRecords(records) {
  return ['security', 'quality', 'bench'].map((k) => `${k}:${String(records['review.' + k] || '').split(' ').slice(0, 2).join(':')}`)
    .concat([`check:pass:${records['phase.check'] || ''}`])
    .filter((r) => /^[a-z]+:(pass|blocked):[0-9a-f]{7,40}$/.test(r))
}
// The pull request, the repository, and the branch, when the script holds
// them in their plain forms, so the merger need not read the run state.
function mergeTarget() {
  const pr = /^[0-9]+$/.test(state.pr || '') ? state.pr : ''
  const repo = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(state.repo || '') ? state.repo : ''
  const branch = /^(feature|bugfix|hotfix|release|chore)\/[a-z0-9][a-z0-9-]*$/.test(state.branch || '') ? state.branch : ''
  return pr && repo && branch ? ` Pull request ${pr} of ${repo}, branch ${branch}.` : ' Read the pull request, the repository, and the branch with the show command.'
}

const at = (key) => (state[key] || '').split(' ')
const doneAtHead = (name) => passedAt(ran, 'phase.' + name, head)
const reviewedAtHead = (kind) => passedAt(ran, 'review.' + kind, head)
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
  let result = null
  let more = ''
  for (let count = 0; ; count++) {
    result = await measured(key, () => agent(
      `${intro()} Mode: ${mode}. ${detail}${more}\nFollow your Modes section for \`${mode}\` and return the schema.${capLine(mode)}`,
      calibrate('contributor', { agentType: 'contributor', schema: withCalls(WORK), label: `contributor: ${mode}${count ? ', continued' : ''}` })), callCap(mode))
    state.pushed = keepPushed(mode, state.pushed, result)
    const step = continuation(result, result ? workLeft(result) : null, count)
    if (step.next === 'done') break
    if (step.next === 'stop') {
      stopped = `contributor (${mode}) stopped${count ? ` after ${count + 1} starts` : ''}: ${result ? result.question || result.summary : 'no result'}`
      return false
    }
    if (result && /^[0-9a-f]{7,40}$/.test(result.head || '')) head = result.head
    const why = result ? 'reached its cap' : 'returned no result'
    note(`contributor (${mode}) ${why}${result ? `, left: ${step.left.join('; ')}` : ''}; continued`)
    queue(`sh tools/run_state.sh note ${state.change} overrun "contributor ${mode} start ${count + 1} ${why} and was continued"`, head)
    more = `\nThis continues a start that ${result ? `reached its cap. It left:\n- ${step.left.join('\n- ')}` : 'returned no result, having reached its turn ceiling'}\nResume from the branch's commits, tasks.md, and the run state; redo nothing already committed or recorded.${mode === 'package' || mode === 'push' ? `\nWhen this mode's push already ran, which a second push refuses, return \`sh tools/run_state.sh get ${state.change} pushed\` as \`pushed\`.` : ''}`
  }
  head = result.head
  note(`contributor (${mode}): ${result.summary}`)
  return result
}

// Check, the quality and security reviews in parallel, and benchmark until
// all pass at one commit; whatever blocks goes back to the contributor while
// mayFix allows, both reviews' findings in one round.
async function verify(fixes = true) {
  const passed = await rounds(fixes)
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

// The verdict line of tools/run_state.sh check, which the checker returns
// verbatim: passed or failed (a refusal is a failure the contributor fixes)
// at a commit; killed, superseded, and running mean the check did not
// finish, and any other line is none. The words are the script's verdicts,
// which tools/tools_test.sh compares with RERUN_WORDS.
const RERUN_WORDS = /^(killed|superseded|running|none)$/
function checkVerdict(line) {
  const text = String(line || '').trim().replace(/^run_state: /, '')
  let m = /^check: every stage passed at ([0-9a-f]{7,40})(;|$)/.exec(text)
  if (m) return { kind: 'passed', at: m[1], stage: '', log: '' }
  m = /^check: stage ([a-z0-9-]+) (failed|killed|superseded) at ([0-9a-f]{7,40}); read ([A-Za-z0-9_./-]+)$/.exec(text)
  if (m) return { kind: m[2], at: m[3], stage: m[1], log: m[4] }
  m = /^check: refused: (.+)$/.exec(text)
  if (m) return { kind: 'failed', at: head, stage: 'refused', log: m[1] }
  m = /^check: still running at ([0-9a-f]{7,40})/.exec(text)
  if (m) return { kind: 'running', at: m[1], stage: '', log: '' }
  return { kind: 'none', at: '', stage: '', log: '' }
}
const sameCommit = (a, b) => COMMIT.test(a || '') && COMMIT.test(b || '') && (a.startsWith(b) || b.startsWith(a))
let reruns = 0
let rerunWhy = ''

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
function qualityReview(scope, more) {
  return agent(`${intro()} Review the committed diff and return the findings.${more || scope}${capLine('quality')}`,
    calibrate('quality', { agentType: 'quality-reviewer', schema: withCalls(QUALITY), phase: 'Quality', label: more ? 'quality-reviewer: continued' : 'quality-reviewer' }))
}
function securityReview(more) {
  return agent(more
    ? `${intro()} The last security review did not complete.${more} Run it, every sub-task inline, and return the result.${capLine('security')}`
    : `${intro()} Run the security review on the committed diff and return the result.${capLine('security')}`,
  calibrate('security', { agentType: 'security-reviewer', schema: withCalls(SECURITY), phase: 'Security', label: more ? 'security-reviewer: continued' : 'security-reviewer' }))
}
// What a continued review is told: the files the last start left, or the
// whole diff when it returned nothing.
const reviewMore = (r, left) => (r && left.length && left[0] !== 'the whole diff'
  ? `\nThe last start reached its cap and left these files of the diff; review only them against the rules, and return their findings:\n- ${left.join('\n- ')}`
  : '\nThe last start returned no result or did not run; review the whole committed diff.')
// A review continued while it left files or returned nothing, at most
// CONTINUES more starts, the findings of every start kept.
async function continueReview(kind, scope, first) {
  let all = first
  let r = first
  for (let count = 0; ; count++) {
    const step = continuation(r, r ? reviewLeft(r) : null, count)
    if (step.next !== 'continue') return all
    note(`${kind} review ${r ? 'reached its cap' : 'returned no result'}; continued`)
    const more = reviewMore(r, step.left)
    r = await measured(kind, () => (kind === 'quality' ? qualityReview(scope, more) : securityReview(more)), callCap(kind))
    all = r && all && (!('ran' in all) || all.ran) ? combineReviews(all, r) : r || all
  }
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
  const run = { quality: () => qualityReview(scope, ''), security: () => securityReview('') }
  if (kinds.length > 1) { phase('Quality'); phase('Security') } else phase(kinds[0] === 'quality' ? 'Quality' : 'Security')
  const reviewCap = (r) => callCap('ran' in r ? 'security' : 'quality')
  const results = await measured(kinds.length > 1 ? 'reviews' : kinds[0], () => parallel(kinds.map((k) => run[k])), reviewCap)
  const got = {}
  kinds.forEach((k, i) => { got[k] = results[i] })
  // A review that left files or returned nothing is continued over what it
  // left; a security review never passes with anything left.
  for (const k of kinds) got[k] = await continueReview(k, scope, got[k])
  const messages = []
  const files = []
  let commit = head
  if (kinds.includes('security')) {
    const s = got.security
    if (!s || reviewLeft(s).length) { stopped = `the security review did not ${s && s.ran ? `cover ${reviewLeft(s).join(', ')}` : 'run'}; it cannot be skipped`; return null }
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
    if (reviewLeft(q).length) { stopped = `the quality review did not cover ${reviewLeft(q).join(', ')}`; return null }
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

async function rounds(fixes = true) {
  for (;;) {
    let blocked = ''
    if (!doneAtHead('check')) {
      phase('Check')
      // The check the workflow last recorded: stage records count only at
      // it, so a record at the head that no workflow record backs runs again.
      const backed = COMMIT.test(state['phase.check'] || '') ? state['phase.check'] : ''
      const how = backed ? ` The last check the workflow recorded passed at ${backed}: run \`sh tools/run_state.sh check ${state.change} ${backed}\`.` : ''
      const again = rerunWhy ? ` The last check did not finish (${rerunWhy}); run it again: a check still running at this commit is rejoined.` : ''
      const c = await measured('check', () => agent(`${intro()}${figuresFirst()} Run the checks and report.${how}${again}${capLine('checker')}`, calibrate('checker', { agentType: 'checker', schema: withCalls(CHECK) })), callCap('checker'))
      if (!c) { stopped = 'the checker returned no result'; return false }
      // Only a pass or a failure at the head is a result: a check that did
      // not finish, or one at another commit, runs again with no fix round.
      const v = checkVerdict(c.verdict)
      if (RERUN_WORDS.test(v.kind) || !sameCommit(v.at, head)) {
        const where = v.stage ? ` at stage ${v.stage}, log ${v.log}` : ''
        const why = v.kind === 'none' ? 'no verdict line' : `${v.kind}${where} at ${v.at}${sameCommit(v.at, head) ? '' : `, not the head ${head}`}`
        if (++reruns > RERUNS) { stopped = `the check did not finish at ${head} in ${reruns} starts: ${why}`; return false }
        rerunWhy = why
        note(`check rerun ${reruns} of ${RERUNS}, no fix round: ${why}`)
        continue
      }
      reruns = 0
      rerunWhy = ''
      const passed = v.kind === 'passed'
      verdict('check', passed)
      note(`check at ${v.at}: ${passed ? 'passed' : `failed at stage ${v.stage}; ${v.log}`}`)
      if (passed) {
        phaseDone('check', head)
        budgetAtCheck(c.budget, head)
        benchSameAt = c.bench_same ? head : ''
        benchReport = c.bench_report || []
      } else blocked = v.stage === 'refused' ? `The check refused to run: ${v.log}` : `The stage ${v.stage} failed; its log, ${v.log}:\n${c.log_excerpt || ''}`
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
          `${intro()} The check's measurement differs from main's recorded figures, or was not compared:\n- ${benchReport.join('\n- ') || 'no comparison'}\nCompare with main and return the result. Build the base with PREFIX=$PWD/tmp/.toolchain SPINEL_CACHE_DIR=$PWD/build/spinel-cache, as your step 1 says.${capLine('bench')}`,
          calibrate('bench', { agentType: 'benchmark', schema: withCalls(BENCH) })), callCap('bench'))
        if (!b) { stopped = 'the benchmark agent returned no result'; return false }
        verdict('bench', !b.blocking.length)
        note(`benchmark at ${b.head}: ${b.report.join('; ')}`)
        reviewed('bench', !b.blocking.length, b.head, { blocking: b.blocking.length })
        if (b.blocking.length) blocked = `Blocking regressions:\n- ${b.blocking.join('\n- ')}`
      }
    }
    if (!blocked) return true
    if (!fixes) { stopped = `blocked at ${head} on resume, where no fix can be pushed: ${blocked.split('\n')[0]}`; return false }
    if (!mayFix()) { stopped = `still blocked after ${rework} fix rounds: ${blocked.split('\n')[0]}`; return false }
    phase('Implement')
    if (!(await contributor('fix', blocked))) return false
  }
}

phase('Resume')
const resume = await agent(
  `Prepare the delivery of one change. Input: ${JSON.stringify(input)}.
1. \`git fetch -q origin\`. The change name is input.change, or an existing change under openspec/changes/ that the brief names, or a kebab-case name of 2 to 5 words derived from the brief.
2. The branch is input.branch, or the one in build/pipeline/<change>.json, or <type>/<change> with the type from CLAUDE.md's Branch naming. Check it out when it exists locally or on origin; otherwise run \`sh tools/run_state.sh restore <branch>\` and check it out when that exited 0 (it created the branch from the backup of a reclaimed run's commits); otherwise create it from origin/main, which needs a clean tree (stop with the reason when it is not).
3. \`make doctor\`; run \`make toolchain\` when it fails and stop when that fails too.
4. Run \`sh tools/run_state.sh init <change> <branch>\`, then \`sh tools/run_state.sh trusted <change>\`, and return the second command's output verbatim as state_json, with \`git rev-parse --short=12 HEAD\` as head.
5. Run \`sh tools/run_state.sh plan-needed <change>\` and return its one line verbatim as plan; its exit 1 means not needed, not a failure.${capLine('resume')}`,
  calibrate('resume', { schema: RESUME, label: 'resume' }))
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
// name gives the scouts and the contributor nothing to work from, so they
// read the queue item naming the change in docs/queue.md themselves: the
// item never passes through a model's output.
const planLine = resume && typeof resume.plan === 'string' ? resume.plan.split('\n')[0] : ''
const request = typeof input.brief === 'string' && input.brief.trim() !== '' && input.brief.trim() !== state.change
const brief = request ? input.brief : `the item of docs/queue.md that names \`${state.change}\`, read there as written (when no item names it, the existing OpenSpec change)`
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
    `${intro()} Plan the queue for this delivery. Brief: ${input.brief || 'the existing OpenSpec change'}.${capLine('planner')}`,
    calibrate('planner', { agentType: 'planner', schema: withCalls(PLAN) })), callCap('planner'))
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
        `List the areas of docs/codebase-map.md (by number and name) whose files this change edits, as the brief says, at most ${MAX_AREAS}: ${brief}. ${input.areas ? 'Requested areas: ' + input.areas.join(', ') + '.' : ''} Leave out an area the change only reads, and any finding the change only records in docs/backlog.md or other bookkeeping: those reach the contributor through the plan notes, never a scout. For each area, a pack under tmp/scout/ is current when its Commit: is origin/main or \`git diff --quiet <its commit> origin/main -- <its Files read>\` passes; list current packs by path and the areas still needing one, with the question a contributor needs answered about the existing code it edits or hooks into (callers, registration, tests), never about code the change will add, which does not exist yet; an area whose only edits are new files needs no pack.${capLine('areas')}`,
        calibrate('areas', { schema: withCalls(SCOUT_PLAN), label: 'scout plan' })), callCap('areas'))
      const room = plan ? Math.max(0, MAX_AREAS - plan.current.length) : 0
      const needed = plan ? plan.needed.slice(0, room) : []
      if (plan && plan.needed.length > room) note(`not scouted, beyond ${MAX_AREAS} areas: ${plan.needed.slice(room).map((n) => n.area).join(', ')}`)
      const fresh = plan ? await measured('scout', () => parallel(needed.map((n) => () =>
        agent(`Area: ${n.area}. Question: ${n.question}. The change, for scope only: ${brief}. Write the pack and return its path.${capLine('scout')}`, calibrate('scout', { agentType: 'scout', schema: withCalls(PACK), label: `scout: ${n.area}` })))), callCap('scout')) : []
      packs = (plan ? plan.current : []).concat(fresh.filter(Boolean).map((p) => p.pack))
      note(`scout packs: ${packs.join(', ') || 'none'}`)
    }
    phase('Implement')
    const done = await contributor('implement', `Brief: ${brief}. Scout packs: ${packs.join(', ') || 'none'}.${planNotes.length ? `\nPlan notes:\n- ${planNotes.join('\n- ')}` : ''}`)
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
    // A resume past the push holds no check or review of this start, and
    // the run state's could be branch-written: they run again at the head.
    // A start that ran them all keeps its records, though the package step
    // committed after them: the merge gates' settled_at allows that
    // records-only diff. The resume runs no fix round, since a fix commit
    // could not be pushed; a blocking finding stops the run.
    if (!ranAll(ran)) {
      note('resumed past the push: the check and the reviews run again at the head')
      if (!(await verify(false)) && !stopped) stopped = `the check or a review did not pass at ${head} on resume`
      phase('Merge')
    }
    for (; !stopped;) {
      // GitHub matches the expected head against the full sha, and only the
      // head the push recorded is the one the reviews and gates covered.
      const pushed = pushedHead(state.pushed, head)
      if (!pushed) { stopped = `the pushed head ${state.pushed || 'none'} is not a full sha beginning with the reported head ${head}`; break }
      const lines = mergeLines()
      const m = await measured('merge', () => agent(
        `${intro()}${mergeTarget()} The pushed head is ${pushed}. Wait for CI at it${waits ? ' (it was still running when you last returned; keep waiting)' : ''}, and merge the pull request if CI is green and every merge gate passes.\nThe green line: \`${lines.green}\`\nThe red line: \`${lines.red}\`\nTool calls: at most ${FIXED_CAPS.merger} in this start when CI passes within your first two waits, and 2 more for each later wait.`,
        calibrate('merger', { agentType: 'merger', schema: withCalls(MERGE) })), mergerCap)
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

// The close, one retrospective start in every run: it runs the records left
// since the last flush with this start's own phase lines and the metric
// line, looks back when the change merged and no retrospective ran yet,
// says whether a periodic review is due, and writes the report. The line
// and the summary are built from the same figures at once, so once the line
// has run the run state's totals equal the summary's; this start's own cost
// is the one figure recorded nowhere. When the start did not record, its
// lines go to one record start, as a run whose hooks still load the old
// profile needs. The periodic review, when due, runs after it; what the
// reviews find waits in the run state for the next change's planner.
// A stopped run keeps its backup on origin for a resume; only the user
// abandons a run, which deletes it.
if (stopped && !state.merged && CHANGE.test(state.change || '')) note(`the backup of an unpushed branch stays on origin for a resume; \`sh tools/run_state.sh abandon ${state.change}\` deletes it when the run will not resume`)
const looking = !stopped && Boolean(state.merged) && !state['phase.retro']
phase('Close')
// A line the close profile refuses (none is left after verify()'s flush,
// but a stop could leave one) goes through the record agent first.
if (pending.some((l) => !CLOSABLE.test(l)) && !(await flush())) note(stopped)
const closeAt = state.merged || head
const own = CHANGE.test(state.change || '') && COMMIT.test(closeAt || '')
  ? (looking ? ['retro', 'report'] : ['report']).map((n) => phaseLine(n, closeAt)) : []
const left = pending.splice(0)
const records = left.concat(own, [metricLine()].filter(Boolean)).join(' && ')
const figures = summary()
const close = await measured('close', () => agent(
  `Change \`${state.change || input.change || 'unknown'}\`${state.branch ? ` on branch \`${state.branch}\`` : ''}. ${state.merged ? `It merged as ${state.merged}.` : 'It did not merge.'} ${looking ? 'Run the retrospective steps, then the report steps.' : 'Skip the retrospective steps; run the report steps.'}\nThe record line: ${records ? `\`${records}\`` : 'none; skip that step and return recorded true.'}\nThe run's figures: ${figures}.\nWorkflow notes:\n- ${notes.join('\n- ')}\n${stopped ? 'The run stopped: ' + stopped : 'The run finished.'}${capLine('close')}`,
  calibrate('close', { agentType: 'retrospective', schema: withCalls(CLOSE) })), callCap('close'))
if (close && looking) {
  state['phase.retro'] = closeAt
  note(`retrospective: ${close.proposals.map((x) => `${x.proposal} (${x.evidence})`).join('; ') || 'no proposal'}; ${close.review_due || 'review-due not read'}`)
}
if (records && (!close || !close.recorded)) {
  note(`the closing start did not record the run${close && close.record_output ? `: ${close.record_output}` : ''}; one record start runs its lines`)
  pending.push(...left, ...(close ? own : []))
  if (!(await flush(true))) note(stopped)
}
let periodic = ''
if (close && looking && close.due) {
  phase('Review')
  let p = null
  try {
    p = await measured('review', () => workflow({ scriptPath: '.claude/workflows/periodic-review.js' }, { change: state.change }))
  } catch (e) {
    note(`the periodic review failed to start: ${e.message}`)
  }
  // The periodic review records its own overrun notes; the workflow notes
  // them beside its result.
  for (const text of (p && p.over) || []) note(`over the call cap: ${text}`)
  const missed = (areas) => (areas && areas.length ? `, partial: not reviewed ${areas.join(', ')}` : '')
  if (!p || !p.ran) stopped = 'the periodic security review did not run; run /review'
  else periodic = `periodic review: security ${p.security.length} finding(s), ${p.security_blocking} blocking (to the front of the queue)${missed(p.security_not_reviewed)}; quality ${p.quality_blocking.length} blocking, ${p.quality_advisory} advisory${missed(p.quality_not_reviewed)}${p.recorded === false ? '; the results were not recorded in the run state' : ''}`
  if (periodic) note(periodic)
}
const after = `${periodic ? `\n- Periodic review: ${periodic.replace(/^periodic review: /, '')}` : ''}${stopped && looking ? `\n- Stopped after the close: ${stopped}` : ''}`
return close ? `${close.report}${after}` : `No report; notes:\n${notes.join('\n')}${stopped ? '\nStopped: ' + stopped : ''}`
