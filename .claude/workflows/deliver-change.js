export const meta = {
  name: 'deliver-change',
  description: 'Deliver one change to main through fixed phases: plan, scouts, contributor, checker, quality and security review, benchmark, package, CI, merge, retrospective, periodic review, report',
  whenToUse: 'Every change to this repository, started by /deliver with a change name or a brief; it resumes from build/pipeline/CHANGE.json',
  phases: [
    { title: 'Resume', detail: 'branch, toolchain, and the run state' },
    { title: 'Plan', detail: 'planner: the next queue from the metrics history; security findings first' },
    { title: 'Scout', detail: 'one scout per map area without a current pack' },
    { title: 'Implement', detail: 'contributor: propose and apply, committing early' },
    { title: 'Check', detail: 'checker: the canonical stages through make' },
    { title: 'Quality', detail: 'quality reviewer: code-review and the repository rules' },
    { title: 'Security', detail: 'security reviewer on the committed diff; never skipped' },
    { title: 'Benchmark', detail: 'allocations and analysis rounds against main' },
    { title: 'Package', detail: 'contributor: archive, gates, one push, pull request' },
    { title: 'CI', detail: 'CI watcher; red goes back to the contributor' },
    { title: 'Merge', detail: 'merger: squash with the trailer, verify main' },
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
// verdict of each gate, rework rounds, CI minutes) and hands the figures to
// the retrospective and the reporter, which record them with
// tools/run_state.sh metric; the script itself writes no file.
const input = typeof args === 'string' ? { brief: args } : (args || {})
const ROUNDS = 3
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
  properties: { passed: { type: 'boolean' }, head: HEAD, stages: LINES, failed_stage: { type: 'string' }, log_excerpt: { type: 'string' } },
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
const CI = {
  type: 'object',
  properties: { status: { type: 'string', enum: ['green', 'red', 'stalled', 'stale'] }, head: HEAD, minutes: { type: 'number' }, step: { type: 'string' }, log_excerpt: { type: 'string' } },
  required: ['status', 'head'],
}
const MERGE = {
  type: 'object',
  properties: { merged: { type: 'boolean' }, sha: { type: 'string' }, subject: { type: 'string' }, branch_deleted: { type: 'boolean' }, problem: { type: 'string' } },
  required: ['merged'],
}
const REPORT = { type: 'object', properties: { report: { type: 'string' } }, required: ['report'] }
const PLAN = {
  type: 'object',
  properties: {
    decisions: { type: 'array', items: { type: 'object', properties: { decision: { type: 'string' }, evidence: { type: 'string' } }, required: ['decision', 'evidence'] } },
    security_first: { ...LINES, description: 'unresolved blocking security findings the brief does not fix' },
    files: LINES,
  },
  required: ['decisions', 'security_first', 'files'],
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
const withCalls = (schema) => ({ ...schema, properties: { ...schema.properties, tool_calls: CALLS } })

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
  for (const r of [].concat(result)) if (r && r.tool_calls) u.calls += r.tool_calls
  return result
}
const verdict = (gate, passed) => { if (!(gate in firstPass)) firstPass[gate] = passed ? 1 : 0 }
// The run's figures as NAME=VALUE pairs of numbers and fixed names only, so
// the line is safe for the shell and for tools/run_state.sh metric.
function metricLine() {
  const keys = Object.keys(usage)
  const total = (field) => keys.reduce((n, k) => n + usage[k][field], 0)
  const pairs = [`rework=${rework}`, `out_tokens=${Math.round(total('tokens'))}`, `tool_calls=${total('calls')}`]
  const first = Object.keys(firstPass).map((g) => `${g}:${firstPass[g]}`).join(',')
  if (first) pairs.push(`first_pass=${first}`)
  if (Number.isFinite(Number(ciMinutes)) && ciMinutes !== null) pairs.push(`ci_min=${Number(ciMinutes).toFixed(1)}`)
  if (keys.length) pairs.push(`phases=${keys.map((k) => `${k}=${Math.round(usage[k].tokens)}/${usage[k].calls}`).join(',')}`)
  return `sh tools/run_state.sh metric ${state.change} ${pairs.join(' ')}`
}

const at = (key) => (state[key] || '').split(' ')
const doneAtHead = (name) => state['phase.' + name] === head
const reviewedAtHead = (kind) => at('review.' + kind)[0] === 'pass' && at('review.' + kind)[1] === head
const note = (line) => { notes.push(line); log(line) }
const backlog = []
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

// Check, quality, security, and benchmark until all pass at one commit;
// whatever blocks goes back to the contributor, at most ROUNDS times.
async function verify() {
  for (let round = 1; round <= ROUNDS + 1; round++) {
    let blocked = ''
    if (!doneAtHead('check')) {
      phase('Check')
      const c = await measured('check', () => agent(`${intro()} Run the checks and report.`, { agentType: 'checker', schema: withCalls(CHECK), effort: 'low' }))
      if (!c) { stopped = 'the checker returned no result'; return false }
      verdict('check', c.passed)
      note(`check at ${c.head}: ${c.passed ? 'passed' : 'failed at ' + c.failed_stage}`)
      if (c.passed) state['phase.check'] = c.head
      else blocked = `The stage ${c.failed_stage} failed; its log:\n${c.log_excerpt || ''}`
    }
    if (!blocked && !reviewedAtHead('quality')) {
      phase('Quality')
      const q = await measured('quality', () => agent(`${intro()} Review the committed diff and record the result.`, { agentType: 'quality-reviewer', schema: withCalls(QUALITY) }))
      if (!q) { stopped = 'the quality reviewer returned no result'; return false }
      verdict('quality', !q.blocking.length)
      note(`quality at ${q.head}: ${q.blocking.length} blocking, ${q.advisory.length} advisory`)
      if (q.blocking.length) blocked = `Blocking quality findings:\n- ${q.blocking.join('\n- ')}`
      else state['review.quality'] = `pass ${q.head}`
    }
    if (!blocked && !reviewedAtHead('security')) {
      phase('Security')
      let s = await measured('security', () => agent(`${intro()} Run the security review on the committed diff and record the result.`, { agentType: 'security-reviewer', schema: withCalls(SECURITY) }))
      if (!s || !s.ran) s = await measured('security', () => agent(`${intro()} The last security review did not complete. Run it again, every sub-task inline, and record the result.`, { agentType: 'security-reviewer', schema: withCalls(SECURITY), label: 'security-reviewer: retry' }))
      if (!s || !s.ran) { stopped = 'the security review did not run; it cannot be skipped'; return false }
      const blocking = s.findings.filter((f) => f.severity !== 'Low' && f.confidence >= 8 && f.in_change)
      verdict('security', !blocking.length)
      for (const f of s.findings.filter((f) => !blocking.includes(f))) {
        const line = `security ${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`
        if (!backlog.includes(line)) backlog.push(line)
      }
      note(`security at ${s.head}: ${s.findings.length} finding(s), ${blocking.length} blocking`)
      if (blocking.length) blocked = `Blocking security findings, to fix first:\n- ${blocking.map((f) => `${f.severity} (${f.confidence}) ${f.file}:${f.line || 0} ${f.title}; fix: ${f.fix}`).join('\n- ')}`
      else state['review.security'] = `pass ${s.head}`
    }
    if (!blocked && !reviewedAtHead('bench')) {
      phase('Benchmark')
      const b = await measured('bench', () => agent(`${intro()} Compare with main and record the result.`, { agentType: 'benchmark', schema: withCalls(BENCH), effort: 'low' }))
      if (!b) { stopped = 'the benchmark agent returned no result'; return false }
      verdict('bench', !b.blocking.length)
      note(`benchmark at ${b.head}: ${b.report.join('; ')}`)
      if (b.blocking.length) blocked = `Blocking regressions:\n- ${b.blocking.join('\n- ')}`
      else state['review.bench'] = `pass ${b.head}`
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
  note(`resumed ${state.change} on ${state.branch} at ${head}`)
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
    if (p.security_first.length) stopped = `security first: deliver the fix of ${p.security_first.join('; ')} before this change`
    else state['phase.plan'] = head
  }
}

if (!stopped && !state.merged) {
  if (!state['phase.implement']) {
    phase('Scout')
    let packs = input.packs || []
    if (!packs.length) {
      const plan = await measured('scout', () => agent(
        `List the areas of docs/codebase-map.md (by number and name) that this change touches: ${input.brief || state.change}. ${input.areas ? 'Requested areas: ' + input.areas.join(', ') + '.' : ''} For each, a pack under tmp/scout/ is current when its Commit: is origin/main or \`git diff --quiet <its commit> origin/main -- <its Files read>\` passes; list current packs by path and the areas still needing one, with the question a contributor needs answered.`,
        { schema: withCalls(SCOUT_PLAN), effort: 'low', label: 'scout plan' }))
      const fresh = plan ? await measured('scout', () => parallel(plan.needed.map((n) => () =>
        agent(`Area: ${n.area}. Question: ${n.question}. Write the pack and return its path.`, { agentType: 'scout', schema: withCalls(PACK), label: `scout: ${n.area}` })))) : []
      packs = (plan ? plan.current : []).concat(fresh.filter(Boolean).map((p) => p.pack))
      note(`scout packs: ${packs.join(', ') || 'none'}`)
    }
    phase('Implement')
    const done = await contributor('implement', `Brief: ${input.brief || 'the existing OpenSpec change'}. Scout packs: ${packs.join(', ') || 'none'}.`)
    if (done) state['phase.implement'] = head
  }

  if (!stopped && !(state['phase.package'] && state.pr)) {
    if (await verify()) {
      phase('Package')
      const done = await contributor('package', `Non-blocking findings for docs/backlog.md:\n- ${backlog.join('\n- ') || 'none'}\nApply the planner's files under build/plan/ and append the history of the merged changes as your package step says.`)
      if (done) { state['phase.package'] = head; state.pr = String(done.pr || '') }
    }
  }

  if (!stopped && !(state['phase.ci'] && at('ci')[0] === 'green')) {
    phase('CI')
    for (let round = 0; ; round++) {
      const ci = await measured('ci', () => agent(`${intro()} Watch CI on the pull request's head and report.`, { agentType: 'ci-watcher', schema: withCalls(CI), effort: 'low' }))
      if (!ci) { stopped = 'the CI watcher returned no result'; break }
      verdict('ci', ci.status === 'green')
      if (ci.minutes) ciMinutes = ci.minutes
      note(`CI at ${ci.head}: ${ci.status}${ci.minutes ? ` in ${ci.minutes} min` : ''}`)
      if (ci.status === 'green') break
      if (ci.status !== 'red' || round >= ROUNDS) { stopped = `CI ${ci.status}${ci.step ? ' at ' + ci.step : ''}`; break }
      if (!(await contributor('fix', `CI failed at ${ci.step}; its log:\n${ci.log_excerpt || ''}`))) break
      if (!(await verify())) break
      phase('CI')
      if (!(await contributor('push', 'Push the CI fix.'))) break
    }
  }

  if (!stopped) {
    phase('Merge')
    const m = await measured('merge', () => agent(`${intro()} Merge the pull request if every merge gate passes.`, { agentType: 'merger', schema: withCalls(MERGE), effort: 'low' }))
    if (!m || !m.merged) stopped = `not merged: ${m ? m.problem : 'no result'}`
    else {
      state.merged = m.sha
      note(`merged ${m.sha}: ${m.subject}${m.branch_deleted ? '' : ' (branch deletion refused)'}`)
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
    `${intro()} The change merged. Metric command line: \`${metricLine()}\`\nWorkflow notes:\n- ${notes.join('\n- ')}`,
    { agentType: 'retrospective', schema: withCalls(RETRO) }))
  if (!r) stopped = 'the retrospective returned no result'
  else {
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
      else note(`periodic review: security ${p.security.length} finding(s), ${p.security_blocking} blocking (to the front of the queue); quality ${p.quality_blocking.length} blocking, ${p.quality_advisory} advisory`)
    }
  }
}

phase('Report')
const report = await agent(
  `Change \`${state.change || input.change || 'unknown'}\`. Write the report.${state.merged && state.change ? ` Metric command line: \`${metricLine()}\`` : ''} Workflow notes:\n- ${notes.join('\n- ')}\n${stopped ? 'The run stopped: ' + stopped : 'The run finished.'}`,
  { agentType: 'reporter', schema: REPORT, effort: 'low' })
return report ? report.report : `No report; notes:\n${notes.join('\n')}${stopped ? '\nStopped: ' + stopped : ''}`
