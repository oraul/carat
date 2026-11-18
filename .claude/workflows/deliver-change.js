export const meta = {
  name: 'deliver-change',
  description: 'Deliver one change to main through fixed phases: plan, scouts, contributor, checker, quality and security review, benchmark, package, CI and merge, close (records, retrospective, and report in one start); the sprint-end review is sprint-planning\'s',
  whenToUse: 'Every change to this repository, started by /deliver with a change name or a brief; it resumes from build/pipeline/CHANGE.json',
  phases: [
    { title: 'Resume', detail: 'branch, toolchain, and the run state' },
    { title: 'Plan', detail: 'planner: the next queue from the metrics history; security findings first' },
    { title: 'Scout', detail: 'one scout per edited map area without a current pack, at most three' },
    { title: 'Implement', detail: 'contributor: propose and apply, committing early' },
    { title: 'Check', detail: 'the fast stages through make in a start that runs only the check lines; the checker reads a failed stage\'s log; CI runs the rest' },
    { title: 'Quality', detail: 'quality reviewer: code-review and the repository rules, beside security on the same commit' },
    { title: 'Security', detail: 'security reviewer on the committed diff, beside quality; never skipped' },
    { title: 'Benchmark', detail: 'allocations and rounds against the figures recorded for main; the agent against main only when they differ' },
    { title: 'Package', detail: 'contributor: archive, gates, pr.md, one push, the pull request open-pr opens' },
    { title: 'Merge', detail: 'merger: wait for CI, red back to the contributor; main\'s merge gates, squash with the trailer, verify main' },
    { title: 'Close', detail: 'retrospective: the last records, the proposals, the budget and review-due lines, and the report, in one start' },
  ],
}

// args: { change?, brief?, branch?, packs?: [path], areas?: [string],
// records?: 'skip' }, or a
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
// that ran the workflow sees, /deliver adds with tools/run_state.sh usage, and
// each start's tier-weighted tokens with tools/run_state.sh tokens. The
// run state's phase.* and review.* lines and the figures are the script's
// own: it builds each command from a schema-checked result. One agent that
// reads nothing else runs the queued lines with the metric line (flush) at
// the end of verify() only when a check or review record is among them,
// since the pre-push and merge gates read those and no guarded agent may
// write them; the closing start runs every other line at the end, where
// the package, CI, and merge phases wait (a resume reads pushed, pr, and
// merged instead), under the guard's close profile, which allows only the
// phases no merge gate reads. The check's run start and the merger run the
// metric line first, so a fix round is counted before its check.
// tools/agent_guard.sh keeps the other agents off the phase and review
// commands, and the merger's records gate compares the file with what the
// script received. Each start's model tier and effort come from
// CALIBRATION, and the run state records them beside its figures.
// Only the arguments above are kept: a field passed beside them, such as a
// chat message, never reaches a start's prompt, which carries the brief or
// the resume brief only.
const ARG_KEYS = ['change', 'brief', 'branch', 'packs', 'areas', 'records']
function startInput(raw) {
  const given = typeof raw === 'string' ? { brief: raw } : (raw || {})
  const kept = {}
  for (const key of ARG_KEYS) if (given[key] !== undefined) kept[key] = given[key]
  return kept
}
const input = startInput(args)
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
// Tool calls per agent start. CALL_CAPS holds a start's cap at a medium
// estimate, from the history's calls per phase; CALL_SCALE scales it by the
// estimate, rounded up, the medium figure applying while no estimate exists
// (the planner's start). FIXED_CAPS holds the starts whose work does not
// grow with the change (areas is the scout plan); the merger's is its work,
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
const CALL_CAPS = { planner: 20, scout: 30, implement: 90, fix: 40, package: 30, push: 15, moved: 15, body: 12, wait: 6, checker: 20, quality: 35, security: 35, bench: 20, close: 25 }
const CALL_SCALE = { small: 0.5, medium: 1, large: 1.5 }
const FIXED_CAPS = { resume: 12, areas: 10, record: 3, merger: 10, run: 8 }
const sizeWord = () => (SIZES.includes(estimate) ? estimate : 'medium')
const callCap = (kind) => (kind in FIXED_CAPS ? FIXED_CAPS[kind] : Math.ceil(CALL_CAPS[kind] * CALL_SCALE[sizeWord()]))
const capLine = (kind) => `\nTool calls: at most ${callCap(kind)} in this start (${kind in FIXED_CAPS ? 'a fixed cap' : `the ${kind} cap at ${SIZES.includes(estimate) ? `the ${estimate} estimate` : 'the medium figure, with no estimate yet'}`}). Count them; on reaching the cap, stop and return the schema with what is done, saying the cap stopped you.`
// The merger's waits are 3, 4, then 5 minutes (.claude/agents/merger.md), so
// the minutes it waited give its waits, and every wait 2 calls of its cap.
const waitsOf = (r) => { const w = Number(r && r.waited); return w > 0 ? (w <= 3 ? 1 : w <= 7 ? 2 : 2 + Math.ceil((w - 7) / 5)) : 0 }
const mergerCap = (r) => FIXED_CAPS.merger + 2 * waitsOf(r)
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
const SCOUT_AREA = { type: 'object', properties: { area: { type: 'string' }, question: { type: 'string' }, locations: { ...LINES, description: 'path or path:line of existing code the change edits in this area, each a path the area\'s section of docs/codebase-map.md names, itself or by its directory' } }, required: ['area', 'question', 'locations'] }
const SCOUT_PLAN = {
  type: 'object',
  properties: {
    current: LINES,
    unread: { ...LINES, description: 'the locations the change edits that a current pack does not list, each path or path:line, for the contributor to read itself' },
    needed: { type: 'array', items: SCOUT_AREA },
  },
  required: ['current', 'needed'],
}
// When a pack an earlier change left serves this one: a pack of the area
// whose files read are unchanged at main is reused, and the locations it
// does not list go to the contributor to read itself, never to a new scout
// of the whole area (scout-pack-reuse; .claude/agents/scout.md step 3
// applies the same rule).
const PACK_CURRENT = 'a pack under tmp/scout/ is current for an area when its Commit: is origin/main or `git diff --quiet <its commit> origin/main -- <its Files read>` passes; reuse it even when its Locations: line lacks some location the change edits in that area, and list each location it lacks under unread; an area with a current pack needs no scout'
// The scouts a plan starts: an area given no location the change edits
// there (a file the map places in no area, such as a root LICENSE) starts
// none, nor one whose every location the brief names by path (named: the
// contributor, which holds the brief, reads them itself), and the rest are
// cut at the room the current packs leave. tools/tools_test.sh runs this
// helper.
function scoutTargets(plan, max, brief = '') {
  if (!plan) return { current: [], needed: [], unplaced: [], beyond: [], named: [], unread: [] }
  const placed = plan.needed.filter((n) => Array.isArray(n.locations) && n.locations.some((l) => String(l).trim()))
  const pathOf = (l) => String(l).trim().replace(/:[0-9][0-9,-]*$/, '')
  const named = placed.filter((n) => n.locations.every((l) => !pathOf(l) || String(brief).includes(pathOf(l))))
  const scouted = placed.filter((n) => !named.includes(n))
  const room = Math.max(0, max - plan.current.length)
  return { current: plan.current, needed: scouted.slice(0, room), unplaced: plan.needed.filter((n) => !placed.includes(n)), beyond: scouted.slice(room), named, unread: (plan.unread || []).concat(...named.map((n) => n.locations.filter((l) => pathOf(l)))) }
}
// A scout's prompt: its area, the locations the change edits there, which
// bound what it reads (.claude/agents/scout.md), and the question.
function scoutPrompt(n, brief) {
  return `Area: ${n.area}. Locations: ${n.locations.join(', ')}; read only what these locations need. Question: ${n.question}. The change, for scope only: ${brief}. Write the pack and return its path.`
}
// The contributor's line for the locations no pack covers, which it reads
// itself at those locations only. tools/tools_test.sh runs this helper.
function unreadLine(unread) {
  return unread && unread.length ? ` Locations no pack covers, read them yourself at those locations only: ${unread.join(', ')}.` : ''
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
// The file:line a finding names: a quality finding "<commit> <file>:<line>
// ...", an advisory without the commit, or a security line "security SEV
// (C) <file>:<line> ...".
function findingAt(text) {
  const m = /(?:^|\s)([A-Za-z0-9_.][^\s:()]*:[0-9]+)/.exec(String(text || ''))
  return m ? m[1] : ''
}
// Whether a blocking quality finding at LOCATION repeats an advisory the
// run already kept (EARLIER): a re-raise, which a fix round never blocks
// on. Security findings never pass through it (securityBlocking).
function reRaised(location, earlier) {
  return !!location && !/:0$/.test(location) && earlier.some((e) => findingAt(e) === location)
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
    .concat(Object.keys(firstPass).map((g) => `first.${g}=${firstPass[g]}`), [`rework=${rework}`, `extra=${extra}`, `stop=${stopKind}`])
  if (ciMinutes !== null) pairs.push(`ci_min=${Number(ciMinutes).toFixed(1)}`)
  if (Number.isInteger(ciWaitCalls)) pairs.push(`ci_wait_calls=${ciWaitCalls}`)
  if (SIZES.includes(estimate)) pairs.push(`estimate=${estimate}`)
  if (planned !== null) pairs.push(`planned=${planned}`)
  for (const k of Object.keys(calibrated)) pairs.push(`calib.${k}=${calibrated[k]}`)
  const safe = pairs.filter((p) => /^[a-z0-9_.-]+=([0-9./]+|small|medium|large|none|rounds|(cheap|session)\/(low|session))$/.test(p))
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
  extra = Number(state['metric.extra']) || 0
  lastStop = /^[a-z]+$/.test(state['metric.stop'] || '') ? state['metric.stop'] : ''
  if (/^[01]$/.test(state['metric.planned'] || '')) planned = Number(state['metric.planned'])
  if (state['metric.ci_min']) ciMinutes = Number(state['metric.ci_min'])
  if (/^[0-9]+$/.test(state['metric.ci_wait_calls'] || '')) ciWaitCalls = Number(state['metric.ci_wait_calls'])
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
  held = heldFindings(noted)
  // A close before the push handed nothing yet: its findings go back into
  // the list the package step hands over, once a resume has not pushed
  // either (a pushed one's package step handed them).
  if (!state.pushed) for (const t of heldFindings(noted, 'unpushed-finding')) addBacklog(t)
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
// only itself (an && chain lost sprint-14-records its merge, retro, and
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
// Runs the queued records with the metric line through one agent, only
// when a check or review record is queued, which the pre-push and merge
// gates read and only an unguarded start may write; every other line and
// the figures wait for the closing start. The agent's own cost reaches the
// next line.
async function flush() {
  if (!pending.some((l) => !CLOSABLE.test(l))) return true
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
// keeps and the add writes into the copy, so a planted object fails the
// line before main's gates run. Given a head, fsck reads no index or
// reflog, so another lane's work in progress does not fail it.
// fsck ignores replace refs, so a refs/replace entry pointing main's
// gates.sh blob at a valid planted one would pass it while the add
// checked out the planted text: every pinned git runs with
// --no-replace-objects, and the line stops before the add when any
// refs/replace entry stands.
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
    green: `cd ${laneDir(state.change)} && git worktree prune; git worktree remove --force ${MERGE_GATES}; ${first(ci('green'))} && ${originCheck()} && ${PINNED_GIT} fetch -q --refmap= origin +refs/heads/main:refs/remotes/origin/main && ${PINNED_GIT} for-each-ref refs/replace | wc -l | grep -q -x -E ' *0' && ${PINNED_GIT} worktree add -q --detach ${MERGE_GATES} origin/main && ${PINNED_GIT} fsck --no-dangling --no-progress origin/main && CHANGE=${state.change} RECORDS="${records.join(' ')}" sh ${MERGE_GATES}/tools/gates.sh merge build/pipeline/${state.change}.body.md`,
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
// duplicates, for docs/findings/CHANGE.md; the findings handed to the contributor
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
// over, so they never reach held and are written once.
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
  return `Mode: ${mode}. Brief: ${briefText}. ${detail}${mode === 'implement' || mode === 'fix' ? `\n${MERGE_MAIN}${SELF_CHECK}` : ''}`
}
// An implement or fix start first takes in a main that moved while the
// delivery ran (parallel-lanes-b), so the checks and reviews cover the merge.
const MERGE_MAIN = 'First run `sh tools/run_state.sh merge-main <change>` in the worktree: it merges a moved origin/main into the branch, never a rebase, both sides of the appended records kept; on a conflict it names, follow your push mode\'s conflict rules.'
// The contributor's self-check before an implement or fix start returns
// (its agent file's implement step 5): the mechanical findings a review
// would otherwise block on.
const SELF_CHECK = '\nBefore returning, check yourself: every behavior the change adds or alters has a test that proves it; every document describing that behavior (README.md, docs/architecture.md, CLAUDE.md, docs/codebase-map.md, docs/compatibility.md, docs/actions.md) is updated; and the diff is compared against the brief, anything extra named in your summary.'

async function contributor(mode, detail) {
  if (mode === 'fix') rework++
  const key = mode === 'implement' || mode === 'fix' ? 'implement' : 'package'
  let result = null
  let more = ''
  for (let count = 0; ; count++) {
    result = await measured(key, () => agent(
      `${intro()} ${contributorTask(mode, brief, detail)}${more}\nFollow your Modes section for \`${mode}\` and return the schema.${capLine(mode)}`,
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
    more = `\nThis continues a start that ${result ? `reached its cap. It left:\n- ${step.left.join('\n- ')}` : 'returned no result, having reached its turn ceiling'}\nResume from the branch's commits, tasks.md, and the run state; redo nothing already committed or recorded.${pushedHint(mode, state.change)}`
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
  const [result, commit] = String(ran['review.quality'] || '').split(' ')
  if (!COMMIT.test(commit || '')) return ''
  const last = `\nThe last quality review, at ${commit}, was ${result}.`
  const blocked = result === 'blocked'
  // A fix round after a pass of this start reviews only the commits since it.
  const since = narrowedFrom(ran, 'quality', head)
  if (since) return `${last} Review only \`git diff ${since} HEAD\`, the commits since that pass, and block only on what that diff introduces.`
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
// skip naming both commits; the quality review alone runs, scoped by
// priorQuality to the commits since its pass at FROM.
let settledRound = null
let settleAt = ''
function settleRound(from) {
  settledRound = { at: head, from }
  const text = `advisory-only round at ${head}: only records changed since ${from}, where the check, the security review, and the benchmark passed; none of them rerun, the quality review scoped to the commits since`
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
// The commit both reviews of this start passed at, which tools/run_state.sh
// moved compares with the merged head; '' when they passed at different
// commits or not at all, so both run again.
function carryFrom(records) {
  const q = String(records['review.quality'] || '').split(' ')
  const s = String(records['review.security'] || '').split(' ')
  return q[0] === 'pass' && s[0] === 'pass' && COMMIT.test(q[1] || '') && q[1] === s[1] ? q[1] : ''
}
// The moved line the checker returns verbatim stands the reviews only
// when it says the change is the same at the head as at the reviewed
// commit (from); any other line, or none, runs them again. The line only
// decides: the record needs the run state's moved record at the head
// against the commit each review passed at, which only moved's exit-0 path
// writes (review refuses a carried=1 summary without it), so a forged line
// stops at the record, carrying nothing (moved-review-carry).
const CARRIED = /^moved: the change is the same at ([0-9a-f]{7,40}) as at ([0-9a-f]{7,40}):/
function carried(line, head, from) {
  const m = CARRIED.exec(String(line || '').trim())
  return !!m && sameCommit(m[1], head) && sameCommit(m[2], from)
}
// The main-moved contributor start's task: merge-main, a conflict merged
// by the push mode's rules, and a conflict both sides changed the same
// logic in a stop naming its files.
function movedTask(problem) {
  return `The merge was refused because main moved: ${problem || 'no reason given'}. Run \`sh tools/run_state.sh merge-main ${state.change}\` in the worktree. On the conflicts it names, merge origin/main by hand by your push mode's conflict rules and commit the merge with the trailer; where both sides changed the same logic, return stopped, with the question naming each such file. Commit nothing else and push nothing: the workflow reruns the check, and the reviews when the merge changed files of the change, before the main-moved push.`
}
// The reviewed commit tools/run_state.sh moved compares with the head the
// check after a main-moved merge passes at; '' once compared.
let movedFrom = ''
let mainMovedPushes = 0
// After the check passed at the merged head: both reviews carried to it
// when the moved line says the change is the same, recorded only where
// moved exited 0 at the head (above), else they run again (reviews()
// finds no pass at the head).
function carryReviews(line) {
  const from = movedFrom
  movedFrom = ''
  const text = String(line || '').trim()
  if (!carried(text, head, from)) { note(`after the merge of main: ${text || 'no moved line returned'}; the reviews run again at ${head}`); return }
  for (const k of ['quality', 'security']) reviewed(k, true, head, { blocking: 0, carried: 1 })
  note(`after the merge of main: ${text}; the quality and security reviews of ${from} stand at ${head}`)
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


// The quality review's request: a first pass (no earlier review scopes it)
// is asked for every blocking finding at once, so one fix round answers
// them (vim-folds-a found six one round at a time, in three rounds).
// tools/tools_test.sh runs this helper.
function qualityTask(scope, more) {
  const first = more || scope ? '' : ' This is the first pass: review the whole diff and return every blocking finding you can find, not only the first, so one fix round answers them all.'
  return `Review the committed diff and return the findings.${first}${more || scope}`
}
// The quality review at the head, with the scope priorQuality gives.
function qualityReview(scope, more) {
  return agent(`${intro()} ${qualityTask(scope, more)}${capLine('quality')}`,
    calibrate('quality', { agentType: 'quality-reviewer', schema: withCalls(QUALITY), phase: 'Quality', label: more ? 'quality-reviewer: continued' : 'quality-reviewer' }))
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
    : `${intro()} Run the security review on the committed diff and return the result.${priorSecurity()}${inPlaceCheck('security')}${capLine('security')}`,
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
  const scope = kinds.includes('quality') ? `${priorQuality()}${inPlaceCheck('quality')}` : ''
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
    // Every High or Medium in the change at confidence 8 or above blocks,
    // a re-rating of an earlier non-blocking finding included.
    const blocking = securityBlocking(s.findings)
    verdict('security', !blocking.length)
    for (const f of s.findings.filter((f) => !blocking.includes(f))) {
      const line = `security ${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`
      addBacklog(line)
      if (f.in_change) reviewFindings.push(line)
    }
    confirmInPlace('security', s.fixed_in_place)
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
    // A blocking finding at the location of an earlier advisory is a
    // re-raise, kept as an advisory.
    const raised = q.blocking.filter((f) => reRaised(findingAt(f), qualityAdvisory))
    if (raised.length) note(`quality re-raises kept as advisories: ${raised.join('; ')}`)
    q.blocking = q.blocking.filter((f) => !raised.includes(f))
    q.advisory = q.advisory.concat(raised)
    qualityBlocking = q.blocking
    qualityAt = q.head
    addAdvisories(q.advisory)
    reviewFindings.push(...q.advisory.map((a) => `quality advisory ${String(a).replace(/^[0-9a-f]{7,40} /, '')}`))
    confirmInPlace('quality', q.fixed_in_place)
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

// A resume past the push blocked at the head (fixes false): one fix round
// a run when the quality or security review blocked (by, the step that
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
// finding in code the change touches, of any severity, and each quality
// advisory of a review this start ran is offered to the contributor once,
// in the round of the blocking findings, or in a round of its own when
// nothing blocks and a round remains after it, so a blocking finding the
// fix brings still has one; at the last round it is recorded, not fixed.
// The contributor fixes those in files the change edits whose fix stays
// there and adds no behavior, each a task of tasks.md; the check and both
// reviews run again at the new head, whose reviewers list, verbatim, the
// ones they confirm fixed (fixed_in_place). Only those leave the findings
// handed to docs/findings/CHANGE.md; every other stays recorded. A resume
// past the push offers none. tools/tools_test.sh runs these helpers.
let reviewFindings = []
const offered = new Set()
const fixedInPlace = new Set()
let awaiting = { quality: [], security: [] }
function inPlaceRound(blocked, count, used, limit) {
  if (!count) return 'none'
  if (blocked) return 'with'
  return used + 1 < limit ? 'alone' : 'record'
}
function inPlaceTask(list) {
  return `Fix in place, in this round, each finding below that lies in a file the change edits when its fix stays in those files and adds no behavior: each one a task of the change's tasks.md, marked done with its fix, its delta spec updated when specified behavior moves. Leave any other; it stays recorded for docs/findings/${state.change}.md.\n- ${list.join('\n- ')}`
}
// What a reviewer after an in-place round is asked: the findings of its
// kind offered then, to confirm fixed.
function inPlaceCheck(kind) {
  const list = awaiting[kind]
  return list.length ? `\nFindings fixed in place since the last review, to check: list in fixed_in_place, verbatim as written here, each one the fix removed; one still present is a finding as before.\n- ${list.join('\n- ')}` : ''
}
function confirmInPlace(kind, listed) {
  for (const f of listed || []) if (awaiting[kind].includes(f)) fixedInPlace.add(f)
  awaiting[kind] = []
}
function offer(list, awaited) {
  for (const f of list) offered.add(f)
  if (awaited) awaiting = { quality: list.filter((f) => f.startsWith('quality ')), security: list.filter((f) => f.startsWith('security ')) }
}

async function rounds(fixes = true) {
  for (;;) {
    let blocked = ''
    let by = 'check'
    if (!doneAtHead('check')) {
      phase('Check')
      // The check the workflow last recorded: stage records count only at
      // it, so a record at the head that no workflow record backs runs again.
      const backed = COMMIT.test(state['phase.check'] || '') ? state['phase.check'] : ''
      const again = rerunWhy ? ` The last check did not finish (${rerunWhy}); a check still running at this commit is rejoined.` : ''
      const from = settleBase(movedFrom, settleAt)
      settleAt = ''
      const lines = checkLines(state.change, backed, movedFrom, metricLine(), from)
      const c = await measured('check', () => agent(`${intro()} ${checkRunTask(lines)}${again}${capLine('run')}`, calibrate('checker', { agentType: 'checker', schema: withCalls(CHECK_RUN), label: 'checker: run' })), callCap('run'))
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
        const passed = v.kind === 'passed'
        verdict('check', passed)
        note(`check at ${v.at}: ${passed ? 'passed' : `failed at stage ${v.stage}; ${v.log}`}`)
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
        if (b.blocking.length) { blocked = `Blocking regressions:\n- ${b.blocking.join('\n- ')}`; by = 'bench' }
      }
    }
    // Fix in place: the findings of this round's reviews, offered once.
    const fresh = fixes ? reviewFindings.filter((f) => !offered.has(f)) : []
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
      note(`fix in place: ${fresh.length} finding(s) in a round of their own; ${from ? `the check, security, and bench stand on ${from} when the fix changes only records, else they run again` : 'check, security, and quality run again'} at its head`)
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

phase('Resume')
const resume = await agent(
  `Prepare the delivery of one change. Input: ${JSON.stringify(input)}.
1. \`git fetch -q origin\`. The change name is input.change, or an existing change under openspec/changes/ that the brief names, or a kebab-case name of 2 to 5 words derived from the brief.
2. In the main checkout, before any worktree links the toolchain, \`make doctor\`; run \`make toolchain\` when it fails and stop when that fails too.
3. The branch is input.branch, or the one in build/pipeline/<change>.json, or <type>/<change> with the type from CLAUDE.md's Branch naming. Run \`sh tools/run_state.sh lane-open <change> <branch>\` in the main checkout, which stays on main: it makes the change's worktree tmp/.lane-<change> on the branch (local, else origin's, else new from origin/main), keeps it on a resume, and links the shared toolchain, compile cache, and run states; stop with its message when it fails.
4. Run \`sh tools/run_state.sh init <change> <branch>\`; when it refuses (a merged change name), stop with its message as reason. Then \`cd tmp/.lane-<change> && sh tools/run_state.sh trusted <change>\`, and return the second command's output verbatim as state_json, with \`git -C tmp/.lane-<change> rev-parse --short=12 HEAD\` as head.
5. Run \`cd tmp/.lane-<change> && sh tools/run_state.sh plan-needed <change>\` and return its one line verbatim as plan; its exit 1 means not needed, not a failure.${capLine('resume')}`,
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
// when the queue needs a decision, which plan-needed alone finds (the change
// is not the queue's head, a proposal or finding waits, or a periodic
// security review failed with no merge since): a brief for the
// head item keeps the order, so it plans no more than the change's name
// would (planSkipped). Otherwise the head item is taken as written, with its
// size as the estimate, and the brief still reaches the scouts and the
// contributor. A brief that is only the change
// name gives the scouts and the contributor nothing to work from, so they
// read the queue item naming the change in its lane queue themselves: the
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
// The package step's plan line: plan-apply, first, and history for the
// change's own lane, never groom, which only a sprint's records change runs, in its
// implement step, so the fold and the sprint row are written once.
function packagePlan(state, planned) {
  if (/^sprint-[0-9]+-records$/.test(state.change)) return 'This is the sprint\'s records change: your implement step ran history and groom; run neither again, nor plan-apply, and copy nothing from build/plan/.'
  const history = state.records === 'skip'
    ? 'run no history: this change\'s run state excludes the planning records (records=skip), and history says so for it'
    : `run \`sh tools/run_state.sh history ${state.change}\`, which appends only its lane's rows`
  return planned === 0
    ? `The planner did not run: this change was taken from the head of its lane queue as written. Copy nothing from build/plan/ and run no plan-apply; ${history}; never run groom, which the sprint's records change runs; then remove this change's item from its lane queue and renumber the rest.`
    : `Run \`sh tools/run_state.sh plan-apply ${state.change}\`, which applies ${planDir(state.change)} for this change's lane only, before any edit of a lane queue, which it overwrites, and ${history}; never run groom, which the sprint's records change runs.`
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
// clears the review at the merge of the next change planned after it,
// or passed_since at a later passing periodic security review
// (review-coverage, review-coverage-b); otherwise
// nothing. tools/tools_test.sh runs this helper.
function planReview(line) {
  const m = /^needed: ((?:review|sprint)-[0-9][a-z0-9-]*) records a failing periodic security review at ([0-9a-f]{7,40}),/.exec(line || '')
  return m ? ` plan-needed: \`${m[1]}\` records a failing periodic security review at ${m[2]}; read \`sh tools/run_state.sh show ${m[1]}\` and apply your security-first step to its findings.` : ''
}
const request = typeof input.brief === 'string' && input.brief.trim() !== '' && input.brief.trim() !== state.change
const brief = request ? input.brief : resumeBrief(state.change, planLine)
if (!stopped && planSkipped(state, planLine)) {
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
    `${intro()} Plan the queue for this delivery. Brief: ${input.brief || 'the existing OpenSpec change'}. Write your files under ${planDir(state.change)}, this delivery's own plan directory.${planReview(planLine)}${capLine('planner')}`,
    calibrate('planner', { agentType: 'planner', schema: withCalls(PLAN) })), callCap('planner'))
  if (!p) stopped = 'the planner returned no result'
  else {
    note(`plan: ${p.decisions.map((d) => `${d.decision} (${d.evidence})`).join('; ') || 'no change to the queue'}`)
    planNotes = p.notes
    // Stored with the figures, so budget and the history row keep it after
    // the queue item leaves the queue.
    if (SIZES.includes(p.estimate)) estimate = p.estimate
    if (p.records === 'skip') excludeRecords('the planner')
    if (p.security_first.length) stopped = `security first: deliver the fix of ${p.security_first.join('; ')} before this change`
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
    phase('Scout')
    let packs = input.packs || []
    let unread = []
    if (!packs.length) {
      // The plan's calls are its own key, so phase.scout holds only the
      // scouts' starts, the figure their packs' Tool calls lines match.
      const plan = await measured('areas', () => agent(
        `List the areas of docs/codebase-map.md (by number and name) whose files this change edits, as the brief says, at most ${MAX_AREAS}: ${brief}. ${input.areas ? 'Requested areas: ' + input.areas.join(', ') + '.' : ''} Leave out an area the change only reads, and any finding the change only appends to docs/backlog.md or other bookkeeping: those reach the contributor through the plan notes, never a scout. A file belongs to an area only when the area's section names its path, itself or by its directory (look the path up in docs/codebase-map.md): a file the map places in no area, such as a root LICENSE, belongs to none, and a change editing only such files lists no area. For each area, first name its locations, the paths or path:line of the existing code the change edits there, and the question a contributor needs answered about that code (callers, registration, tests), never about code the change will add, which does not exist yet; an area whose only edits are new files needs no pack. Then ${PACK_CURRENT}. List current packs by path, the locations they lack under unread, and the areas still needing one, each with its locations and question.${capLine('areas')}`,
        calibrate('areas', { schema: withCalls(SCOUT_PLAN), label: 'scout plan' })), callCap('areas'))
      const targets = scoutTargets(plan, MAX_AREAS, brief)
      if (targets.unplaced.length) note(`not scouted, no location in the area: ${targets.unplaced.map((n) => n.area).join(', ')}`)
      if (targets.named.length) note(`not scouted, the brief names every location: ${targets.named.map((n) => n.area).join(', ')}`)
      unread = targets.unread
      if (targets.beyond.length) note(`not scouted, beyond ${MAX_AREAS} areas: ${targets.beyond.map((n) => n.area).join(', ')}`)
      const fresh = targets.needed.length ? await measured('scout', () => parallel(targets.needed.map((n) => () =>
        agent(scoutPrompt(n, brief) + capLine('scout'), calibrate('scout', { agentType: 'scout', schema: withCalls(PACK), label: `scout: ${n.area}` })))), callCap('scout')) : []
      packs = targets.current.concat(fresh.filter(Boolean).map((p) => p.pack))
      note(`scout packs: ${packs.join(', ') || 'none'}`)
    }
    phase('Implement')
    const done = await contributor('implement', `Scout packs: ${packs.join(', ') || 'none'}.${unreadLine(unread)}${planNotes.length ? `\nPlan notes:\n- ${planNotes.join('\n- ')}` : ''}`)
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
    if (await verify()) {
      phase('Package')
      const plan = packagePlan(state, planned)
      const done = await contributor('package', `Non-blocking findings to append to docs/findings/${state.change}.md (mkdir -p docs/findings first, as a fresh checkout lacks it, then a shell append; never read docs/backlog.md):\n- ${handOver().join('\n- ') || 'none'}\n${plan}${settledTesting()}`)
      if (done) state.pr = packagedPr(done)
      if (done && !state.pr) stopped = 'no pull request appeared for the branch ' + state.branch + ': read the open-pr workflow\'s log'
      else if (done) phaseDone('package', head)
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
    // gates' settled_at allows that records-only diff. A blocking quality or
    // security review gets one fix round a run (resumeFix), the security
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
