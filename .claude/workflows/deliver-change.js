export const meta = {
  name: 'deliver-change',
  description: 'Deliver one change to main through fixed phases: plan, contributor, checker, security review, benchmark, package, CI and merge, close (records, retrospective, and report in one start); the sprint-end review is sprint-planning\'s',
  whenToUse: 'Every change to this repository, started by /deliver with a change name or a brief; it resumes from build/pipeline/CHANGE.json',
  phases: [
    { title: 'Resume', detail: 'branch, toolchain, and the run state' },
    { title: 'Plan', detail: 'planner: the next queue from the metrics history; security findings first' },
    { title: 'Implement', detail: 'contributor: propose and apply, committing early, then its own quality review before the archive' },
    { title: 'Check', detail: 'the fast stages through make in a start that runs only the check lines; the checker reads a failed stage\'s log; CI runs the rest' },
    { title: 'Security', detail: 'security reviewer on the committed diff; never skipped' },
    { title: 'Benchmark', detail: 'allocations and rounds against the figures recorded for main; the agent against main only when they differ' },
    { title: 'Package', detail: 'contributor: archive, gates, pr.md, one push, the pull request open-pr opens' },
    { title: 'Merge', detail: 'merger: wait for CI, red back to the contributor; main\'s merge gates, squash with the trailer, verify main' },
    { title: 'Close', detail: 'retrospective: the last records, the proposals, the budget and review-due lines, and the report, in one start' },
  ],
}

// args: { change?, brief?, branch?, records?: 'skip' }, or a string that
// is a change name or a brief. The run state, written only by
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
// that ran the workflow sees, /deliver adds with tools/run_state.sh usage, and
// each start's tier-weighted tokens with tools/run_state.sh tokens. The
// run state's phase.* and review.* lines and the figures are the script's
// own: it builds each command from a schema-checked result. One agent, the
// runner, which reads nothing else, runs the queued lines with the metric
// line (flush) at the end of verify() only when a check or review record is
// among them, since the pre-push and merge gates read those and no other
// agent may write them; the closing start runs every other line at the
// end, where the package, CI, and merge phases wait (a resume reads pushed,
// pr, and merged instead), under the guard's close profile, which allows
// only the phases no merge gate reads. The check's run start and the merger run the
// metric line first, so a fix round is counted before its check.
// tools/agent_guard.sh keeps the other agents off the phase and review
// commands, and the merger's records gate compares the file with what the
// script received. Each start's model tier and effort come from
// CALIBRATION, and the run state records them beside its figures.
// Only the arguments above are kept: a field passed beside them, such as a
// chat message, never reaches a start's prompt, which carries the brief or
// the resume brief only.
const ARG_KEYS = ['change', 'brief', 'branch', 'records']
function startInput(raw) {
  const given = typeof raw === 'string' ? { brief: raw } : (raw || {})
  const kept = {}
  for (const key of ARG_KEYS) if (given[key] !== undefined) kept[key] = given[key]
  return kept
}
const input = startInput(args)
const ROUNDS = 3
// Merger calls that may find CI still running (each waits up to 30
// minutes) before the run stops as stalled.
const WAITS = 4
// Checker starts in a row that may end without a verdict at the head (a
// killed, superseded, escaped, or unfinished check) before the run stops;
// such a start is rerun with no fix round.
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
// The check runs each implement or fix start made after its first, summed
// across starts (contributor-self-check, metric.self_fix): the rework a
// contributor fixed in its own session, which no fix round counts.
let selfFix = 0
// The closing loop's figures (closing-loop): the advisories it offered that
// the reviews confirmed fixed, and those left, null until the loop ran or
// was skipped; recorded as metric lines beside, not in, the rework rounds.
const closingFigures = { closed: null, left: null }
let closingLoop = false
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
// The review fix rounds this start began on a resume past the push (at
// most one a run, with the run state's review_fixes; resumeFix).
let reviewFixRounds = 0
let planned = null
let ciMinutes = null
// The merger's calls waiting on CI over its starts, two per wait (the
// wait and the read after it); null until a merger returned.
let ciWaitCalls = null
const SIZES = ['small', 'medium', 'large']
let estimate = ''
// Critical routing (docs/goals.md, Critical changes): the rule letter a to e the
// plan named, and whether a contributor start of this run escalated.
let critical = ''
let escalated = false
// The contributor's quality review (card rule 10), ADDED/FIXED/RECORDED as
// the implement start that finished the tasks reported it, '' until one
// did; kept as metric.quality_review, which a restart reads back.
let qualityReview = ''
// Tool calls per agent start. CALL_CAPS holds a start's cap at a medium
// estimate, from the history's calls per phase; CALL_SCALE scales it by the
// estimate, rounded up, the medium figure applying while no estimate exists
// (the planner's start). FIXED_CAPS holds the starts whose work does not
// grow with the change; the merger's is its work,
// fixed whatever CI does, plus 2 for every CI wait (mergerCap), so a
// first-pass green CI that waits long overruns nothing (merge-cap-ci-wait). The prompt states the cap
// (capLine) and the agent stops at it; a start that reports more calls is
// noted and leaves an overrun note for the planner (measured). The hard
// ceiling is each agent file's maxTurns, its largest cap at a large
// estimate plus a return margin of 5 turns (the merger's: its work cap, 2
// for each of the seven waits its 30 minutes hold, and the margin), so a
// start
// whose capped calls take one turn each can still commit, back up, and
// return the schema; tools/tools_test.sh compares them with these lines.
// Implement and fix hold the contributor's own check of its head, up to
// three runs with their fixes, about 18 calls (contributor-self-check).
const CALL_CAPS = { planner: 20, implement: 110, fix: 60, closing: 40, package: 30, prtext: 20, push: 15, moved: 15, body: 12, wait: 6, checker: 20, security: 35, bench: 20, close: 25 }
const CALL_SCALE = { small: 0.5, medium: 1, large: 1.5 }
const FIXED_CAPS = { resume: 12, record: 3, merger: 10, run: 8 }
const sizeWord = () => (SIZES.includes(estimate) ? estimate : 'medium')
const callCap = (kind) => (kind in FIXED_CAPS ? FIXED_CAPS[kind] : Math.ceil(CALL_CAPS[kind] * CALL_SCALE[sizeWord()]))
const capLine = (kind) => `\nTool calls: at most ${callCap(kind)} in this start (${kind in FIXED_CAPS ? 'a fixed cap' : `the ${kind} cap at ${SIZES.includes(estimate) ? `the ${estimate} estimate` : 'the medium figure, with no estimate yet'}`}). Count them; on reaching the cap, stop and return the schema with what is done, saying the cap stopped you.`
// The merger's waits are 3, 4, then 5 minutes (.claude/agents/merger.md), so
// the minutes it waited give its waits, and every wait 2 calls of its cap.
const waitsOf = (r) => { const w = Number(r && r.waited); return w > 0 ? (w <= 3 ? 1 : w <= 7 ? 2 : 2 + Math.ceil((w - 7) / 5)) : 0 }
const mergerCap = (r) => FIXED_CAPS.merger + 2 * waitsOf(r)
// The model tier and reasoning effort of each kind of agent start, as
// TIER/EFFORT, set from the history's figures (docs/goals.md, Calibration).
// The tier is agent, the tier the model: line of the agent's file names, the
// only place a tier is named (tools/tools_test.sh compares them), whichever
// tier that is, or session, the session's model; the effort is low, medium,
// high, or session, none passed. One kind moves at a time, kept only when the
// first-pass rates and the rework do not get worse over the next runs; the
// security reviewer never moves.
// calibrate gives a start its options and records its profile, which the
// metric line stores as calib.KIND beside the tokens, calls, and verdicts.
const CALIBRATION = { resume: 'agent/low', planner: 'session/session', contributor: 'agent/high', checker: 'agent/low', quality: 'session/session', security: 'session/session', bench: 'agent/low', record: 'agent/low', merger: 'agent/low', close: 'agent/high' }
// A profile's form, the one pattern restoreCalibration and the metric line
// accept and tools-test reads (an effort added here only).
const PROFILE = /^(agent|session)\/(low|medium|high|session)$/
const calibrated = {}
// The rule and path of a critical value: the plan's whole value ("b tools/x.sh"),
// or the "critical LETTER PATH" the planner wrote in a queue item's parenthesis;
// null for anything else (two paths, prose, a letter outside a to e).
function criticalOf(text) {
  const s = String(text || '').trim()
  const m = /^([a-e]) ([A-Za-z0-9_./-]+)$/.exec(s) || /, critical ([a-e]) ([A-Za-z0-9_.\/-]+)\)/.exec(s)
  return m ? { rule: m[1], path: m[2] } : null
}
// What a restart carries on of the routing: the rule and the escalation.
function restoreRouting(st) {
  critical = /^[a-e]$/.test(st['metric.critical'] || '') ? st['metric.critical'] : ''
  escalated = st['metric.escalated'] === '1'
}
// The rule letter that labels this run critical: the plan's, or e for a large
// estimate. It is a label for the history and the calibration comparisons
// only: by the user's decision (docs/goals.md, Calibration) no contributor
// start runs on the session's model, whatever the rule.
function criticalRule() { return critical || (estimate === 'large' ? 'e' : '') }
function calibrate(kind, opts) {
  const profile = CALIBRATION[kind]
  calibrated[kind] = profile
  const effort = profile.split('/')[1]
  return effort === 'session' ? opts : Object.assign({}, opts, { effort })
}
// The first start that fails its work is noted in the run state, once, so the
// history keeps the signal; the later contributor starts keep their profile.
function escalate(why) {
  if (escalated) return
  escalated = true
  note(`contributor start failed its work, noted as an escalation: ${why}`)
  queue(`sh tools/run_state.sh note ${state.change} escalation "${why}"`, head)
}
// The self-check of the last implement or fix start, { mode, said }, kept
// until the next check that finishes at the head reads it (compareSelfCheck);
// null after a start of another mode or a settled round (settleRound). A
// match that check contradicts by failing a stage is noted
// self-check-mismatch and escalates; a mismatch escalated when returned. Of
// the refusals only those of the contributor's own tree count, as the stage
// refused (CONTRIBUTOR_REFUSAL): one of the environment, such as CHECK_JOBS,
// contradicts nothing it said.
let selfCheck = null
const CONTRIBUTOR_REFUSAL = /^(tracked files differ from HEAD|untracked files under )/
function compareSelfCheck(v) {
  const said = selfCheck
  selfCheck = null
  if (!said || said.said !== 'match' || v.kind !== 'failed') return
  if (v.stage === 'refused' && !CONTRIBUTOR_REFUSAL.test(v.log || '')) return
  const what = `contributor ${said.mode} self-check said match, the check failed at stage ${safeText(v.stage)}`
  note(what)
  queue(`sh tools/run_state.sh note ${state.change} self-check-mismatch "${what}"`, head)
  escalate('a self-check the check contradicted')
}
// A check that finished at the head: its first-pass verdict, its report
// note, and the comparison with the last self-check; true when it passed.
function finishCheck(v) {
  const passed = v.kind === 'passed'
  verdict('check', passed)
  note(`check at ${v.at}: ${passed ? 'passed' : `failed at stage ${v.stage}; ${v.log}`}`)
  compareSelfCheck(v)
  return passed
}
// A restart carries on the profiles an earlier start recorded as
// metric.calib.KIND, for the kinds this start has not used yet; a value
// outside the table's form is dropped.
function restoreCalibration(saved, used) {
  for (const key of Object.keys(saved)) {
    const m = /^metric\.calib\.([a-z]+)$/.exec(key)
    if (m && !(m[1] in used) && PROFILE.test(saved[key])) used[m[1]] = saved[key]
  }
  return used
}

const STATUS = { type: 'string', enum: ['done', 'stopped'] }
const WORK_STATUS = { type: 'string', enum: ['done', 'partial', 'stopped'], description: 'partial: the cap stopped you with the work committed and backed up' }
const HEAD = { type: 'string', description: 'git rev-parse --short=12 HEAD at the end' }
const LANE_HEAD = { type: 'string', description: 'the head line of sh tools/lane_facts.sh CHANGE at the end' }
const LINES = { type: 'array', items: { type: 'string' } }
const RESUME = {
  type: 'object',
  properties: {
    status: STATUS, change: { type: 'string' }, branch: { type: 'string' }, head: HEAD,
    state: { type: 'object', additionalProperties: { type: 'string' }, description: 'the JSON object tools/run_state.sh trusted printed, as an object: its keys and string values, nothing else' },
    plan: { type: 'string', description: 'the output of tools/run_state.sh plan-needed, verbatim: its one line' },
    reason: { type: 'string' },
  },
  required: ['status', 'change', 'branch', 'head', 'state'],
}
// The implement start's one line on where the change's locations come
// from, the scout and its area plan dropped (scout-drop): the paths and
// lines the change edits, which the planner's notes give, else its queue
// entry or the brief. tools/tools_test.sh reads it.
const LOCATIONS = 'Locations: take the paths and lines the change edits from the plan notes, else from its queue entry or the brief, and start reading there.'
const WORK = {
  type: 'object',
  properties: {
    status: WORK_STATUS, head: LANE_HEAD, summary: { type: 'string' }, self_check: { type: 'string', enum: ['match', 'mismatch'], description: 'mismatch when the self-check found a test, document, or brief item still missing' }, question: { type: 'string' }, assumptions: LINES, pr: { type: 'integer' },
    remaining: { ...LINES, description: 'with status partial: each task or step left, one line each' },
    pushed: { type: 'string', description: 'after a push: the full sha it recorded, sh tools/run_state.sh get <change> pushed' },
    check: { type: 'string', description: 'implement and fix: the last line of your last sh tools/run_state.sh check <change>, verbatim' },
    check_runs: { type: 'integer', minimum: 0, description: 'implement and fix: how many times that check ran in this start, a wait again on exit 3 not counted' },
    quality_review: {
      type: 'object',
      description: 'implement, in the start that finishes every task of tasks.md: the quality step of card rule 10, before the archive',
      properties: { status: { type: 'string', enum: ['done'] }, added: { type: 'integer', minimum: 0 }, fixed: { type: 'integer', minimum: 0 }, recorded: { type: 'integer', minimum: 0, description: 'findings not fixed, appended to docs/findings/<change>.md with their reason; fixed plus recorded equals added' } },
      required: ['status', 'added', 'fixed', 'recorded'],
    },
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
    moved: { type: 'string', description: 'the last line tools/run_state.sh moved printed, verbatim, when the prompt asks for it; empty otherwise' },
  },
  required: ['passed', 'head', 'stages', 'verdict'],
}
// The check's run start (checkRunTask): the lines' last lines, nothing read.
const CHECK_RUN = {
  type: 'object',
  properties: {
    verdict: CHECK.properties.verdict, bench_same: CHECK.properties.bench_same, bench_report: LINES,
    budget: CHECK.properties.budget, moved: CHECK.properties.moved,
  },
  required: ['verdict'],
}
const FIXED_IN_PLACE = { ...LINES, description: 'each finding the input lists as fixed in place that the fix removed, verbatim as listed; empty when the input lists none' }
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
  properties: { head: HEAD, blocking: LINES, advisory: LINES, not_reviewed: NOT_REVIEWED, fixed_in_place: FIXED_IN_PLACE },
  required: ['head', 'blocking', 'advisory'],
}
const SECURITY = {
  type: 'object',
  properties: { ran: { type: 'boolean' }, head: HEAD, findings: { type: 'array', items: FINDING }, not_reviewed: NOT_REVIEWED, fixed_in_place: FIXED_IN_PLACE },
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
    step: { type: 'string' }, log_excerpt: { type: 'string' }, checks: { ...LINES, description: 'each check run of the head, oldest first: workflow, name, status, conclusion, the workflow the path of the workflow run of the head holding the check (actions_list, by check suite), or - on green; one form for every result' },
    body_only: { type: 'boolean', description: 'CI is red only on the scan check, and its log names the pull request title or body, no commit or added line' },
    main_moved: { type: 'boolean', description: 'main moved under the pull request: it conflicts with main, or GitHub refused the merge because the branch is behind main or conflicts with it' },
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
    notes: { ...LINES, description: 'for the contributor: findings the change only writes to docs/findings/CHANGE.md, and bookkeeping' },
    files: LINES,
    estimate: { type: 'string', enum: SIZES, description: 'the size this change is estimated at' },
    critical: { type: 'string', pattern: '^([a-e] [A-Za-z0-9_./-]+)?$', description: 'empty, or a rule letter a to e of docs/goals.md, Critical changes, then a space and the path that makes the change critical' },
    records: { type: 'string', enum: ['apply', 'skip'], description: 'skip when the brief excludes the planning records (history) from this change\'s package step' },
  },
  required: ['decisions', 'security_first', 'notes', 'files', 'estimate'],
}
const CLOSE = {
  type: 'object',
  properties: {
    proposals: { type: 'array', items: { type: 'object', properties: { proposal: { type: 'string' }, evidence: { type: 'string' } }, required: ['proposal', 'evidence'] } },
    review_due: { type: 'string', description: 'the line tools/run_state.sh review-due printed, empty without the retrospective steps' },
    due: { type: 'boolean' },
    recorded: { type: 'boolean', description: 'the record line printed no refused: N' },
    refused: { type: 'array', items: { type: 'integer' }, description: 'each N of a refused: N the record line printed, in order' },
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
// findings and the confirmed in-place fixes of both without duplicates, a
// list only one start returned kept (a continued start is never given the
// in-place list, so it returns no fixed_in_place of its own).
function combineReviews(a, b) {
  if (!a || !b) return b || a
  const out = { ...b }
  for (const key of ['findings', 'blocking', 'advisory', 'fixed_in_place']) {
    if (!Array.isArray(a[key]) && !Array.isArray(b[key])) continue
    const seen = new Set()
    const both = (Array.isArray(a[key]) ? a[key] : []).concat(Array.isArray(b[key]) ? b[key] : [])
    out[key] = both.filter((f) => { const k = JSON.stringify(f); return seen.has(k) ? false : seen.add(k) })
  }
  return out
}
// The pull request number a package step returned, '' when none: open-pr
// opened no pull request from the pushed pr.md (tools/open_pr.sh wait
// failed), and the run stops before the merger starts on none.
function packagedPr(result) {
  const pr = String((result && result.pr) || '')
  return /^[0-9]+$/.test(pr) ? pr : ''
}
// The full sha the push recorded, kept only when it is 40 digits beginning
// with the head the contributor reported; '' otherwise, which stops the
// merge before the merger starts.
function pushedHead(pushed, head) {
  const full = String(pushed || '')
  return /^[0-9a-f]{40}$/.test(full) && /^[0-9a-f]{7,40}$/.test(head || '') && full.startsWith(head) ? full : ''
}
// The contributor modes that push (a body fix pushes pr.md as a CI fix),
// one list for keepPushed and the continuation's pushed hint.
const PUSHING = ['package', 'push', 'body']
// The pushed sha after one start of a pushing mode: the start's own when it
// reported one, else the one kept from an earlier start, so a start capped
// after its push keeps it when the continuation, refused a second push,
// reports none.
function keepPushed(mode, pushed, result) {
  return PUSHING.includes(mode) && result && result.pushed ? result.pushed : pushed
}
// The line a continued start of a pushing mode gets, so it returns the
// recorded sha instead of retrying a push the second time refuses.
function pushedHint(mode, change) {
  return PUSHING.includes(mode) ? `\nWhen this mode's push already ran, which a second push refuses, return \`sh tools/run_state.sh get ${change} pushed\` as \`pushed\`.` : ''
}
// The step before the merge from the run state: merge once the push and
// the pull request number are both recorded; wait when only the push is,
// since a second push is refused: the contributor's wait mode runs
// tools/open_pr.sh wait alone, committing and pushing nothing; package
// when nothing was pushed.
function packageStep(state) {
  if (!(state && state.pushed)) return 'package'
  return /^[0-9]+$/.test(String(state.pr || '')) ? 'merge' : 'wait'
}
// A finding as the text of a run state note: only the characters a
// double-quoted shell word keeps as written, at most 400, so the note line
// stays one the closing start's profile runs (CLOSABLE).
function noteText(text) {
  return String(text || '').replace(/[^A-Za-z0-9 .,:;()/_+=#%'?*@-]/g, ' ').replace(/ +/g, ' ').trim().slice(0, 400)
}
// Whether a red CI is stale: the merger lists every check run of the head
// oldest first, as "workflow, name, status, conclusion", the workflow being
// the run's file under .github/workflows/, and the last run of every check
// of every workflow file passed, so each failed run was superseded by a
// green run of the same check of the same file (a scan re-run by a body
// edit). A check name alone could be a job of a workflow the branch added,
// so an entry naming no workflow file leaves the red standing. A name may
// hold commas (spin (ubuntu, 4)): the workflow is the first field, the
// status and conclusion the last two, the name all between.
function staleRed(checks) {
  const last = {}
  for (const c of checks || []) {
    const parts = String(c).split(',').map((s) => s.trim().toLowerCase())
    if (parts.length < 4) return false
    const [workflow, status, conclusion] = [parts[0], parts[parts.length - 2], parts[parts.length - 1]]
    const name = parts.slice(1, -2).join(', ')
    if (!/^[.]github\/workflows\/[a-z0-9_.-]+[.]ya?ml$/.test(workflow || '') || !name) return false
    last[`${workflow} ${name}`] = `${status} ${conclusion}`
  }
  const names = Object.keys(last)
  return names.length > 0 && names.every((n) => /^completed (success|skipped|neutral)$/.test(last[n]))
}
// The security findings that block (FINDINGS, the reviewer's): a High or
// Medium in the change at confidence 8 or above, whatever an earlier round
// rated at its location, as the hard rule of CLAUDE.md requires.
function securityBlocking(findings) {
  return (findings || []).filter((f) => f.severity !== 'Low' && f.confidence >= 8 && f.in_change)
}
// The commit a fix round's review of KIND narrows to: that of the pass
// RECORDS (this start's, ran) hold, when it is not HEAD; '' otherwise, and
// the whole branch diff is reviewed. A pass only the run state holds,
// which branch code run by the checks could have written, never narrows.
function narrowedFrom(records, kind, head) {
  const [result, commit] = String(records['review.' + kind] || '').split(' ')
  return result === 'pass' && COMMIT.test(commit || '') && commit !== head ? commit : ''
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
    .concat(Object.keys(firstPass).map((g) => `first.${g}=${firstPass[g]}`), [`rework=${rework}`, `self_fix=${selfFix}`, `extra=${extra}`, `stop=${stopKind}`])
  if (ciMinutes !== null) pairs.push(`ci_min=${Number(ciMinutes).toFixed(1)}`)
  if (Number.isInteger(ciWaitCalls)) pairs.push(`ci_wait_calls=${ciWaitCalls}`)
  if (closingFigures.closed !== null) pairs.push(`advisories_closed=${closingFigures.closed}`, `advisories_left=${closingFigures.left}`)
  if (SIZES.includes(estimate)) pairs.push(`estimate=${estimate}`)
  if (planned !== null) pairs.push(`planned=${planned}`)
  if (criticalRule()) pairs.push(`critical=${criticalRule()}`)
  if (escalated) pairs.push('escalated=1')
  if (qualityReview) pairs.push(`quality_review=${qualityReview}`)
  for (const k of Object.keys(calibrated)) pairs.push(`calib.${k}=${calibrated[k]}`)
  const safe = pairs.filter((p) => {
    const m = /^[a-z0-9_.-]+=(.*)$/.exec(p)
    return m !== null && (/^([0-9./]+|small|medium|large|none|rounds|[a-e])$/.test(m[1]) || PROFILE.test(m[1]))
  })
  return CHANGE.test(state.change || '') ? `sh tools/run_state.sh metric ${state.change} ${safe.join(' ')}` : ''
}
// A restart carries on the figures the run state holds.
// The held-finding notes an unmerged close recorded after the push (or,
// given kind, the unpushed-finding notes of a close before it), in order
// and without duplicates, less those a merged close already noted as late
// findings ("late-finding MERGED TEXT").
function heldFindings(noted, kind = 'held-finding') {
  const late = noted.filter((v) => v.startsWith('late-finding ')).map((v) => v.replace(/^late-finding [^ ]+ /, ''))
  const kept = []
  for (const v of noted) {
    const t = v.startsWith(kind + ' ') ? noteText(v.slice(kind.length + 1)) : ''
    if (t && !late.includes(t) && !kept.includes(t)) kept.push(t)
  }
  return kept
}
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
  selfFix = Number(state['metric.self_fix']) || 0
  extra = Number(state['metric.extra']) || 0
  lastStop = /^[a-z]+$/.test(state['metric.stop'] || '') ? state['metric.stop'] : ''
  if (/^[01]$/.test(state['metric.planned'] || '')) planned = Number(state['metric.planned'])
  if (state['metric.ci_min']) ciMinutes = Number(state['metric.ci_min'])
  if (/^[0-9]+$/.test(state['metric.ci_wait_calls'] || '')) ciWaitCalls = Number(state['metric.ci_wait_calls'])
  if (SIZES.includes(state['metric.estimate'])) estimate = state['metric.estimate']
  restoreRouting(state)
  if (/^[0-9]+$/.test(state['metric.advisories_closed'] || '') && /^[0-9]+$/.test(state['metric.advisories_left'] || '')) { closingFigures.closed = Number(state['metric.advisories_closed']); closingFigures.left = Number(state['metric.advisories_left']); closingLoop = closingFigures.closed + closingFigures.left > 0 }
  if (/^[0-9]+\/[0-9]+\/[0-9]+$/.test(state['metric.quality_review'] || '')) qualityReview = state['metric.quality_review']
  // The notes in the order they were recorded; once pushed, the package
  // step has handed the findings over.
  const noted = Object.keys(state).filter((k) => /^note\.[0-9]+$/.test(k))
    .sort((a, b) => Number(a.slice(5)) - Number(b.slice(5))).map((k) => String(state[k]))
  if (state.pushed) for (const f of findings()) handed.add(f)
  held = heldFindings(noted)
  // A close before the push handed nothing yet: its findings go back into
  // the list the package step hands over, once a resume has not pushed
  // either (a pushed one's package step handed them).
  if (!state.pushed) for (const t of heldFindings(noted, 'unpushed-finding')) addBacklog(t)
}
// The figures in one line for the closing start's prompt; the run state
// holds the same.
function summary() {
  const keys = Object.keys(usage)
  const total = (field) => keys.reduce((n, k) => n + usage[k][field], 0)
  const first = Object.keys(firstPass).map((g) => `${g}:${firstPass[g]}`).join(',') || 'none'
  return `output tokens ${Math.round(total('tokens'))}, tool calls ${total('calls')}; per phase ${keys.map((k) => `${k}=${Math.round(usage[k].tokens)}/${usage[k].calls}`).join(',') || 'none'}; first passes ${first}; rework ${rework} of ${ROUNDS + extra}, self-fix ${selfFix}${ciMinutes !== null ? `; CI ${ciMinutes} min` : ''}`
}

// The records the script writes: a phase or a review at a commit, queued as
// command lines of fixed words, commits, and counts, then run by flush().
const COMMIT = /^[0-9a-f]{7,40}$/
const CHANGE = /^[a-z0-9][a-z0-9-]*$/
// The merged commit by name: tools/run_state.sh phase resolves the word to
// the squash commit of the pull request on main, the run state's merged
// (squash_of_change), so no phase line names a sha an agent reported.
const SQUASH = 'merged'
const pending = []
function queue(line, commit) {
  if (CHANGE.test(state.change || '') && (COMMIT.test(commit || '') || commit === SQUASH)) pending.push(line)
  else note(`not recorded (change ${state.change}, commit ${commit}): ${line}`)
}
const phaseLine = (name, commit) => `sh tools/run_state.sh phase ${state.change} ${name} ${commit}`
function phaseDone(name, commit, reported = '') {
  state['phase.' + name] = commit
  ran['phase.' + name] = commit
  queue(`${phaseLine(name, commit)}${reported ? ' ' + reported : ''}`, commit)
}
// The merge, at the merged commit by name, never at the sha the merger
// reported (#185 recorded the pushed head, #169 and #188 a mistyped one):
// the reported sha rides along, so the run state notes a disagreement
// naming both values.
function mergeDone(reported) {
  state.merged = SQUASH
  phaseDone('merge', SQUASH, COMMIT.test(reported || '') ? reported : '')
}
// The close's lines: the closable queued ones, this start's own phase
// lines (the retro and report at the merged commit by name once the
// change merged, else at the head), and the metric line.
function closeLines(looking) {
  const closeAt = state.merged ? SQUASH : head
  const own = CHANGE.test(state.change || '') && (closeAt === SQUASH || COMMIT.test(closeAt || ''))
    ? (looking ? ['retro', 'report'] : ['report']).map((n) => phaseLine(n, closeAt)) : []
  return pending.splice(0).filter((l) => CLOSABLE.test(l)).concat(own, [metricLine()].filter(Boolean))
}
// One shell line that runs every record whatever an earlier one did: a
// refused line prints its refusal and refused: N, its position, and costs
// only itself (an && chain once lost a run its merge, retro, and
// report phases and every metric field to one refused merge phase).
function recordLine(lines) {
  return lines.map((l, i) => `${l} || echo refused: ${i + 1}`).join('; ')
}
// The note naming each refused line by its text, from the positions the
// close returned; empty when none was refused.
function refusedNote(lines, close) {
  const at = ((close && close.refused) || []).filter((n) => Number.isInteger(n) && n >= 1 && n <= lines.length)
  if (!at.length) return ''
  return `refused at the close, the other lines recorded: ${at.map((n) => lines[n - 1]).join('; ')}${close.record_output ? `; output: ${close.record_output}` : ''}`
}
// The queued lines the closing start may run under the guard's close
// profile: the phases no merge gate reads, at a commit or at the merged
// commit by name (the merge with the merger's sha, noted when it differs),
// notes, and the CI stages.
const CLOSABLE = /^sh tools\/run_state\.sh (phase [a-z0-9-]+ (plan|implement|package|ci|merge|retro|report) [0-9a-f]{7,40}|phase [a-z0-9-]+ (merge|retro|report) merged|phase [a-z0-9-]+ merge merged [0-9a-f]{7,40}|note [a-z0-9-]+ [a-z-]+ "[^"]*"|ci-stages [a-z0-9-]+ [0-9a-f]{40})$/
function reviewed(kind, passed, commit, counts) {
  const result = passed ? 'pass' : 'blocked'
  state['review.' + kind] = `${result} ${commit}`
  ran['review.' + kind] = `${result} ${commit}`
  const summary = Object.keys(counts).map((k) => `${k}=${Number.isInteger(counts[k]) ? counts[k] : 0}`).join(' ')
  queue(`sh tools/run_state.sh review ${state.change} ${kind} ${result} "${summary}" ${commit}`, commit)
}
// recordStart is the one start of the record profile, the runner agent (its
// guard profile allows the records and nothing to write), running one command
// from the repository root and returning its RECORDED result (flush, laneHead).
async function recordStart(command, label) {
  return measured('record', () => agent(
    `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${command}\n\nReturn ok true when it exited 0, and its output.${capLine('record')}`,
    calibrate('record', { agentType: 'runner', schema: withCalls(RECORDED), label })), callCap('record'))
}
// Runs the queued records with the metric line through one agent, only
// when a check or review record is queued, which the pre-push and merge
// gates read and only the runner may write; every other line and the
// figures wait for the closing start. The agent's own cost reaches the
// next line.
// force writes the metric line though only closable lines wait (the closing
// loop's figures, held after a start that committed nothing).
async function flush(force = false) {
  if (!force && !pending.some((l) => !CLOSABLE.test(l))) return true
  const command = pending.splice(0).concat([metricLine()].filter(Boolean)).join(' && ')
  if (!command) return true
  const r = await recordStart(command, 'record')
  if (r && r.ok) return true
  if (!stopped) stopped = `the run state records failed: ${r ? r.output : 'no result'}`
  return false
}
// The merger's two record lines at the pushed head, each one Bash call that
// starts with the run's figures. green records CI green and runs the merge
// gates with the review and check results the script holds: those of a
// fresh worktree of origin/main, which the branch cannot have edited, run
// against the branch, after a fetch of main by its own refspec, reading no
// configured one (--refmap=), so origin/main is origin's main (the merge
// gates' origin gate compares the two). The removal of an earlier
// worktree stays outside the && chain, since it fails when none stands; in
// the chain a failed record runs no gate, and the add fails when anything
// but an earlier worktree stands at the path. red records CI red. The
// fetch and the add read no global or system configuration and run no
// hook, both of which branch code run by the checks can write: a global
// insteadOf would fetch a forged main, a hook would rewrite the copy.
// Before the fetch, originCheck holds origin to the hosted repository.
// After the add and before any gate, fsck hashes every object of the
// store the lane shares with the main checkout (loose, packed, and
// alternate) and verifies the commit graph: branch code can plant a loose
// object under the id of a blob of a later main, which a small fetch
// keeps and the add writes into the copy, so a planted object still in
// the store fails the line before main's gates run. Given a head, fsck
// reads no index or reflog, so another lane's work in progress does not
// fail it. fsck reads the store, never the copy: an object swapped back
// to the true one between the add and the fsck passes it with the
// planted text checked out, and a copy file rewritten after the add
// passes it too. So after the fsck, read-tree puts main's tree into the
// copy's index with no stat data and diff --quiet hashes every tracked
// file of the copy against it, failing on a text that is not main's (or
// on its own failure); diff --quiet ignores a file the index does not
// track, so ls-files --others, which without --exclude-standard lists
// ignored files too, must list nothing, an untracked file the gates could
// read stopping the line, right before the gates run; a same-user process
// writing the copy between that diff and the gates' own reads is left to
// CI, the reviews, and branch protection.
// fsck ignores replace refs, so a refs/replace entry pointing main's
// gates.sh blob at a valid planted one would pass it while the add
// checked out the planted text: every pinned git runs with
// --no-replace-objects, and the line stops before the add when any
// refs/replace entry stands. That stop passes only when for-each-ref,
// listing refs/replace and origin/main newest name first, printed
// origin/main's one line, which every replace entry sorts before, so a
// for-each-ref that fails, printing nothing, stops the line too.
// The line runs in the delivery's worktree, whose HEAD is the branch, so
// its merge gates are a worktree under the lane's own tmp/ and two
// deliveries never share one (mergeGatesDir); when the cd fails the rest
// runs in the main checkout, where the gates refuse a HEAD other than the
// pushed head.
const MERGE_GATES = 'tmp/.merge-gates'
// Each delivery's own git worktree of the main checkout, hidden under tmp/
// (tools/run_state.sh lane-open), where its agents run every command; the
// toolchain, compile cache, run states, stage logs, and plans stay the main
// checkout's, linked in, so a feature-lane and a backlog-lane delivery run
// at once.
function laneDir(change) {
  return `tmp/.lane-${change}`
}
function mergeGatesDir(change) {
  return `${laneDir(change)}/${MERGE_GATES}`
}
const PINNED_GIT = 'GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git --no-replace-objects -c core.hooksPath=/dev/null'
// The git blob ids (printf %s FORM | git hash-object --stdin) of the
// repository's address in its https form, the one the hook lines under
// .claude/agents/ pin, then the same with .git; recomputed when the
// repository moves. The ssh and scp forms are refused: their transport
// runs the ssh client, whose own configuration (a Host alias) no pinned
// git environment reaches.
const ORIGIN_IDS = ['244706f6059ecef3ab5cd192a3b80eea788e0e2a', '63b6cf12839e160500c53c6dafc920b56bb92d6b']
// The green line's origin check, before its fetch: the blob id of
// origin's url, as git resolves it (insteadOf included) and with its
// lines joined, is one of ORIGIN_IDS, so the line names no address; a
// user before the host or a trailing slash is refused.
// Branch code run by the checks can point remote.origin.url at a local
// repository or a server of its own, whose main the forced fetch would
// make origin/main, bringing its own gates and the guard the merge hook
// reads; the check is the script's, which no fetch replaces.
function originCheck() {
  return `${PINNED_GIT} remote get-url origin | tr -d '\\n' | ${PINNED_GIT} hash-object --stdin | grep -q -x -E '${ORIGIN_IDS.join('|')}'`
}
// The CI record names the pushed head, the only head the run state accepts
// as CI's (tools/run_state.sh, pushed_at), never a head an agent reported.
function mergeLines(pushed) {
  const records = mergeRecords(ran)
  const first = (line) => [metricLine(), line].filter(Boolean).join(' && ')
  const ci = (result) => `sh tools/run_state.sh set ${state.change} ci "${result} ${pushed}"`
  return {
    green: `cd ${laneDir(state.change)} && git worktree prune; git worktree remove --force ${MERGE_GATES}; ${first(ci('green'))} && ${originCheck()} && ${PINNED_GIT} fetch -q --refmap= origin +refs/heads/main:refs/remotes/origin/main && ${PINNED_GIT} for-each-ref --sort=-refname refs/replace refs/remotes/origin/main | cut -f2 | tr -d '\\n' | grep -q -x -F refs/remotes/origin/main && ${PINNED_GIT} worktree add -q --detach ${MERGE_GATES} origin/main && ${PINNED_GIT} fsck --no-dangling --no-progress origin/main && ${PINNED_GIT} -C ${MERGE_GATES} read-tree origin/main && ${PINNED_GIT} -C ${MERGE_GATES} diff --quiet && ${PINNED_GIT} -C ${MERGE_GATES} ls-files --others | wc -c | grep -q -x -E ' *0' && CHANGE=${state.change} RECORDS="${records.join(' ')}" sh ${MERGE_GATES}/tools/gates.sh merge build/pipeline/${state.change}.body.md`,
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
  return ['security', 'bench'].every((k) => !!records['review.' + k]) && !!records['phase.check']
}
// The merge gates' RECORDS words, KIND:RESULT:COMMIT, from this start's
// records alone, so no record branch code wrote in the run state reaches
// the records gate.
function mergeRecords(records) {
  return ['security', 'bench'].map((k) => `${k}:${String(records['review.' + k] || '').split(' ').slice(0, 2).join(':')}`)
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

const doneAtHead = (name) => passedAt(ran, 'phase.' + name, head) || (name === 'check' && settledAtHead())
const reviewedAtHead = (kind) => passedAt(ran, 'review.' + kind, head) || (SETTLES.includes(kind) && settledAtHead())
const note = (line) => { notes.push(line); log(line) }
const backlog = []
// A finding joins the list once, compared as its note text, so a resumed
// review's raw line and the same line seeded from a note are one entry.
function addBacklog(line) {
  const t = noteText(line)
  if (t && !findings().some((f) => noteText(f) === t)) backlog.push(line)
}
let planNotes = []
// The checker's word on the benchmark at a commit.
let benchSameAt = ''
let benchReport = []
// The findings handed to the contributor so far, so a CI fix's push gets
// only those that arrived after them; the findings, for
// docs/findings/CHANGE.md.
const handed = new Set()
const findings = () => backlog.slice()
function handOver() {
  const fresh = findings().filter((f) => !handed.has(f) && !fixedInPlace.has(f))
  for (const f of fresh) handed.add(f)
  return fresh
}
// The findings that arrived after the package step, as late-finding notes
// in the run state: the next change's package step writes them to
// docs/findings/CHANGE.md with this run's history row, so no push records them.
// The note command refuses a late finding before the merge, so an unmerged
// run's close after the push keeps them as held-finding notes instead,
// which seed reads back into held (a security Low lives only in this
// start's memory, and seed marks every advisory handed once pushed); a
// merged close notes the held ones still not noted late, then the fresh
// ones, as late findings. A close before the push, no package step having
// handed anything, keeps them as unpushed-finding notes, which seed of a
// resume still unpushed puts back into the list its package step hands
// over, so they never reach held and are written once. Only the close
// profile writes these kinds (tools/agent_guard.sh), and the note command
// refuses a held finding outside the push-to-merge span and an unpushed
// one after the push, so no other start plants one that seed reads back.
let held = []
function recordLate() {
  const fresh = handOver().map(noteText).filter((t) => t && !held.includes(t))
  const texts = state.merged ? held.splice(0).concat(fresh) : fresh
  const kind = state.merged ? 'late-finding' : state.pushed ? 'held-finding' : 'unpushed-finding'
  for (const t of texts) queue(`sh tools/run_state.sh note ${state.change} ${kind} "${t}"`, head)
}
const intro = () => `Change \`${state.change}\` on branch \`${state.branch}\`, in its worktree \`${laneDir(state.change)}\`: run every command there (\`cd ${laneDir(state.change)} && ...\`) and read and edit its files there, but where a step names the main checkout; the run state, stage logs, plans, and the body file stay in the main checkout's build/, linked into the worktree, so write the body file there.`
// The merger's step 7 closes the worktree it would otherwise stand in, and
// checks out main, which only the main checkout can, so it runs there.
const MERGER_CLOSE = ' Run step 7 (the merged record, lane-close, the branch deletion, and the fast-forward of main) in the main checkout, with no `cd` into the worktree: lane-close removes the worktree, and main is checked out only in the main checkout.'
// Every contributor start, the package start that pushes included, carries
// the brief, so what it asks, a hold for the user's reading included,
// reaches each of them.
function contributorTask(mode, briefText, detail) {
  return `Mode: ${mode}. Brief: ${briefText}. ${detail}${mode === 'implement' || mode === 'fix' ? `\n${MERGE_MAIN}${SELF_CHECK}` : ''}\n${CONTRIBUTOR_CARD}`
}
// An implement or fix start first takes in a main that moved while the
// delivery ran (parallel-lanes-b), so the checks and reviews cover the merge.
const MERGE_MAIN = 'First run `sh tools/run_state.sh merge-main <change>` in the worktree: it merges a moved origin/main into the branch, never a rebase, both sides of the appended records kept; on a conflict it names, follow your push mode\'s conflict rules.'
// The contributor's self-check before an implement or fix start returns
// (its agent file's implement step 5): the mechanical findings a review
// would otherwise block on, then its own check of the head
// (contributor-self-check), which the checker's check backs (backedCommit).
const SELF_CHECK = '\nBefore returning, check yourself: every behavior the change adds or alters has a test that proves it; every document describing that behavior (README.md, docs/architecture.md, CLAUDE.md, docs/codebase-map.md, docs/compatibility.md, docs/actions.md) is updated; and the diff is compared against the brief, anything extra named in your summary. Set self_check to mismatch when any of this is still not true as you return, else match. Then commit and run the check as docs/contributor-notes.md, Checking, says: `sh tools/run_state.sh check <change>` (Bash timeout 600000, again on exit 3), each failure fixed and committed in this start and the whole check rerun, at most three runs; return its last line verbatim as check and the runs as check_runs.'

// The rules card at the top of the contributor's agent file, word for word
// (tools/tools_test.sh compares them): the mid tier forgets a rule of a long
// file, and each start is fresh, so every start carries it.
const CONTRIBUTOR_CARD = "Rules card:\n1. Return `head` from `sh tools/lane_facts.sh <change>`, never a placeholder or typed hash.\n2. Commit, then pass `sh tools/run_state.sh check <change>` at HEAD before returning implement or fix; quote its verdict line.\n3. You never read `docs/backlog/` or `docs/findings/*.md`; only append to your own findings file with `>>`.\n4. Never remove or rewrite an existing findings entry.\n5. `pr.md` states only what the diff does; after a split, rewrite it for the delivered part.\n6. No model name or alias in a change name, branch, commit, `pr.md`, or doc (the `model:` line excepted).\n7. A fix's new test must fail with the fix reverted (mind caches keeping two frames).\n8. In a fix round fix what blocks; an advisory needing new code goes to the findings file, not a new change.\n9. A spec, compatibility, or architecture doc change also updates README.md and the code map, or the proposal says why not.\n10. Tasks done, review the diff by `.claude/agents/quality-reviewer.md`: a task per finding, fixed or recorded, before packaging."

// Card rule 1 made mechanical: a done contributor result's head is the
// lane's `git rev-parse --short=12 HEAD`, twelve lowercase hex characters.
// The workflow has no shell, so laneHead reads the lane's facts in a start
// of the record profile (recordStart) that runs `sh tools/lane_facts.sh`
// (contributor-harness): { head, dirty }, head '' when it could not read it,
// and then a well-formed head is taken, noted head-unread (the check
// compares its own commit with it); dirty -1 when unknown. A head that
// differs from a committed lane head only in form (headForm) is taken from
// git, noted head-form, with no refusal, escalation, or restart; any other
// placeholder, short hash, or commit is refused (headProblem). safeText is
// all of a reported head that reaches a note or a queued record line: no
// quote or shell character.
const HEAD12 = /^[0-9a-f]{12}$/
function safeText(text) {
  return String(text || '').replace(/[^A-Za-z0-9._-]/g, '').slice(0, 40) || 'empty'
}
function headProblem(reported, lane) {
  if (!HEAD12.test(reported || '')) return `head ${safeText(reported)} is not the 12-character form of git rev-parse --short=12 HEAD`
  if (lane && reported !== lane) return `head ${reported} is not the lane's HEAD ${lane}`
  return ''
}
// The lane's head and dirty count from the `key value` lines of
// tools/lane_facts.sh: only a 12-character hex head and a whole count kept, and
// machinery and ruby yes or no, else unknown.
function parseLaneFacts(text) {
  const facts = {}
  for (const line of String(text || '').split('\n')) {
    const m = /^([a-z_]+) (\S+)$/.exec(line.trim())
    if (m) facts[m[1]] = m[2]
  }
  return { head: HEAD12.test(facts.head || '') ? facts.head : '', dirty: /^[0-9]+$/.test(facts.dirty || '') ? Number(facts.dirty) : -1, machinery: /^(yes|no)$/.test(facts.machinery || '') ? facts.machinery : 'unknown', ruby: /^(yes|no)$/.test(facts.ruby || '') ? facts.ruby : 'unknown' }
}
// True when a reported head differs from the lane's committed head only in
// form: the lane read with no uncommitted path, and the head, lower-cased,
// empty or holding a character that is not a hex digit (a placeholder), or
// a hex prefix of seven or more characters of the lane head or one the lane
// head prefixes (a short or full hash), upper case included. Another hex
// value names another commit and is left to headProblem, as is any head
// over a dirty or unknown lane.
function headForm(reported, lane) {
  if (!lane.head || lane.dirty !== 0 || reported === lane.head) return false
  const r = String(reported || '').trim().toLowerCase()
  if (!/^[0-9a-f]+$/.test(r)) return true
  return r.length >= 7 && (lane.head.startsWith(r) || r.startsWith(lane.head))
}
// Card rule 10 made mechanical (review-in-openspec): an implement start's
// done result, the one that finished the tasks, reports quality_review,
// status done with the counts of the tasks its quality step added, fixed,
// and recorded in docs/findings/, fixed plus recorded equal to added; '' when
// it does, else what is wrong, in words a note keeps.
function qualityReviewProblem(r) {
  const q = r && r.quality_review
  if (!q || q.status !== 'done') return 'no quality review of status done: the quality step of card rule 10 did not run'
  const n = [q.added, q.fixed, q.recorded]
  if (n.every((x) => Number.isInteger(x) && x >= 0) && q.fixed + q.recorded === q.added) return ''
  return `quality review counts ${n.map((x) => safeText(String(x))).join('/')} are not added, fixed, and recorded with fixed plus recorded equal to added`
}
// What a done result is refused for, each a kind (the note's KIND-refused
// and the words of its escalation and stop) and its reason: the head of any
// mode, and the quality review of an implement start.
const REFUSED_WORDS = { head: 'head', quality: 'quality review' }
function resultProblems(mode, r, lane) {
  const found = [{ kind: 'head', text: headProblem(r.head, lane) }]
  if (mode === 'implement') found.push({ kind: 'quality', text: qualityReviewProblem(r) })
  return found.filter((p) => p.text)
}
async function laneHead() {
  const r = await recordStart(`sh tools/lane_facts.sh ${state.change}`, 'record: lane head')
  return parseLaneFacts(r && r.ok ? r.output : '')
}

// A change whose committed diff against its base touches no Ruby code (no file
// under carat/, bin/, bench/, config/, or tools/spinel/, no carat.rb,
// Makefile, or tools/metrics.sh) cannot change the allocations or rounds the
// benchmark compares (bench-skip-nonruby). The fact is read from git by
// tools/lane_facts.sh in a record start, never from a contributor's claim,
// and holds only for a clean lane at the commit the check passed at: ruby
// no, any other value (yes, unknown), a dirty or unread lane, or another
// head keeps the gate.
function noRubyAt(lane, at) {
  return Boolean(lane) && lane.ruby === 'no' && lane.dirty === 0 && sameCommit(lane.head, at)
}
// Records the benchmark review passed at the head with no agent when the diff
// changed no Ruby code; false, recording nothing, otherwise.
async function benchWithoutRuby() {
  if (!doneAtHead('check') || !noRubyAt(await laneHead(), head)) return false
  verdict('bench', true)
  note(`benchmark at ${head}: no Ruby code changed (no file under carat/, bin/, bench/, config/, or tools/spinel/, no carat.rb, Makefile, or tools/metrics.sh); no agent`)
  reviewed('bench', true, head, { blocking: 0 })
  return true
}

// The contributor's own check (contributor-self-check): a done implement or
// fix result whose check line reads every stage passed at its returned
// head, over a lane whose diff leaves the check's machinery alone
// (tools/lane_facts.sh machinery no), is a claim the checker's check backs
// (backedCommit); any other result claims nothing. A claim the run state
// does not hold costs only the stages, which the runner then runs. The
// records at a backed head come from the contributor's working tree's
// runner, so they trust its session: an uncommitted, restored edit of
// tools/ or the Makefile escapes machinery no; CI and main's merge gates
// rerun every stage but diagnose, which the checker's check runs again,
// since a stage of RERUN_STAGES skips only on the recorded phase.check
// (tools/run_state.sh, the check entry).
let claimedPass = null
function claimFrom(r, lane) {
  const v = checkVerdict(r && r.check)
  return v.kind === 'passed' && sameCommit(v.at, r.head) && lane && lane.machinery === 'no' ? { at: r.head } : null
}
// The commit the checker's check backs: the head the contributor's passing
// check claimed, while it is still the head, else phase.check, the check
// the workflow last recorded, as before.
function backedCommit(claim, at, checked) {
  if (claim && COMMIT.test(at || '') && sameCommit(claim.at, at)) return at
  return COMMIT.test(checked || '') ? checked : ''
}
// True when the check would back BACKED, the last check this run passed,
// at a head past it while its phase.check record still waits in the queue
// (flush writes it only after the rounds): tools/run_state.sh backs a
// commit only from the record it holds, so the check flushes it first and
// a fix round's stages still carry from it.
function backedUnwritten(backed, at, queued) {
  return COMMIT.test(backed || '') && !sameCommit(backed, at) && queued.includes(phaseLine('check', backed))
}
// The check runs a start made after its first, from its check_runs.
const extraRuns = (r) => (r && Number.isInteger(r.check_runs) && r.check_runs > 1 ? r.check_runs - 1 : 0)

async function contributor(mode, detail) {
  if (mode === 'fix') rework++
  claimedPass = null
  // One kind names the start's phase figures, its cap line, and its cap.
  const capKind = mode === 'close-advisories' ? 'closing' : mode
  const key = mode === 'implement' || mode === 'fix' ? 'implement' : capKind === 'closing' ? 'closing' : 'package'
  let result = null
  let more = ''
  const refused = new Set()
  for (let count = 0; ; count++) {
    result = await measured(key, () => agent(
      `${intro()} ${contributorTask(mode, brief, detail)}${more}\nFollow your Modes section for \`${mode}\` and return the schema.${capLine(capKind)}`,
      calibrate('contributor', { agentType: 'contributor', schema: withCalls(WORK), label: `contributor: ${mode}${count ? ', continued' : ''}` })), callCap(capKind))
    state.pushed = keepPushed(mode, state.pushed, result)
    if (mode === 'implement' || mode === 'fix') selfFix += extraRuns(result)
    if (!result) escalate('a start returned no result')
    else if (result.self_check === 'mismatch') escalate('a self-check mismatch')
    selfCheck = mode === 'implement' || mode === 'fix' ? { mode, said: (result && result.self_check) || '' } : null
    const step = continuation(result, result ? workLeft(result) : null, count)
    if (step.next === 'done') {
      const lane = await laneHead()
      if (headForm(result.head, lane)) {
        const what = `contributor ${mode} start ${count + 1}: head ${safeText(result.head)} taken from git as ${lane.head}`
        note(`${what}; not refused`)
        queue(`sh tools/run_state.sh note ${state.change} head-form "${what}"`, head)
        result = Object.assign({}, result, { head: lane.head })
      }
      const problems = resultProblems(mode, result, lane.head)
      if (!problems.length) {
        // An unread lane head is also a run-state note in fixed words, so a
        // reader that always fails, turning the wrong-head refusal off, shows.
        if (!lane.head) {
          note(`contributor (${mode}): the lane's head could not be read; head ${result.head} taken as returned`)
          queue(`sh tools/run_state.sh note ${state.change} head-unread "contributor ${mode} start ${count + 1}: lane head not read"`, head)
        }
        if (mode === 'implement') { const q = result.quality_review; qualityReview = `${q.added}/${q.fixed}/${q.recorded}` }
        if (mode === 'implement' || mode === 'fix') claimedPass = claimFrom(result, lane)
        break
      }
      // Each refused kind, a head or a quality review, escalates, is noted,
      // and puts its own reason in the one restart; a kind refused once is
      // restarted once, and its second refusal in this call stops the run;
      // each note says whether its own kind was refused twice.
      const repeated = problems.filter((p) => refused.has(p.kind))
      for (const p of problems) {
        escalate(`a refused ${REFUSED_WORDS[p.kind]}`)
        note(`contributor (${mode}) result refused: ${p.text}${refused.has(p.kind) ? '; refused twice, stopped' : repeated.length ? '; stopped' : '; restarted'}`)
        queue(`sh tools/run_state.sh note ${state.change} ${p.kind}-refused "contributor ${mode} start ${count + 1}: ${p.text}"`, head)
      }
      if (repeated.length) {
        stopped = `contributor (${mode}) returned a refused ${repeated.map((p) => REFUSED_WORDS[p.kind]).join(' and ')} twice: ${repeated.map((p) => p.text).join('; ')}`
        return false
      }
      for (const p of problems) refused.add(p.kind)
      more = problems.map((p) => p.kind === 'head'
        ? `\nThis restarts a start whose result was refused: its ${p.text}. Commit any uncommitted work, then return as head the \`head\` line of \`sh tools/lane_facts.sh ${state.change}\`, copied, never typed or a placeholder; redo nothing already committed or recorded.${pushedHint(mode, state.change)}`
        : `\nThis restarts a start whose result was refused: ${p.text}. ${QUALITY_STEP}`).join('')
      continue
    }
    if (step.next === 'stop') {
      stopped = `contributor (${mode}) stopped${count ? ` after ${count + 1} starts` : ''}: ${result ? result.question || result.summary : 'no result'}`
      return false
    }
    // A continued start's head is read from the lane too, the reported
    // well-formed one kept only when the lane's could not be read.
    const read = result ? (await laneHead()).head : ''
    if (read) head = read
    else if (result && /^[0-9a-f]{7,40}$/.test(result.head || '')) head = result.head
    const why = result ? 'reached its cap' : 'returned no result'
    note(`contributor (${mode}) ${why}${result ? `, left: ${step.left.join('; ')}` : ''}; continued`)
    queue(`sh tools/run_state.sh note ${state.change} overrun "contributor ${mode} start ${count + 1} ${why} and was continued"`, head)
    more = `\nThis continues a start that ${result ? `reached its cap. It left:\n- ${step.left.join('\n- ')}` : 'returned no result, having reached its turn ceiling'}\nResume from the branch's commits, tasks.md, and the run state; redo nothing already committed or recorded.${pushedHint(mode, state.change)}`
  }
  head = result.head
  note(`contributor (${mode}): ${result.summary}`)
  return result
}

// Check, the security review, and benchmark until all pass at one commit;
// whatever blocks goes back to the contributor while mayFix allows.
async function verify(fixes = true) {
  const passed = await rounds(fixes)
  return (await flush()) && passed
}


// The verdict line of tools/run_state.sh check, which the checker returns
// verbatim: passed or failed (a refusal is a failure the contributor fixes)
// at a commit; killed, superseded, and running mean the check did not
// finish, escaped that every stage exited 0 but files changed outside its
// clone, all under the paths of the main checkout's build/ another lane
// writes (LANE_WRITTEN, none by default), so no pass counted and the stages run again (lane-isolation; any other
// escaped path reads failed), and any other line is none. The words
// are the script's verdicts, which tools/tools_test.sh compares with
// RERUN_WORDS.
const RERUN_WORDS = /^(killed|superseded|escaped|running|none)$/
function checkVerdict(line) {
  const text = String(line || '').trim().replace(/^run_state: /, '')
  let m = /^check: every stage passed at ([0-9a-f]{7,40})(;|$)/.exec(text)
  if (m) return { kind: 'passed', at: m[1], stage: '', log: '' }
  m = /^check: stage ([a-z0-9-]+) (failed|killed|superseded|escaped) at ([0-9a-f]{7,40}); read ([A-Za-z0-9_./-]+)$/.exec(text)
  if (m) return { kind: m[2], at: m[3], stage: m[1], log: m[4] }
  m = /^check: refused: (.+)$/.exec(text)
  if (m) return { kind: 'failed', at: head, stage: 'refused', log: m[1] }
  m = /^check: still running at ([0-9a-f]{7,40})/.exec(text)
  if (m) return { kind: 'running', at: m[1], stage: '', log: '' }
  return { kind: 'none', at: '', stage: '', log: '' }
}
// The check's lines, which the workflow builds and a start of the checker
// file's Mode: run runs exactly, reading nothing (each a form the guard's
// read profile allows): the run's figures and the check; after a pass,
// spent and bench; and moved when asked. The checker's reading start runs
// only on a failed stage (checkerNeeded): a pass, a refusal (its message is
// its log), and a check that did not finish start none. tools/tools_test.sh
// runs these helpers. In an advisory-only round (settleFrom) the start
// runs settled first and the check only when that exits 1 (review-lite);
// the run's figures then lead the settle line, so a settled round, which
// runs no check, still records them, once.
function checkLines(change, backed, movedFrom, metric, settleFrom = '') {
  const rs = 'sh tools/run_state.sh'
  const figures = metric ? `${metric}; ` : ''
  return {
    settle: settleFrom ? `${figures}${rs} settled ${change} ${settleFrom}` : '',
    check: `${settleFrom ? '' : figures}${rs} check ${change}${backed ? ` ${backed}` : ''}`,
    passed: `${rs} spent ${change}; ${rs} bench ${change}`,
    moved: movedFrom ? `${rs} moved ${change} ${movedFrom}` : '',
  }
}
function checkRunTask(lines) {
  const settle = lines.settle ? `\nFirst \`${lines.settle}\`: when it exits 0, return its last line, verbatim, as verdict, and run nothing else; when it exits 1, go on.` : ''
  return `Mode: run. Run each line below exactly as written, as your Mode run section says, and read nothing else.${settle}\n1. \`${lines.check}\`: while it exits 3, run it again, at most three times; return its last line, verbatim, as verdict.\n2. Only when that line begins \`check: every stage passed\`: \`${lines.passed}\`; return the line spent printed as budget, bench_same true when the line exited 0, and the last 20 lines bench printed as bench_report.${lines.moved ? `\n3. Then \`${lines.moved}\`; return its last line, verbatim, as moved.` : ''}`
}
// The carried check (cache-reuse): when the contributor's pass at the head
// is the backing, and nothing asks for a settle or a moved line, the
// workflow asks the runner start for tools/run_state.sh carried, which says
// whether every stage holds a pass record at the head (diagnose only scoped
// out) and gives the spent line and bench's result the checker would have
// returned; a carried head starts no checker. The line only decides: the
// phase.check record is the workflow's own, written at the head by flush,
// where the pre-push and merge gates read the stage records themselves.
const CARRIED_FIRST = /^carried: every stage passed at ([0-9a-f]{7,40}); no stage ran$/
const carriedLine = (change, backed) => `sh tools/run_state.sh carried ${change} ${backed}`
function carryWanted(claim, backed, at, settle, moved) {
  return !!claim && COMMIT.test(at || '') && sameCommit(claim.at, at) && sameCommit(backed, at) && !settle && !moved
}
function carriedRun(output, at) {
  const lines = String(output || '').split('\n').map((l) => l.trim().replace(/^run_state: /, ''))
  const first = lines.findIndex((l) => CARRIED_FIRST.test(l))
  if (first < 0 || !sameCommit(CARRIED_FIRST.exec(lines[first])[1], at)) return null
  const same = lines.includes('carried: bench same')
  if (!same && !lines.includes('carried: bench differs')) return null
  const spent = lines.find((l) => l.startsWith('spent: '))
  return {
    verdict: `check: every stage passed at ${at}`, budget: spent ? spent.slice('spent: '.length) : '', bench_same: same, moved: '',
    bench_report: lines.slice(first + 1).filter((l) => l && !l.startsWith('spent: ') && !l.startsWith('carried: ')).slice(-20),
  }
}
function checkerLogTask(v) {
  return `Mode: log. The check failed at stage ${v.stage} at ${v.at}: read only its log, ${v.log}, as your Mode log section says, and return passed false, the verdict \`check: stage ${v.stage} failed at ${v.at}; read ${v.log}\`, and the lines that show the cause. Run no check.`
}
const checkerNeeded = (v) => v.kind === 'failed' && v.stage !== 'refused'
const sameCommit = (a, b) => COMMIT.test(a || '') && COMMIT.test(b || '') && (a.startsWith(b) || b.startsWith(a))
let reruns = 0
let rerunWhy = ''

// An advisory-only round (review-lite, the user-approved exception of
// 2026-11-18): the fix-in-place round of its own, offered when nothing
// blocked. settleFrom gives the commit it may stand on: this start's
// check, when this start's security review and benchmark passed at that
// same commit (RECORDS, ran) and the round offers no security finding,
// which the security reviewer must confirm fixed; '' otherwise, and the
// round runs in full. A blocking round never reaches it.
function settleFrom(records, offeredList) {
  const checked = String(records['phase.check'] || '')
  const passed = ['security', 'bench'].every((k) => passedAt(records, 'review.' + k, checked))
  return COMMIT.test(checked) && passed && !offeredList.some((f) => String(f).startsWith('security ')) ? checked : ''
}
// The settled line the checker returns verbatim stands the check, the
// security review, and the benchmark only when it names FROM and HEAD;
// any other line, an unsettled one included, leaves the check's verdict.
// A forged line only stops the run: the pre-push and merge gates settle
// the same pass records with settled_at, main's copy at the merge.
const SETTLED = /^settled: only records changed from ([0-9a-f]{7,40}) to ([0-9a-f]{7,40})(:|$)/
function settled(line, head, from) {
  const m = SETTLED.exec(String(line || '').trim().replace(/^run_state: /, ''))
  return !!m && sameCommit(m[1], from) && sameCommit(m[2], head)
}
// The commit the next check may settle from: none after a merge of a
// moved main (movedFrom), whose check must run in full.
const settleBase = (moved, at) => (moved ? '' : at || '')
// What the check start's verdict line means at AT: 'settled' (the settle
// line named FROM and AT), 'rerun' (the check did not finish, or ran at
// another commit), or 'check' (a pass or a failure at AT).
function checkOutcome(line, at, from) {
  if (from && settled(line, at, from)) return 'settled'
  const v = checkVerdict(line)
  return RERUN_WORDS.test(v.kind) || !sameCommit(v.at, at) ? 'rerun' : 'check'
}
// What the next check is asked to settle from after the in-place fix: FROM
// only when the fix moved the head; a fix that made no commit leaves the
// check passed at the head, and no settle waits for a later round.
const settleAfter = (from, before, after) => (from && after && before !== after ? from : '')
// The settled round at the head: the check, security, and bench passes
// stay at FROM, where the gates settle them, and the run state notes the
// skip naming both commits; no review runs. It clears the last self-check,
// which stands on the pass at FROM.
let settledRound = null
let settleAt = ''
function settleRound(from) {
  settledRound = { at: head, from }
  selfCheck = null
  const text = `advisory-only round at ${head}: only records changed since ${from}, where the check, the security review, and the benchmark passed; none of them rerun`
  note(text)
  queue(`sh tools/run_state.sh note ${state.change} settled-round "${text}"`, head)
}
const SETTLES = ['security', 'bench']
const settledAtHead = () => !!settledRound && settledRound.at === head
// What the package step is told after a settled round: Testing names the
// check and the security review at the commit where they ran.
function settledTesting() {
  return settledAtHead() ? `\nThe last fix round changed only records: the check, the security review, and the benchmark last ran at ${settledRound.from}; in Testing name each at ${settledRound.from}, never at the head.` : ''
}

// A merge refused because main moved (merge-main-path; #169 stopped there
// and cost a second run): the merger read CI green, and the pull request
// conflicts with main or GitHub refused the merge, the branch behind main
// or conflicting with it (main_moved). used, the run state's main_moved
// plus this start's: the first refusal takes the main-moved path
// (merge-main, the check again, the reviews again only when the merge
// changed files of the change, one main-moved push, CI and the merge
// again); a second is the stop's reason; anything else is ''.
function mainMoved(m, used) {
  if (!m || m.merged || m.main_moved !== true || m.ci !== 'green') return ''
  if (Number(used || 0) >= 1) return `a second merge refused because main moved, at ${m.head}: one main-moved push is allowed a run${m.problem ? `; ${m.problem}` : ''}`
  return 'merge'
}
// The commit the security review of this start passed at, which
// tools/run_state.sh moved compares with the merged head; '' when it did
// not pass, so it runs again.
function carryFrom(records) {
  const s = String(records['review.security'] || '').split(' ')
  return s[0] === 'pass' && COMMIT.test(s[1] || '') ? s[1] : ''
}
// The moved line the checker returns verbatim stands the review only
// when it says the change is the same at the head as at the reviewed
// commit (from); any other line, or none, runs them again. The line only
// decides: the record needs the run state's moved record at the head
// against the commit the review passed at, which only moved's exit-0 path
// writes (review refuses a carried=1 summary without it), so a forged line
// stops at the record, carrying nothing (moved-review-carry).
const CARRIED = /^moved: the change is the same at ([0-9a-f]{7,40}) as at ([0-9a-f]{7,40}):/
function carried(line, head, from) {
  const m = CARRIED.exec(String(line || '').trim())
  return !!m && sameCommit(m[1], head) && sameCommit(m[2], from)
}
// The main-moved contributor start's task: merge-main, a conflict merged
// by the push mode's rules and committed, every conflict resolved by the
// contributor and none a stop.
function movedTask(problem) {
  return `The merge was refused because main moved: ${problem || 'no reason given'}. Run \`sh tools/run_state.sh merge-main ${state.change}\` in the worktree. On the conflicts it names, merge origin/main by hand by your push mode's conflict rules and commit the merge with the trailer, resolving every conflict yourself, a conflict where both sides changed the same logic included, without stopping to ask. Commit nothing else and push nothing: the workflow reruns the check, and the reviews when the merge changed files of the change, before the main-moved push.`
}
// The reviewed commit tools/run_state.sh moved compares with the head the
// check after a main-moved merge passes at; '' once compared.
let movedFrom = ''
let mainMovedPushes = 0
// After the check passed at the merged head: the security review carried to it
// when the moved line says the change is the same, recorded only where
// moved exited 0 at the head (above), else it runs again (reviews()
// finds no pass at the head).
function carryReviews(line) {
  const from = movedFrom
  movedFrom = ''
  const text = String(line || '').trim()
  if (!carried(text, head, from)) { note(`after the merge of main: ${text || 'no moved line returned'}; the security review runs again at ${head}`); return }
  reviewed('security', true, head, { blocking: 0, carried: 1 })
  note(`after the merge of main: ${text}; the security review of ${from} stands at ${head}`)
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


// The security reviewer's scope in a fix round: the commits since this
// start's last passed security review, in_change only for what they
// introduce.
function priorSecurity() {
  // A review fix round of a resume past the push reviews the whole diff.
  const since = reviewFixRounds ? '' : narrowedFrom(ran, 'security', head)
  return since
    ? `\nThe last security review passed at ${since}: review \`git diff ${since} HEAD\`, the commits since, and set in_change only for a finding that diff introduces.`
    : ''
}
function securityReview(more) {
  return agent(more
    ? `${intro()} ${continuedSecurity(more)}${capLine('security')}`
    : `${intro()} Run the security review on the committed diff and return the result.${priorSecurity()}${inPlaceCheck()}${capLine('security')}`,
  calibrate('security', { agentType: 'security-reviewer', schema: withCalls(SECURITY), phase: 'Security', label: more ? 'security-reviewer: continued' : 'security-reviewer' }))
}
// The continued security request, its closing sentence on a line of its
// own so the last file of the list stands alone.
const continuedSecurity = (more) => `The last security review did not complete.${more}\nRun it, every sub-task inline, and return the result.`
// What a continued review is told: the files the last start left, or the
// whole diff when it returned nothing.
function reviewMore(r, left) {
  return r && left.length && left[0] !== 'the whole diff'
    ? `\nThe last start reached its cap and left these files of the diff; review only them against the rules, and return their findings:\n- ${left.join('\n- ')}`
    : '\nThe last start returned no result or did not run; review the whole committed diff.'
}
// A review continued while it left files or returned nothing, at most
// CONTINUES more starts, the findings of every start kept.
async function continueReview(first) {
  let all = first
  let r = first
  for (let count = 0; ; count++) {
    const step = continuation(r, r ? reviewLeft(r) : null, count)
    if (step.next !== 'continue') return all
    note(`security review ${r ? 'reached its cap' : 'returned no result'}; continued`)
    const more = reviewMore(r, step.left)
    r = await measured('security', () => securityReview(more), callCap('security'))
    all = r && all && (!('ran' in all) || all.ran) ? combineReviews(all, r) : r || all
  }
}

// The pull request text review (delivery-guards): after the package step
// pushed pr.md, a quality reviewer of the session model compares its Summary
// and Changes with the committed diff and the archived proposal's Out of
// scope, since a contributor's own text reached main claiming work the diff
// lacks. Any claim not in the diff, or work the proposal moved out, blocks:
// the contributor's body mode rewrites pr.md and pushes it with --pr-text, and
// the text is reviewed once more. tools/tools_test.sh runs these helpers.
function prTextTask(change) {
  return `Review the pull request text only, not the code. Read the archived change's pr.md and proposal.md (the directory openspec/changes/archive/DATE-${change}/) and the committed diff against origin/main (\`git diff origin/main...HEAD\`). Return as blocking, one finding each with the claim quoted, every claim of pr.md's Summary or Changes that the diff does not contain, and every piece of work the proposal's Out of scope moved elsewhere that pr.md claims as done; return nothing blocking when each claim is in the diff.`
}
// The blocking message of a pull request text review result: '' when
// nothing blocks, null when the review returned no result.
function prTextBlocks(r) {
  if (!r) return null
  const found = Array.isArray(r.blocking) ? r.blocking : []
  return found.length ? `the pull request text claims what the diff does not contain:\n- ${found.join('\n- ')}` : ''
}
// The decision of one text review round from prTextBlocks's message: 'unchecked' when the review
// returned no result, 'pass' when nothing blocks, 'stop' when the second
// round still blocks, else 'rewrite'.
function prTextStep(round, why) {
  if (why === null) return 'unchecked'
  if (!why) return 'pass'
  return round >= 1 ? 'stop' : 'rewrite'
}
async function prTextReview() {
  for (let round = 0; round < 2; round++) {
    phase('Package')
    const r = await measured('prtext', () => agent(`${intro()} ${prTextTask(state.change)}${capLine('prtext')}`,
      calibrate('quality', { agentType: 'quality-reviewer', schema: withCalls(QUALITY), phase: 'Package', label: 'quality-reviewer: pull request text' })), callCap('prtext'))
    const why = prTextBlocks(r)
    const step = prTextStep(round, why)
    if (step === 'unchecked') {
      note('the pull request text review returned no result; the text was not checked against the diff')
      return
    }
    if (step === 'pass') return
    note(`pull request text blocked (round ${round + 1}): ${why}`)
    queue(`sh tools/run_state.sh note ${state.change} pr-text-blocked "round ${round + 1}: ${r.blocking.length} claim(s) not in the diff"`, head)
    if (step === 'stop') {
      stopped = `the pull request text still claims what the diff does not contain after a rewrite: ${r.blocking.join('; ')}`
      return
    }
    if (!(await contributor('body', `The quality review of the pull request text blocked it, as a body-mode rewrite of pr.md, not a red CI. ${why}\nRewrite the Summary and Changes of the body file to claim only what the committed diff contains, never adding work the proposal's Out of scope moved elsewhere; gate it, rewrite pr.md, commit, and push with \`sh tools/run_state.sh push ${state.change} --pr-text\`, not --ci-fix: no CI run is red.`))) return
  }
}

// The security review at the head, when this start holds no pass there:
// the blocking message, '' when nothing blocks, or null when it did not run.
async function reviews() {
  if (reviewedAtHead('security')) return ''
  phase('Security')
  const first = await measured('security', () => securityReview(''), callCap('security'))
  // A review that left files or returned nothing is continued over what it
  // left; a security review never passes with anything left.
  const s = await continueReview(first)
  if (!s || reviewLeft(s).length) { stopped = `the security review did not ${s && s.ran ? `cover ${reviewLeft(s).join(', ')}` : 'run'}; it cannot be skipped`; return null }
  // Every High or Medium in the change at confidence 8 or above blocks,
  // a re-rating of an earlier non-blocking finding included.
  const blocking = securityBlocking(s.findings)
  verdict('security', !blocking.length)
  for (const f of s.findings.filter((f) => !blocking.includes(f))) {
    const line = `security ${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`
    addBacklog(line)
    if (f.in_change) reviewFindings.push(line)
  }
  confirmInPlace(s.fixed_in_place)
  note(`security at ${s.head}: ${s.findings.length} finding(s), ${blocking.length} blocking`)
  const count = (severity) => s.findings.filter((f) => f.severity === severity).length
  reviewed('security', !blocking.length, s.head, { high: count('High'), medium: count('Medium'), low: count('Low'), blocking: blocking.length })
  return blocking.length ? `Blocking security findings, to fix first:\n- ${blocking.map((f) => `${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`).join('\n- ')}` : ''
}

// A resume past the push blocked at the head (fixes false): one fix round
// a run when the security review blocked (by, the step that
// blocked: check, review, or bench) and no review fix was used (used, the
// run state's review_fixes plus this start's rounds), its push a review
// fix (tools/run_state.sh push --review-fix); else the stop's reason.
function resumeFix(by, used) {
  if (by !== 'review') return 'blocked on resume, where only a blocking review gets a fix round'
  if (Number(used) >= 1) return 'a second review fix round is refused: one is allowed a run'
  return ''
}

// After a resume past the push passed its check and reviews at the head
// (verify(false)): push when the head is not the recorded push and no
// review fix push was made (used, the run state's review_fixes), so the
// fix commit of an earlier resume that then stopped is pushed as the review
// fix too; empty when the head is the pushed one or no push is recorded
// (the merge loop stops on that); else the stop's reason.
function resumePush(pushed, head, used) {
  if (!/^[0-9a-f]{40}$/.test(String(pushed || '')) || pushedHead(pushed, head)) return ''
  if (Number(used || 0) >= 1) return `the head ${head} is not the pushed head ${pushed} and the run's one review fix push was made`
  return 'push'
}

// Fix in place (cut 4b, the user's decision of 2026-11-18): each security
// finding in code the change touches, of any severity, is offered to the contributor once,
// in the round of the blocking findings, or in a round of its own when
// nothing blocks and a round remains after it, so a blocking finding the
// fix brings still has one; at the last round it is recorded, not fixed.
// The contributor fixes those in files the change edits whose fix stays
// there and adds no behavior, each a task of tasks.md; the check and the
// security review run again at the new head, whose reviewers list, verbatim, the
// ones they confirm fixed (fixed_in_place). Only those leave the findings
// handed to docs/findings/CHANGE.md; every other stays recorded. A resume
// past the push offers none. tools/tools_test.sh runs these helpers.
let reviewFindings = []
const offered = new Set()
const fixedInPlace = new Set()
let awaiting = []
// The findings a round offers for a fix in place: those not offered before,
// none while the closing loop runs (its advisories go to the findings file).
function freshOffers(fixes) {
  return fixes && !closingLoop ? reviewFindings.filter((f) => !offered.has(f)) : []
}
function inPlaceRound(blocked, count, used, limit) {
  if (!count) return 'none'
  if (blocked) return 'with'
  return used + 1 < limit ? 'alone' : 'record'
}
function inPlaceTask(list) {
  return `Fix in place, in this round, each finding below that lies in a file the change edits when its fix stays in those files and adds no behavior: each one a task of the change's tasks.md, marked done with its fix, its delta spec updated when specified behavior moves. Leave any other; it stays recorded for docs/findings/${state.change}.md.\n- ${list.join('\n- ')}`
}
// What the security reviewer after an in-place round is asked: the
// security findings offered then, to confirm fixed.
function inPlaceCheck() {
  return awaiting.length ? `\nFindings fixed in place since the last review, to check: list in fixed_in_place, verbatim as written here, each one the fix removed; one still present is a finding as before.\n- ${awaiting.join('\n- ')}` : ''
}
function confirmInPlace(listed) {
  for (const f of listed || []) if (awaiting.includes(f)) fixedInPlace.add(f)
  awaiting = []
}
function offer(list, awaited) {
  for (const f of list) offered.add(f)
  if (awaited) awaiting = list.filter((f) => f.startsWith('security '))
}

// The closing loop (closing-loop, the user's exception of 2026-11-19): once
// a run, after the last review passed with nothing blocking and before the
// package step, one contributor start (close-advisories) fixes the
// advisories left open in the change's own files that need no new behavior;
// the check and the security review then run again at its commit, the
// security review at once when code changed (settleFrom: only a records-only commit stands on the
// earlier passes). Advisories those reviews raise are recorded for
// docs/findings/, never offered again (closingLoop stops the in-place
// offers); a blocking finding goes through the normal fix rounds. It is
// not a fix round: it adds nothing to rework. A run with no open advisory
// skips it. tools/tools_test.sh runs these helpers.
const openAdvisories = () => findings().filter((f) => !fixedInPlace.has(f))
function closingTask(list) {
  return `Close advisories, once in this run: each finding below that lies in a file this change edits and needs no new behavior and no design change (wording, a comment, a doc or spec text, a missing test for behavior the change already has, a name, a small duplication) is fixed now, each a task of the change's tasks.md marked done and committed, its delta spec updated when specified behavior moves. Leave every other; it stays recorded for docs/findings/${state.change}.md. Make no commit when none qualifies.\n- ${list.join('\n- ')}`
}
// The contributor's quality review, then the last review passes, then the
// one closing loop: the archive and package step waits for all three.
async function readyToPackage() {
  return (await qualityStep()) && (await verify()) && (await closeAdvisories())
}
// The archive and package step is refused without a quality review: with
// none recorded (a resume, or a run begun before the step existed), one
// implement start runs the step alone, its result refused like any
// implement result without one, and the check and the security review then
// run on its commit.
const QUALITY_STEP = 'Run the quality step of card rule 10 now (docs/contributor-notes.md, Self-review): review the whole committed diff, append each finding as a task under a Quality review heading of tasks.md, fix it or record it in the findings file, commit, and return quality_review; redo nothing already committed.'
async function qualityStep() {
  if (qualityReview) return true
  note('no quality review recorded: one implement start runs the quality step before the archive')
  phase('Implement')
  return !!(await contributor('implement', `Every task of tasks.md is done. ${QUALITY_STEP}`))
}
async function closeAdvisories() {
  if (closingFigures.closed !== null) return true
  const open = openAdvisories()
  if (!open.length) {
    closingFigures.closed = 0
    closingFigures.left = 0
    note('closing loop skipped: no open advisory')
    return true
  }
  closingLoop = true
  const from = settleFrom(ran, open)
  const before = head
  note(`closing loop: ${open.length} open advisory(ies) offered to one closing start, then the check and the reviews of its commit`)
  offer(open, true)
  phase('Implement')
  if (!(await contributor('close-advisories', closingTask(open)))) return false
  settleAt = settleAfter(from, before, head)
  // Nothing committed: the offered findings were not touched, so no later
  // review is asked to confirm them.
  if (head === before) awaiting = []
  // Held and flushed at once, so a run stopped during the re-review (and a
  // resume before the push) has the loop recorded as run; the final figures
  // follow it.
  closingFigures.closed = 0
  closingFigures.left = open.length
  if (head !== before && !(await flush(true))) return false
  const passed = head === before ? true : await verify()
  closingFigures.closed = open.filter((f) => fixedInPlace.has(f)).length
  closingFigures.left = open.length - closingFigures.closed
  const recorded = await flush(true)
  note(`closing loop: ${closingFigures.closed} closed, ${closingFigures.left} left for docs/findings/`)
  return recorded && passed
}

async function rounds(fixes = true) {
  for (;;) {
    let blocked = ''
    let by = 'check'
    if (!doneAtHead('check')) {
      phase('Check')
      // The check the workflow last recorded, or the head the contributor's
      // own passing check claimed (backedCommit): stage records count only
      // at it, so a record at the head that neither backs runs again; the
      // checker's verdict is the one recorded.
      const backed = backedCommit(claimedPass, head, state['phase.check'])
      if (claimedPass && backed === head) note(`check: backs the contributor's passing check at ${head}; the stages it passed there are skipped`)
      if (backedUnwritten(backed, head, pending) && !(await flush())) return false
      const again = rerunWhy ? ` The last check did not finish (${rerunWhy}); a check still running at this commit is rejoined.` : ''
      const from = settleBase(movedFrom, settleAt)
      settleAt = ''
      const lines = checkLines(state.change, backed, movedFrom, metricLine(), from)
      let c = null
      if (carryWanted(claimedPass, backed, head, from, movedFrom)) {
        const r = await recordStart(carriedLine(state.change, backed), 'record: carried check')
        c = r && r.ok ? carriedRun(r.output, head) : null
        note(c ? `check: every stage already passed at ${head}; carried, no checker start` : `check: not carried at ${head}; the checker runs`)
      }
      if (!c) c = await measured('check', () => agent(`${intro()} ${checkRunTask(lines)}${again}${capLine('run')}`, calibrate('checker', { agentType: 'checker', schema: withCalls(CHECK_RUN), label: 'checker: run' })), callCap('run'))
      if (!c) { stopped = 'the check start returned no result'; return false }
      // Only a pass or a failure at the head is a result: a check that did
      // not finish, or one at another commit, runs again with no fix round.
      const v = checkVerdict(c.verdict)
      const outcome = checkOutcome(c.verdict, head, from)
      if (outcome === 'settled') {
        reruns = 0
        rerunWhy = ''
        settleRound(from)
      } else if (outcome === 'rerun') {
        const where = v.stage ? ` at stage ${v.stage}, log ${v.log}` : ''
        const why = v.kind === 'none' ? 'no verdict line' : `${v.kind}${where} at ${v.at}${sameCommit(v.at, head) ? '' : `, not the head ${head}`}`
        if (++reruns > RERUNS) { stopped = `the check did not finish at ${head} in ${reruns} starts: ${why}`; return false }
        rerunWhy = why
        note(`check rerun ${reruns} of ${RERUNS}, no fix round: ${why}`)
        continue
      } else {
        reruns = 0
        rerunWhy = ''
        const passed = finishCheck(v)
        if (passed) {
          phaseDone('check', head)
          budgetAtCheck(c.budget, head)
          benchSameAt = c.bench_same ? head : ''
          benchReport = c.bench_report || []
          if (movedFrom) carryReviews(c.moved)
        } else if (checkerNeeded(v)) {
          // The checker starts only here, to read the failed stage's log.
          const r = await measured('check', () => agent(`${intro()} ${checkerLogTask(v)}${capLine('checker')}`, calibrate('checker', { agentType: 'checker', schema: withCalls(CHECK), label: 'checker: log' })), callCap('checker'))
          blocked = `The stage ${v.stage} failed; its log, ${v.log}:\n${(r && r.log_excerpt) || ''}`
        } else blocked = `The check refused to run: ${v.log}`
      }
    }
    if (!blocked) {
      const r = await reviews()
      if (r === null) return false
      blocked = r
      by = 'review'
    }
    if (!blocked && !reviewedAtHead('bench')) {
      phase('Benchmark')
      if (benchSameAt && benchSameAt === state['phase.check']) {
        // The check measured the same allocations and rounds as main's
        // figures (those stored for main's current commit, else the newest
        // merged change without a history row, else the last row), or no
        // more of either when main's stored figures are the base: nothing
        // to compare with main.
        verdict('bench', true)
        note(`benchmark at ${benchSameAt}: allocations and rounds equal main's recorded figures; no agent`)
        reviewed('bench', true, benchSameAt, { blocking: 0 })
      } else if (!(await benchWithoutRuby())) {
        const b = await measured('bench', () => agent(
          `${intro()} The check's measurement differs from main's recorded figures, or was not compared:\n- ${benchReport.join('\n- ') || 'no comparison'}\nCompare with main and return the result. Measure main only when your step 1 finds no stored figures of its current commit, building the base with PREFIX=$PWD/tmp/.toolchain SPINEL_CACHE_DIR=$PWD/build/spinel-cache.${capLine('bench')}`,
          calibrate('bench', { agentType: 'benchmark', schema: withCalls(BENCH) })), callCap('bench'))
        if (!b) { stopped = 'the benchmark agent returned no result'; return false }
        verdict('bench', !b.blocking.length)
        note(`benchmark at ${b.head}: ${b.report.join('; ')}`)
        reviewed('bench', !b.blocking.length, b.head, { blocking: b.blocking.length })
        if (b.blocking.length) { blocked = `Blocking regressions:\n- ${b.blocking.join('\n- ')}`; by = 'bench' }
      }
    }
    // Fix in place: the findings of this round's reviews, offered once.
    const fresh = freshOffers(fixes)
    reviewFindings = []
    const place = inPlaceRound(Boolean(blocked), fresh.length, rework, ROUNDS + extra)
    if (place === 'record') note(`fix in place: ${fresh.length} finding(s) left at the round limit, recorded for docs/findings/`)
    offer(fresh, place === 'with' || place === 'alone')
    if (place === 'with') blocked += `\n\n${inPlaceTask(fresh)}`
    if (place === 'alone') {
      // A records-only fix stands on this round's check, security, and
      // bench passes (settleFrom, settled); any other reruns them all.
      // Only this path computes it: a blocking round is 'with'
      // (inPlaceRound), so it never settles.
      const from = settleFrom(ran, fresh)
      note(`fix in place: ${fresh.length} finding(s) in a round of their own; ${from ? `the check, security, and bench stand on ${from} when the fix changes only records, else they run again` : 'the check and security run again'} at its head`)
      phase('Implement')
      const before = head
      if (!(await contributor('fix', inPlaceTask(fresh)))) return false
      settleAt = settleAfter(from, before, head)
      continue
    }
    if (!blocked) return true
    const refused = fixes ? '' : resumeFix(by, Number(state.review_fixes || 0) + reviewFixRounds)
    if (refused) { stopped = `${refused}, at ${head}: ${blocked.split('\n')[0]}`; return false }
    if (!mayFix()) { stopped = `still blocked after ${rework} fix rounds: ${blocked.split('\n')[0]}`; return false }
    if (!fixes) {
      reviewFixRounds++
      note(`resumed past the push: a review blocked at ${head}; one review fix round, pushed with --review-fix`)
    }
    phase('Implement')
    if (!(await contributor('fix', blocked))) return false
  }
}

// The run state of a resume result, { state, error }: the schema's `state`
// object, else the `state_json` string of an older or replayed result, whose
// leading JSON object is taken so text an agent appended (the 2026-11-23
// `</state_json>` and parameter fragment) is dropped. The state is flat and
// holds a change name; anything else is an error, never a throw.
function leadingObject(text) {
  const s = text.trimStart()
  if (s[0] !== '{') return s
  let depth = 0
  let quoted = false
  for (let i = 0; i < s.length; i++) {
    const c = s[i]
    if (quoted) {
      if (c === '\\') i++
      else if (c === '"') quoted = false
    } else if (c === '"') quoted = true
    else if (c === '{') depth++
    else if (c === '}' && --depth === 0) return s.slice(0, i + 1)
  }
  return s
}
function readResumed(result) {
  let raw = result && result.state !== undefined ? result.state : result ? result.state_json : undefined
  if (typeof raw === 'string') {
    try { raw = JSON.parse(leadingObject(raw)) } catch (e) { return { state: null, error: `the run state is not JSON: ${e.message}` } }
  }
  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) return { state: null, error: 'the run state is not a JSON object' }
  if (typeof raw.change !== 'string' || raw.change === '') return { state: null, error: 'the run state names no change' }
  return { state: raw, error: '' }
}
// The resume start, once more with a note when its state cannot be read (a
// stopped result needs no state): { resume, state, error }, the error that of
// the second reading when both fail. start(extra) runs the agent.
async function resumeState(start) {
  let resume = await start('')
  let read = resume && resume.status === 'done' ? readResumed(resume) : { state: null, error: '' }
  if (read.error) {
    resume = await start(`\nThe run state of your last answer could not be read (${read.error}). Answer again: state is the JSON object of the trusted command as an object, with no text after it.`)
    read = resume && resume.status === 'done' ? readResumed(resume) : { state: null, error: read.error }
  }
  return { resume, state: read.state, error: read.error }
}

phase('Resume')
const resumed = await resumeState((extra) => agent(
  `Prepare the delivery of one change. Input: ${JSON.stringify(input)}.
1. \`git fetch -q origin\`. The change name is input.change, or an existing change under openspec/changes/ that the brief names, or a kebab-case name of 2 to 5 words derived from the brief.
2. In the main checkout, before any worktree links the toolchain, \`make doctor\`; run \`make toolchain\` when it fails and stop when that fails too.
3. The branch is input.branch, or the one in build/pipeline/<change>.json, or <type>/<change> with the type from CLAUDE.md's Branch naming. Run \`sh tools/run_state.sh lane-open <change> <branch>\` in the main checkout, which stays on main: it makes the change's worktree tmp/.lane-<change> on the branch (local, else origin's, else new from origin/main), keeps it on a resume, and links the shared toolchain, compile cache, and run states; stop with its message when it fails.
4. Run \`sh tools/run_state.sh init <change> <branch>\`; when it refuses (a merged change name), stop with its message as reason. Then \`cd tmp/.lane-<change> && sh tools/run_state.sh trusted <change>\`, and return the JSON object it printed as the object state (each key with its string value, no text outside the object), with \`git -C tmp/.lane-<change> rev-parse --short=12 HEAD\` as head.
5. Run \`cd tmp/.lane-<change> && sh tools/run_state.sh plan-needed <change>\` and return its one line verbatim as plan; its exit 1 means not needed, not a failure.${capLine('resume')}${extra}`,
  calibrate('resume', { agentType: 'runner', schema: RESUME, label: extra ? 'resume again' : 'resume' })))
const resume = resumed.resume
if (!resume || resume.status !== 'done') {
  stopped = `resume stopped: ${resume ? resume.reason : 'no result'}`
} else if (resumed.error) {
  stopped = `resume stopped: ${resumed.error}`
} else {
  state = resumed.state
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
// when the queue needs a decision, which plan-needed alone finds (the change
// is not the queue's head, a proposal or finding waits, or a periodic
// security review failed with no change planned after it merged since): a brief for the
// head item keeps the order, so it plans no more than the change's name
// would (planSkipped). Otherwise the head item is taken as written, with its
// size as the estimate, and the brief still reaches the contributor. A
// brief that is only the change name gives the contributor nothing to
// work from, so it reads the queue item naming the change in its lane
// queue itself: the
// item never passes through a model's output.
const planLine = resume && typeof resume.plan === 'string' ? resume.plan.split('\n')[0] : ''
// The resume brief names the lane queues plan-needed read: the waiting
// sprint plan's under build/plan/ only while one waits there, the docs/
// lane queues otherwise.
function resumeBrief(change, line) {
  const LANES = 'queue-feature.md or queue-backlog.md'
  const queueFile = /build\/plan\/queue-/.test(line) ? `build/plan/${LANES}, the waiting sprint plan,`
    : /docs\/queue-/.test(line) ? `docs/${LANES}` : `docs/${LANES} (build/plan/ while a sprint plan waits there)`
  return `the item of ${queueFile} that names \`${change}\`, read there as written (when no item names it, the existing OpenSpec change)`
}
// A delivery's planner writes only under its own plan directory, so two
// lanes' planners never overwrite each other; the sprint planner keeps
// build/plan/ itself. tools/tools_test.sh runs these helpers.
function planDir(change) {
  return `build/plan/${change}/`
}
// The package step's plan line (planner-loop): history, then groom, then
// plan-apply for the change's own lane. groom applies a waiting sprint plan
// in the first delivery that packages after the sprint closed, whose
// history then appends every lane's rows, so the sprint's records (the
// rows, the groomed backlog, both lane queues, the sprint row) land in its
// own pull request; it does nothing when no plan waits, another change
// carries it, or a sprint security finding holds it. plan-apply after it
// keeps the lane queue the delivery planner wrote.
// tools/tools_test.sh runs this helper.
function packagePlan(state, planned) {
  const records = state.records === 'skip'
    ? 'run no history and no groom: this change\'s run state excludes the planning records (records=skip), and both say so for it'
    : `run \`sh tools/run_state.sh history ${state.change}\`, which appends its lane's rows (every lane's when it carries a waiting sprint plan), then \`sh tools/run_state.sh groom ${state.change}\`, which applies a waiting sprint plan once, the groomed backlog, both lane queues, and the sprint's row committed with this change, and says when none waits, another change carries it, or a security finding holds it`
  return planned === 0
    ? `The planner did not run: this change was taken from the head of its lane queue as written. Copy nothing from build/plan/ and run no plan-apply; first ${records}; then remove this change's item from its lane queue and renumber the rest.`
    : `First ${records}; then run \`sh tools/run_state.sh plan-apply ${state.change}\`, which overwrites this change's lane queue with ${planDir(state.change)}, before any edit of your own.`
}
// Whether the Plan phase is skipped: no merge, plan, or implement record
// yet, and plan-needed's line says not needed, whatever the brief says.
// tools/tools_test.sh runs this helper.
function planSkipped(state, line) {
  return !state.merged && !state['phase.plan'] && !state['phase.implement'] && /^not needed:/.test(line || '')
}
// The planner prompt's line for a failing periodic security review that
// plan-needed names first: the review run, whose show the planner reads,
// since its pending list holds merged run states only and merged_since
// clears the review at the merge of the next change whose plan-needed
// read the review runs after the review was recorded, or passed_since at
// a later passing whole-tree periodic security review (review-coverage,
// review-coverage-b, periodic-clear-rules); otherwise
// nothing. tools/tools_test.sh runs this helper.
function planReview(line) {
  const m = /^needed: ((?:review|sprint)-[0-9][a-z0-9-]*) records a failing periodic security review at ([0-9a-f]{7,40}),/.exec(line || '')
  return m ? ` plan-needed: \`${m[1]}\` records a failing periodic security review at ${m[2]}; read \`sh tools/run_state.sh show ${m[1]}\` and apply your security-first step to its findings.` : ''
}
// The user's decision comes first (the user's of 2026-11-24, after a split
// of a brief the user decided as one delivery): the planner's start carries
// the rule and the brief's USER DECISIONS ahead of the rubric, and a plan
// that splits a brief decided as one delivery stops the run.
const USER_FIRST = 'User decision first: what the brief\'s or queue item\'s USER DECISIONS or the user\'s recorded request says (one delivery, no split, a split as the user says, the items, their order, a sprint\'s contents) you follow as written, before the tiers, the sprint composition, and the size check, and never split, reorder, or drop against it; where you would have decided otherwise, record in a decision that the user\'s decision overrode your rule, with the rule and its number, instead of acting on it.'
function userDecisionsOf(text) {
  const parts = String(text || '').split(/USER DECISIONS:|User decisions:/)
  if (parts.length < 2) return ''
  const found = parts[parts.length - 1].split(/\bRULES:/)[0].trim()
  return /^none\.?$/i.test(found) ? '' : found
}
function userFirst(text) {
  const found = userDecisionsOf(text)
  return found ? `${USER_FIRST} The USER DECISIONS: ${found}` : USER_FIRST
}
function splitAgainstUser(text, plan) {
  if (!/\b(one delivery|single delivery|no split|not (be )?split|never split|do not split|without a split)\b/i.test(userDecisionsOf(text))) return ''
  const lines = (plan.decisions || []).map((d) => String(d.decision)).concat(plan.notes || [])
  const split = lines.find((l) => /\b(split|splits|splitting)\b|queue the rest|deliver the first/i.test(l) && !/overr(ode|ide|iding)|\b(no|not|never) split/i.test(l))
  return split ? `the planner split a brief the user decided as one delivery: ${split.slice(0, 160)}` : ''
}
const request = typeof input.brief === 'string' && input.brief.trim() !== '' && input.brief.trim() !== state.change
const brief = request ? input.brief : resumeBrief(state.change, planLine)
if (!stopped && planSkipped(state, planLine)) {
  phase('Plan')
  const size = /estimated (small|medium|large)\b/.exec(planLine)
  if (size) estimate = size[1]
  const queued = criticalOf(planLine)
  if (queued) { critical = queued.rule; note(`critical by rule ${queued.rule}: ${queued.path}`) }
  else if (/critical/.test(planLine)) note('plan: critical value not read')
  planned = 0
  note(`plan: skipped, ${planLine}`)
  phaseDone('plan', head)
}
if (!stopped && !state.merged && !state['phase.plan'] && !state['phase.implement']) {
  phase('Plan')
  planned = 1
  const p = await measured('plan', () => agent(
    `${intro()} ${userFirst(brief)} Plan the queue for this delivery. Brief: ${input.brief || 'the existing OpenSpec change'}. Write your files under ${planDir(state.change)}, this delivery's own plan directory. Among your notes, give the locations the change edits, path:line each, which the contributor starts from (no scout runs).${planReview(planLine)}${capLine('planner')}`,
    calibrate('planner', { agentType: 'planner', schema: withCalls(PLAN) })), callCap('planner'))
  if (!p) stopped = 'the planner returned no result'
  else {
    note(`plan: ${p.decisions.map((d) => `${d.decision} (${d.evidence})`).join('; ') || 'no change to the queue'}`)
    planNotes = p.notes
    // Stored with the figures, so budget and the history row keep it after
    // the queue item leaves the queue.
    if (SIZES.includes(p.estimate)) estimate = p.estimate
    const rule = criticalOf(p.critical)
    if (rule) { critical = rule.rule; note(`critical by rule ${rule.rule}: ${rule.path}`) }
    else if (String(p.critical || '').trim()) note(`plan: critical value not read: ${String(p.critical).trim().slice(0, 80)}`)
    if (p.records === 'skip') excludeRecords('the planner')
    const against = splitAgainstUser(brief, p)
    if (p.security_first.length) stopped = `security first: deliver the fix of ${p.security_first.join('; ')} before this change`
    else if (against) stopped = against
    else phaseDone('plan', head)
  }
}

// A brief may exclude the planning records from the package step: the
// run state's records=skip, which history honors for the change:
// no closable line, so the flush at the end of verify() writes it, before
// the package step.
function excludeRecords(why) {
  if (state.records === 'skip') return
  state.records = 'skip'
  queue(`sh tools/run_state.sh set ${state.change} records skip`, head)
  note(`planning records excluded by ${why}: the package step runs no history`)
}
if (!stopped && !state.merged && input.records === 'skip') excludeRecords('the input')

if (!stopped && !state.merged) {
  if (!state['phase.implement']) {
    phase('Implement')
    const done = await contributor('implement', `${LOCATIONS}${planNotes.length ? `\nPlan notes:\n- ${planNotes.join('\n- ')}` : ''}`)
    if (done) phaseDone('implement', head)
  }

  // A second push is refused, so a restart finds the package step done from
  // the push and the pull request it recorded (tools/run_state.sh push and
  // tools/open_pr.sh wait); its phase line waits for the last flush. The
  // pull request is opened by .github/workflows/open-pr.yml from the pr.md
  // the contributor commits before its push, never by a session's tool, and a
  // package step that returns no number stops the run before the merger. A
  // restart after a push that recorded no number only waits for it.
  const step = stopped ? 'merge' : packageStep(state)
  if (step === 'wait') {
    phase('Package')
    const done = await contributor('wait', `The push recorded ${state.pushed}, but no pull request number: wait for it; commit nothing and push nothing.`)
    if (done) state.pr = packagedPr(done)
    if (done && !state.pr) stopped = 'no pull request appeared for the branch ' + state.branch + ': read the open-pr workflow\'s log'
    else if (done) phaseDone('package', head)
  }
  if (step === 'package') {
    if (await readyToPackage()) {
      phase('Package')
      const plan = packagePlan(state, planned)
      const done = await contributor('package', `Non-blocking findings to append to docs/findings/${state.change}.md (mkdir -p docs/findings first, as a fresh checkout lacks it, then a shell append; never read docs/backlog.md):\n- ${handOver().join('\n- ') || 'none'}\n${plan}${settledTesting()}`)
      if (done) state.pr = packagedPr(done)
      if (done && !state.pr) stopped = 'no pull request appeared for the branch ' + state.branch + ': read the open-pr workflow\'s log'
      else if (done) phaseDone('package', head)
      if (done && !stopped) await prTextReview()
    }
  }

  // One agent waits for CI, up to 30 minutes a start, and merges. Pending
  // CI is asked again, at most WAITS times; red CI goes back to the
  // contributor's fix loop. The CI and merge phase lines wait for the last
  // flush; a restart after the merge reads merged, which the merger wrote.
  if (!stopped) {
    phase('Merge')
    let waits = 0
    let bodyFixed = false
    // A resume past the push holds no check or review of this start, and
    // the run state's could be branch-written (a pass, or the branch's own
    // tools/gates.sh saying they settled): they run again at the head, the
    // security review over the whole diff, and only this start's verdicts
    // reach RECORDS or narrow a review. A start that ran them all keeps its
    // records, though the package step committed after them: the merge
    // gates' settled_at allows that records-only diff. A blocking security
    // review gets one fix round a run (resumeFix), the security
    // review over the whole diff again, pushed as a review fix; a failed
    // check or benchmark, or a second review fix, stops the run. A head
    // past the recorded push once the check and reviews passed is pushed as
    // that review fix whichever start committed it (resumePush).
    if (!ranAll(ran)) {
      note('resumed past the push: the check and the reviews run again at the head')
      if (!(await verify(false)) && !stopped) stopped = `the check or a review did not pass at ${head} on resume`
      phase('Merge')
      const push = stopped ? '' : resumePush(state.pushed, head, state.review_fixes)
      if (push && push !== 'push') stopped = `${push}: nothing pushes it`
      else if (push) {
        await contributor('push', `Push the review fix of this resume past the push with \`sh tools/run_state.sh push ${state.change} --review-fix\`, not --ci-fix; the findings that arrived after the package step are recorded in the run state at the close, not appended.`)
      }
    }
    for (; !stopped;) {
      // GitHub matches the expected head against the full sha, and only the
      // head the push recorded is the one the reviews and gates covered.
      const pushed = pushedHead(state.pushed, head)
      if (!pushed) { stopped = `the pushed head ${state.pushed || 'none'} is not a full sha beginning with the reported head ${head}`; break }
      const lines = mergeLines(pushed)
      const m = await measured('merge', () => agent(
        `${intro()}${MERGER_CLOSE}${mergeTarget()} The pushed head is ${pushed}. Wait for CI at it${waits ? ' (it was still running when you last returned; keep waiting)' : ''}, and merge the pull request if CI is green and every merge gate passes.\nThe green line: \`${lines.green}\`\nThe red line: \`${lines.red}\`\nTool calls: at most ${FIXED_CAPS.merger} in this start besides your CI waits, and 2 more for each wait.`,
        calibrate('merger', { agentType: 'merger', schema: withCalls(MERGE) })), mergerCap)
      if (!m) { stopped = 'the merger returned no result'; break }
      ciWaitCalls = (ciWaitCalls || 0) + 2 * waitsOf(m)
      // The CI steps' seconds, read once the run finished, by the record
      // start or the closing start, whose guard is main's after the merge.
      if (m.ci === 'green' || m.ci === 'red') queue(`sh tools/run_state.sh ci-stages ${state.change} ${pushed}`, pushed)
      const checks = (m.checks || []).join('; ')
      note(`CI at ${m.head}: ${m.ci}${m.minutes ? ` in ${m.minutes} min` : ''}${m.ci === 'pending' && checks ? ` (${checks})` : ''}`)
      if (m.ci === 'pending' && !(m.waited >= 30)) note(`the merger returned pending after waiting ${Number.isFinite(m.waited) ? m.waited : 'unknown'} of 30 minutes`)
      // A red that a later green run of the same check on the head
      // superseded is no failure: asked again, never a fix round.
      if (m.ci === 'red' && staleRed(m.checks)) {
        note(`CI red at ${m.head} superseded by a green run of the same check: asked again, no fix round`)
        if (++waits < WAITS) continue
        stopped = `CI at ${m.head} read red on superseded runs only, ${WAITS} times: ${checks}`
        break
      }
      if (m.ci === 'pending') {
        if (++waits < WAITS) continue
        stopped = `CI stalled at ${m.head} after ${WAITS} waits of up to 30 minutes: ${checks || 'no check state returned'}`
        break
      }
      waits = 0
      if (m.ci === 'green' || m.ci === 'red') verdict('ci', m.ci === 'green')
      if (Number.isFinite(m.minutes) && m.minutes > 0) ciMinutes = m.minutes
      // CI ran at the pushed head, the one the merger checked the pull request
      // against; the merge is recorded at the squash commit the run state
      // resolves (mergeDone), the merger's sha only reported beside it.
      if (m.ci === 'green') { state.ci = `green ${pushed}`; phaseDone('ci', pushed) }
      if (m.merged) {
        mergeDone(m.sha)
        note(`merged: ${m.subject}; the merger reported ${m.sha || 'no sha'}, recorded at the run state's squash commit${m.branch_deleted ? '' : ' (branch deletion refused)'}`)
        break
      }
      // A red only on the scan of the pull request body: the contributor
      // fixes the body file, commits it as pr.md, and pushes it as a CI fix,
      // from which open-pr sets the pull request's title and body; the merge
      // goes on at the new head without a fix round, once per run.
      if (m.ci === 'red' && m.body_only === true && !bodyFixed) {
        bodyFixed = true
        note('CI red only on the scan of the pull request body: the body is fixed without a fix round')
        if (!(await contributor('body', `CI is red only on the scan of the pull request's title or body; its log:\n${m.log_excerpt || ''}`))) break
        continue
      }
      // Main moved under a green pull request: merge-main, the check (the
      // reviews only when the merge changed files of the change), and one
      // main-moved push a run, then CI and the merge again, no fix round;
      // first.ci keeps the green before the move.
      const moved = mainMoved(m, Number(state.main_moved || 0) + mainMovedPushes)
      if (moved === 'merge') {
        mainMovedPushes++
        note(`the merge at ${m.head} was refused because main moved: ${m.problem || 'no reason given'}; merge-main, the check, and one main-moved push`)
        const from = carryFrom(ran)
        if (!(await contributor('moved', movedTask(m.problem)))) break
        movedFrom = from
        if (!(await verify())) break
        phase('Merge')
        if (!(await contributor('push', `Push the merge of the moved main with \`sh tools/run_state.sh push ${state.change} --main-moved\`, not --ci-fix; the findings that arrived after the package step are recorded in the run state at the close, not appended.`))) break
        continue
      }
      if (moved) { stopped = moved; break }
      if (m.ci !== 'red' || !mayFix()) {
        stopped = m.ci === 'green' ? `not merged: ${m.problem || 'no reason given'}` : `CI ${m.ci}${m.step ? ' at ' + m.step : ''}${m.problem ? ': ' + m.problem : ''}${m.ci === 'red' ? ` after ${rework} fix rounds` : ''}`
        break
      }
      if (!(await contributor('fix', `CI failed at ${m.step}; its log:\n${m.log_excerpt || ''}`))) break
      if (!(await verify())) break
      phase('Merge')
      if (!(await contributor('push', 'Push the CI fix; the findings that arrived after the package step are recorded in the run state at the close, not appended.'))) break
    }
  }
}

// The close, one retrospective start in every run: it runs the records left
// since the last flush with this start's own phase lines and the metric
// line, looks back when the change merged and no retrospective ran yet,
// says whether sprint-planning is due, and writes the report. The line
// and the summary are built from the same figures at once, so once the line
// has run the run state's totals equal the summary's; this start's own cost
// is the one figure recorded nowhere. No other start records: a line the
// close did not run is reported as not recorded. The delivery never runs
// the periodic review: sprint-planning (/sprint), its own workflow, reviews
// the sprint's combined diff once its counted changes merged, and the report
// says when it is due. A stopped run's unpushed commits stay on its local
// branch for a resume.
const looking = !stopped && Boolean(state.merged) && !state['phase.retro']
phase('Close')
// The findings that arrived after the package step become late-finding
// notes of a merged run, which the note command stamps with the merged
// commit, held-finding notes of one pushed but unmerged, which a merged
// resume notes late, and unpushed-finding notes of one stopped before the
// push, which a resume's package step hands over (a late finding before
// the merge would be refused). A line the close profile refuses (a check or review
// record a failed flush left) is reported, not recorded: a resume runs
// that check or review again.
recordLate()
const refused = pending.filter((l) => !CLOSABLE.test(l))
if (refused.length) note(`not recorded, refused by the close profile: ${refused.join('; ')}`)
const closeRecords = closeLines(looking)
const records = recordLine(closeRecords)
const figures = summary()
const close = await measured('close', () => agent(
  `Change \`${state.change || input.change || 'unknown'}\`${state.branch ? ` on branch \`${state.branch}\`` : ''}. ${state.merged ? `It merged: its merged commit is the squash commit of pull request #${state.pr || 'unknown'} on main whose subject ends with its number, the commit \`sh tools/run_state.sh get ${state.change} merged\` prints, never the sha the merger returned; a refused line of the record line prints refused: N and the rest still run.` : 'It did not merge.'} ${looking ? 'Run the retrospective steps, then the report steps.' : 'Skip the retrospective steps; run the report steps.'}\nThe record line: ${records ? `\`${records}\`` : 'none; skip that step and return recorded true.'}\nThe run's figures: ${figures}.\nWorkflow notes:\n- ${notes.join('\n- ')}\n${stopped ? 'The run stopped: ' + stopped : 'The run finished.'}${capLine('close')}`,
  calibrate('close', { agentType: 'retrospective', schema: withCalls(CLOSE) })), callCap('close'))
if (close && looking) {
  state['phase.retro'] = state.merged ? SQUASH : head
  note(`retrospective: ${close.proposals.map((x) => `${x.proposal} (${x.evidence})`).join('; ') || 'no proposal'}; ${close.review_due || 'review-due not read'}`)
}
const refusedLines = refusedNote(closeRecords, close)
if (refusedLines) note(refusedLines)
else if (records && (!close || !close.recorded)) note(`the closing start did not record the run${close && close.record_output ? `: ${close.record_output}` : ''}; its lines are not recorded`)
const sprintDue = close && looking && close.due ? 'sprint-planning is due: start /sprint before the next /deliver' : ''
if (sprintDue) note(sprintDue)
const after = `${sprintDue ? `\n- Sprint: ${sprintDue}` : ''}${stopped && looking ? `\n- Stopped after the close: ${stopped}` : ''}`
return close ? `${close.report}${after}` : `No report; notes:\n${notes.join('\n')}${stopped ? '\nStopped: ' + stopped : ''}`
