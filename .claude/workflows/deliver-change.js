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
    { title: 'Quality', detail: 'quality reviewer: code-review and the repository rules' },
    { title: 'Security', detail: 'security reviewer on the committed diff; never skipped' },
    { title: 'Benchmark', detail: 'allocations and rounds against the figures recorded for main; the agent against main only when they differ' },
    { title: 'Package', detail: 'contributor: archive, gates, one push, pull request' },
    { title: 'Merge', detail: 'merger: wait for CI, red back to the contributor; squash with the trailer, verify main' },
    { title: 'Retrospective', detail: 'retrospective: record the metrics, propose simplifications, decide whether a review is due' },
    { title: 'Review', detail: 'periodic review of the whole codebase: security, never skipped, and quality' },
    { title: 'Report', detail: 'reporter: the fixed report shape' },
  ],
}

// args: { change?, brief?, branch?, packs?: [path], areas?: [string] }, or a
// string that is a change name or a brief. The run state, written only by
// tools/run_state.sh, decides which phases are already done: a phase whose
// recorded commit is the current one is skipped, so a restart resumes and a
// fix (a new commit) runs every later phase again. The workflow also
// measures the run (output tokens and tool calls per phase, the first
// verdict of each gate, rework rounds, CI minutes) and stores each figure
// as metric.* when it changes, so a restart seeds them and tools/run_state.sh
// history builds a whole row. The run state's phase.* and review.* lines
// and the figures are the script's own: it builds each command from a
// schema-checked result and one agent that reads nothing else runs them
// (flush): at the end of verify(), since the pre-push gates read the
// reviews, after the package step and after the merge, which cannot run
// twice, and once at the end; tools/agent_guard.sh keeps the other agents
// off those commands, and the merger's records gate compares the file with
// what the script received.
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
let ciMinutes = null

const STATUS = { type: 'string', enum: ['done', 'stopped'] }
const HEAD = { type: 'string', description: 'git rev-parse --short=12 HEAD at the end' }
const LINES = { type: 'array', items: { type: 'string' } }
const RESUME = {
  type: 'object',
  properties: {
    status: STATUS, change: { type: 'string' }, branch: { type: 'string' }, head: HEAD,
    state_json: { type: 'string', description: 'the output of tools/run_state.sh init, verbatim' },
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
  },
  required: ['decisions', 'security_first', 'notes', 'files'],
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
// The figures waiting for the next flush, metric name to value: fixed
// names and numbers only, so the command is safe for the shell and for
// tools/run_state.sh metric.
const figures = {}
const figure = (name, value) => { figures[name] = String(value) }
// Runs fn (agent calls), adds its output tokens and reported tool calls to
// the phase key, and stores the key's total as metric.phase.KEY.
async function measured(key, fn) {
  const before = spent()
  const result = await fn()
  const u = usage[key] || (usage[key] = { tokens: 0, calls: 0 })
  u.tokens += spent() - before
  for (const r of [].concat(result)) if (r && Number.isInteger(r.tool_calls)) u.calls += r.tool_calls
  figure(`phase.${key}`, `${Math.round(u.tokens)}/${u.calls}`)
  return result
}
function verdict(gate, passed) {
  if (gate in firstPass) return
  firstPass[gate] = passed ? 1 : 0
  figure(`first.${gate}`, firstPass[gate])
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
  if (state['metric.ci_min']) ciMinutes = Number(state['metric.ci_min'])
  // The blocked quality review's findings, which its reviewer recorded as
  // quality-blocking notes; kept only when all of them are there.
  const [result, commit, count] = at('review.quality')
  const prefix = `quality-blocking ${commit} `
  const found = Object.keys(state).filter((k) => /^note\.[0-9]+$/.test(k))
    .sort((a, b) => Number(a.slice(5)) - Number(b.slice(5)))
    .map((k) => String(state[k])).filter((v) => v.startsWith(prefix)).map((v) => v.slice(prefix.length))
  if (result === 'blocked' && COMMIT.test(commit || '') && found.length && count === `blocking=${found.length}`) {
    qualityBlocking = found
    qualityAt = commit
  }
}
// The figures in one line for the retrospective's and the reporter's
// prompts; the run state holds the same.
function summary() {
  const keys = Object.keys(usage)
  const total = (field) => keys.reduce((n, k) => n + usage[k][field], 0)
  const first = Object.keys(firstPass).map((g) => `${g}:${firstPass[g]}`).join(',') || 'none'
  return `output tokens ${Math.round(total('tokens'))}, tool calls ${total('calls')}; per phase ${keys.map((k) => `${k}=${Math.round(usage[k].tokens)}/${usage[k].calls}`).join(',') || 'none'}; first passes ${first}; rework ${rework}${ciMinutes !== null ? `; CI ${ciMinutes} min` : ''}`
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
async function flush() {
  const pairs = Object.keys(figures).filter((k) => /^[a-z0-9_.-]+$/.test(k) && /^[0-9./]+$/.test(figures[k])).map((k) => `${k}=${figures[k]}`)
  for (const k of Object.keys(figures)) delete figures[k]
  if (pairs.length && CHANGE.test(state.change || '')) pending.push(`sh tools/run_state.sh metric ${state.change} ${pairs.join(' ')}`)
  if (!pending.length) return true
  const command = pending.splice(0).join(' && ')
  const r = await measured('record', () => agent(
    `Run this one command with the Bash tool from the repository root, exactly as written, and nothing else:\n\n${command}\n\nReturn ok true when it exited 0, and its output.`,
    { schema: withCalls(RECORDED), effort: 'low', label: 'record' }))
  if (r && r.ok) return true
  if (!stopped) stopped = `the run state records failed: ${r ? r.output : 'no result'}`
  return false
}
// The merge gates with the review results the script holds, for the merger.
function mergeGates() {
  const records = ['security', 'quality', 'bench'].map((k) => `${k}:${at('review.' + k).slice(0, 2).join(':')}`)
    .filter((r) => /^[a-z]+:(pass|blocked):[0-9a-f]{7,40}$/.test(r))
  return `CHANGE=${state.change} RECORDS="${records.join(' ')}" sh tools/gates.sh merge build/pipeline/${state.change}.body.md`
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
const intro = () => `Change \`${state.change}\` on branch \`${state.branch}\`.`

async function contributor(mode, detail) {
  if (mode === 'fix') figure('rework', ++rework)
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

// Check, quality, security, and benchmark until all pass at one commit;
// whatever blocks goes back to the contributor, at most ROUNDS times.
async function verify() {
  const passed = await rounds()
  return (await flush()) && passed
}

// The quality reviewer's input after an earlier review: its commit, its
// blocking findings, and the fix diff to review when only tests changed.
// The fix diff is offered only for a commit other than HEAD whose findings
// are known (a pass has none); otherwise the whole branch diff is reviewed.
function priorQuality() {
  const [result, commit] = at('review.quality')
  if (!COMMIT.test(commit || '')) return ''
  const last = `\nThe last quality review, at ${commit}, was ${result}.`
  const blocked = result === 'blocked'
  const known = !blocked || (qualityAt === commit && qualityBlocking.length > 0)
  if (commit === head || !known) return `${last} Review the whole branch diff.`
  const findings = blocked ? ` Its blocking findings:\n- ${qualityBlocking.join('\n- ')}\n` : ' '
  return `${last}${findings}When \`git diff --name-only ${commit} HEAD\` lists at least one file and only files under test/ (tests and their snapshots), review only \`git diff ${commit} HEAD\` against ${blocked ? 'those findings and ' : ''}the rules; otherwise review the whole branch diff.`
}

async function rounds() {
  for (let round = 1; round <= ROUNDS + 1; round++) {
    let blocked = ''
    if (!doneAtHead('check')) {
      phase('Check')
      const c = await measured('check', () => agent(`${intro()} Run the checks and report.`, { agentType: 'checker', schema: withCalls(CHECK), effort: 'low' }))
      if (!c) { stopped = 'the checker returned no result'; return false }
      verdict('check', c.passed)
      note(`check at ${c.head}: ${c.passed ? 'passed' : 'failed at ' + c.failed_stage}`)
      if (c.passed) {
        state['phase.check'] = c.head
        benchSameAt = c.bench_same ? c.head : ''
        benchReport = c.bench_report || []
      } else blocked = `The stage ${c.failed_stage} failed; its log:\n${c.log_excerpt || ''}`
    }
    if (!blocked && !reviewedAtHead('quality')) {
      phase('Quality')
      const q = await measured('quality', () => agent(`${intro()} Review the committed diff and return the findings.${priorQuality()}`, { agentType: 'quality-reviewer', schema: withCalls(QUALITY) }))
      if (!q) { stopped = 'the quality reviewer returned no result'; return false }
      qualityBlocking = q.blocking
      qualityAt = q.head
      verdict('quality', !q.blocking.length)
      note(`quality at ${q.head}: ${q.blocking.length} blocking, ${q.advisory.length} advisory`)
      reviewed('quality', !q.blocking.length, q.head, { blocking: q.blocking.length, advisory: q.advisory.length })
      if (q.blocking.length) blocked = `Blocking quality findings:\n- ${q.blocking.join('\n- ')}`
    }
    if (!blocked && !reviewedAtHead('security')) {
      phase('Security')
      let s = await measured('security', () => agent(`${intro()} Run the security review on the committed diff and return the result.`, { agentType: 'security-reviewer', schema: withCalls(SECURITY) }))
      if (!s || !s.ran) s = await measured('security', () => agent(`${intro()} The last security review did not complete. Run it again, every sub-task inline, and return the result.`, { agentType: 'security-reviewer', schema: withCalls(SECURITY), label: 'security-reviewer: retry' }))
      if (!s || !s.ran) { stopped = 'the security review did not run; it cannot be skipped'; return false }
      const blocking = s.findings.filter((f) => f.severity !== 'Low' && f.confidence >= 8 && f.in_change)
      verdict('security', !blocking.length)
      for (const f of s.findings.filter((f) => !blocking.includes(f))) {
        const line = `security ${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`
        if (!backlog.includes(line)) backlog.push(line)
      }
      note(`security at ${s.head}: ${s.findings.length} finding(s), ${blocking.length} blocking`)
      const count = (severity) => s.findings.filter((f) => f.severity === severity).length
      reviewed('security', !blocking.length, s.head, { high: count('High'), medium: count('Medium'), low: count('Low'), blocking: blocking.length })
      if (blocking.length) blocked = `Blocking security findings, to fix first:\n- ${blocking.map((f) => `${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`).join('\n- ')}`
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
    if (round > ROUNDS) { stopped = `still blocked after ${ROUNDS} fix rounds: ${blocked.split('\n')[0]}`; return false }
    phase('Implement')
    if (!(await contributor('fix', blocked))) return false
  }
  return false
}

phase('Resume')
const resume = await agent(
  `Prepare the delivery of one change. Input: ${JSON.stringify(input)}.
1. \`git fetch -q origin\`. The change name is input.change, or an existing change under openspec/changes/ that the brief names, or a kebab-case name of 2 to 5 words derived from the brief.
2. The branch is input.branch, or the one in build/pipeline/<change>.json, or <type>/<change> with the type from CLAUDE.md's Branch naming. Check it out when it exists locally or on origin; otherwise create it from origin/main, which needs a clean tree (stop with the reason when it is not).
3. \`make doctor\`; run \`make toolchain\` when it fails and stop when that fails too.
4. Run \`sh tools/run_state.sh init <change> <branch>\` and return its output verbatim as state_json, with \`git rev-parse --short=12 HEAD\` as head.`,
  { schema: RESUME, effort: 'low', label: 'resume' })
if (!resume || resume.status !== 'done') {
  stopped = `resume stopped: ${resume ? resume.reason : 'no result'}`
} else {
  state = JSON.parse(resume.state_json)
  head = resume.head
  seed()
  note(`resumed ${state.change} on ${state.branch} at ${head}`)
  if (!CHANGE.test(state.change || '')) stopped = `not a change name: ${state.change}`
}

// The planner orders the queue from the metrics history before a new change
// starts; an unresolved blocking security finding goes first.
if (!stopped && !state.merged && !state['phase.plan'] && !state['phase.implement']) {
  phase('Plan')
  const p = await measured('plan', () => agent(
    `${intro()} Plan the queue for this delivery. Brief: ${input.brief || 'the existing OpenSpec change'}.`,
    { agentType: 'planner', schema: withCalls(PLAN) }))
  if (!p) stopped = 'the planner returned no result'
  else {
    note(`plan: ${p.decisions.map((d) => `${d.decision} (${d.evidence})`).join('; ') || 'no change to the queue'}`)
    planNotes = p.notes
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
        `List the areas of docs/codebase-map.md (by number and name) whose files this change edits, as the brief says, at most ${MAX_AREAS}: ${input.brief || state.change}. ${input.areas ? 'Requested areas: ' + input.areas.join(', ') + '.' : ''} Leave out an area the change only reads, and any finding the change only records in docs/backlog.md or other bookkeeping: those reach the contributor through the plan notes, never a scout. For each area, a pack under tmp/scout/ is current when its Commit: is origin/main or \`git diff --quiet <its commit> origin/main -- <its Files read>\` passes; list current packs by path and the areas still needing one, with the question a contributor needs answered about the code it edits.`,
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
    const done = await contributor('implement', `Brief: ${input.brief || 'the existing OpenSpec change'}. Scout packs: ${packs.join(', ') || 'none'}.${planNotes.length ? `\nPlan notes:\n- ${planNotes.join('\n- ')}` : ''}`)
    if (done) phaseDone('implement', head)
  }

  if (!stopped && !(state['phase.package'] && state.pr)) {
    if (await verify()) {
      phase('Package')
      const done = await contributor('package', `Non-blocking findings for docs/backlog.md:\n- ${backlog.join('\n- ') || 'none'}\nApply the planner's files under build/plan/ and append the history of the merged changes as your package step says.`)
      // A second push is refused, so a restart must find the package step.
      if (done) { state.pr = String(done.pr || ''); phaseDone('package', head); await flush() }
    }
  }

  // One agent waits for CI and merges. Pending CI is asked again, at most
  // WAITS times; red CI goes back to the contributor's fix loop.
  if (!stopped) {
    phase('Merge')
    let waits = 0
    let fixes = 0
    for (;;) {
      const m = await measured('merge', () => agent(
        `${intro()} Wait for CI at the pushed head${waits ? ' (it was still running when you last returned; keep waiting)' : ''}, then merge the pull request if CI is green and every merge gate passes. The merge gates: \`${mergeGates()}\``,
        { agentType: 'merger', schema: withCalls(MERGE), effort: 'low' }))
      if (!m) { stopped = 'the merger returned no result'; break }
      const checks = (m.checks || []).join('; ')
      note(`CI at ${m.head}: ${m.ci}${m.minutes ? ` in ${m.minutes} min` : ''}${m.ci === 'pending' && checks ? ` (${checks})` : ''}`)
      if (m.ci === 'pending') {
        if (++waits < WAITS) continue
        stopped = `CI stalled at ${m.head} after ${WAITS} waits of up to 30 minutes: ${checks || 'no check state returned'}`
        break
      }
      waits = 0
      if (m.ci === 'green' || m.ci === 'red') verdict('ci', m.ci === 'green')
      if (Number.isFinite(m.minutes) && m.minutes > 0) { ciMinutes = m.minutes; figure('ci_min', m.minutes.toFixed(1)) }
      if (m.ci === 'green') { state.ci = `green ${m.head}`; phaseDone('ci', m.head) }
      if (m.merged) {
        state.merged = m.sha
        phaseDone('merge', m.sha)
        await flush()
        note(`merged ${m.sha}: ${m.subject}${m.branch_deleted ? '' : ' (branch deletion refused)'}`)
        break
      }
      if (m.ci !== 'red' || fixes >= ROUNDS) {
        stopped = m.ci === 'green' ? `not merged: ${m.problem || 'no reason given'}` : `CI ${m.ci}${m.step ? ' at ' + m.step : ''}${m.problem ? ': ' + m.problem : ''}`
        break
      }
      fixes++
      if (!(await contributor('fix', `CI failed at ${m.step}; its log:\n${m.log_excerpt || ''}`))) break
      if (!(await verify())) break
      phase('Merge')
      if (!(await contributor('push', 'Push the CI fix.'))) break
    }
  }
}

// After the merge: record the run's figures, learn from them, and review the
// whole codebase when five changes merged since the last review or this one
// touched a sensitive area. What they find waits in the run state for the
// next change's planner.
if (!stopped && state.merged && !state['phase.retro']) {
  phase('Retrospective')
  const r = await measured('retro', () => agent(
    `${intro()} The change merged. Its figures, also in the run state: ${summary()}.\nWorkflow notes:\n- ${notes.join('\n- ')}`,
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
  if (!(await flush())) note(stopped)
}
return report ? report.report : `No report; notes:\n${notes.join('\n')}${stopped ? '\nStopped: ' + stopped : ''}`
