export const meta = {
  name: 'deliver-change',
  description: 'Deliver one change to main through fixed phases: scouts, contributor, checker, quality and security review, benchmark, package, CI, merge, report',
  whenToUse: 'Every change to this repository, started by /deliver with a change name or a brief; it resumes from build/pipeline/CHANGE.json',
  phases: [
    { title: 'Resume', detail: 'branch, toolchain, and the run state' },
    { title: 'Scout', detail: 'one scout per map area without a current pack' },
    { title: 'Implement', detail: 'contributor: propose and apply, committing early' },
    { title: 'Check', detail: 'checker: the canonical stages through make' },
    { title: 'Quality', detail: 'quality reviewer: code-review and the repository rules' },
    { title: 'Security', detail: 'security reviewer on the committed diff; never skipped' },
    { title: 'Benchmark', detail: 'allocations and analysis rounds against main' },
    { title: 'Package', detail: 'contributor: archive, gates, one push, pull request' },
    { title: 'CI', detail: 'CI watcher; red goes back to the contributor' },
    { title: 'Merge', detail: 'merger: squash with the trailer, verify main' },
    { title: 'Report', detail: 'reporter: the fixed report shape' },
  ],
}

// args: { change?, brief?, branch?, packs?: [path], areas?: [string] }, or a
// string that is a change name or a brief. The run state, written only by
// tools/run_state.sh, decides which phases are already done: a phase whose
// recorded commit is the current one is skipped, so a restart resumes and a
// fix (a new commit) runs every later phase again.
const input = typeof args === 'string' ? { brief: args } : (args || {})
const ROUNDS = 3
const notes = []
let head = ''
let state = {}
let stopped = ''

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

const at = (key) => (state[key] || '').split(' ')
const doneAtHead = (name) => state['phase.' + name] === head
const reviewedAtHead = (kind) => at('review.' + kind)[0] === 'pass' && at('review.' + kind)[1] === head
const note = (line) => { notes.push(line); log(line) }
const backlog = []
const intro = () => `Change \`${state.change}\` on branch \`${state.branch}\`.`

async function contributor(mode, detail) {
  const result = await agent(
    `${intro()} Mode: ${mode}. ${detail}\nFollow your Modes section for \`${mode}\` and return the schema.`,
    { agentType: 'contributor', schema: WORK, label: `contributor: ${mode}` })
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
      const c = await agent(`${intro()} Run the checks and report.`, { agentType: 'checker', schema: CHECK, effort: 'low' })
      if (!c) { stopped = 'the checker returned no result'; return false }
      note(`check at ${c.head}: ${c.passed ? 'passed' : 'failed at ' + c.failed_stage}`)
      if (c.passed) state['phase.check'] = c.head
      else blocked = `The stage ${c.failed_stage} failed; its log:\n${c.log_excerpt || ''}`
    }
    if (!blocked && !reviewedAtHead('quality')) {
      phase('Quality')
      const q = await agent(`${intro()} Review the committed diff and record the result.`, { agentType: 'quality-reviewer', schema: QUALITY })
      if (!q) { stopped = 'the quality reviewer returned no result'; return false }
      note(`quality at ${q.head}: ${q.blocking.length} blocking, ${q.advisory.length} advisory`)
      if (q.blocking.length) blocked = `Blocking quality findings:\n- ${q.blocking.join('\n- ')}`
      else state['review.quality'] = `pass ${q.head}`
    }
    if (!blocked && !reviewedAtHead('security')) {
      phase('Security')
      let s = await agent(`${intro()} Run the security review on the committed diff and record the result.`, { agentType: 'security-reviewer', schema: SECURITY })
      if (!s || !s.ran) s = await agent(`${intro()} The last security review did not complete. Run it again, every sub-task inline, and record the result.`, { agentType: 'security-reviewer', schema: SECURITY, label: 'security-reviewer: retry' })
      if (!s || !s.ran) { stopped = 'the security review did not run; it cannot be skipped'; return false }
      const blocking = s.findings.filter((f) => f.severity !== 'Low' && f.confidence >= 8 && f.in_change)
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
      const b = await agent(`${intro()} Compare with main and record the result.`, { agentType: 'benchmark', schema: BENCH, effort: 'low' })
      if (!b) { stopped = 'the benchmark agent returned no result'; return false }
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

if (!stopped && !state.merged) {
  if (!state['phase.implement']) {
    phase('Scout')
    let packs = input.packs || []
    if (!packs.length) {
      const plan = await agent(
        `List the areas of docs/codebase-map.md (by number and name) that this change touches: ${input.brief || state.change}. ${input.areas ? 'Requested areas: ' + input.areas.join(', ') + '.' : ''} For each, a pack under tmp/scout/ is current when its Commit: is origin/main or \`git diff --quiet <its commit> origin/main -- <its Files read>\` passes; list current packs by path and the areas still needing one, with the question a contributor needs answered.`,
        { schema: SCOUT_PLAN, effort: 'low', label: 'scout plan' })
      const fresh = plan ? await parallel(plan.needed.map((n) => () =>
        agent(`Area: ${n.area}. Question: ${n.question}. Write the pack and return its path.`, { agentType: 'scout', schema: PACK, label: `scout: ${n.area}` }))) : []
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
      const done = await contributor('package', `Non-blocking findings for docs/backlog.md:\n- ${backlog.join('\n- ') || 'none'}`)
      if (done) { state['phase.package'] = head; state.pr = String(done.pr || '') }
    }
  }

  if (!stopped && !(state['phase.ci'] && at('ci')[0] === 'green')) {
    phase('CI')
    for (let round = 0; ; round++) {
      const ci = await agent(`${intro()} Watch CI on the pull request's head and report.`, { agentType: 'ci-watcher', schema: CI, effort: 'low' })
      if (!ci) { stopped = 'the CI watcher returned no result'; break }
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
    const m = await agent(`${intro()} Merge the pull request if every merge gate passes.`, { agentType: 'merger', schema: MERGE, effort: 'low' })
    if (!m || !m.merged) stopped = `not merged: ${m ? m.problem : 'no result'}`
    else note(`merged ${m.sha}: ${m.subject}${m.branch_deleted ? '' : ' (branch deletion refused)'}`)
  }
}

phase('Report')
const report = await agent(
  `Change \`${state.change || input.change || 'unknown'}\`. Write the report. Workflow notes:\n- ${notes.join('\n- ')}\n${stopped ? 'The run stopped: ' + stopped : 'The run finished.'}`,
  { agentType: 'reporter', schema: REPORT, effort: 'low' })
return report ? report.report : `No report; notes:\n${notes.join('\n')}${stopped ? '\nStopped: ' + stopped : ''}`
