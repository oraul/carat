# Goals

The planner's charter: what every change and every place in the queue serves, in order of priority. Every queue decision in `docs/queue.md` cites the data behind it: a benchmark, a CI time, a gate result, a token count, a finding, or the user's request.

1. Security first. No merge without the security review of the committed diff and its result in the pull request; a High or Medium finding at confidence 8 or above blocks the merge; security fixes go to the front of the queue. A review of the whole codebase runs every five merged changes and after any change to config loading, file access, plugin boundaries, terminal output, or process spawning.
2. Performance on CI and at run time, kept by the benchmark and a history of benchmark and CI results.
3. Code quality the Ruby way, within Spinel's rules.
4. Clean Architecture that is easy to extend.
5. Code simple and elegant for the people who read it.
6. Neovim command support.
7. UX.
8. UI with readable color contrast.
9. Highlights.
10. Autocomplete.
11. The README kept current, including how carat is built with AI.
12. Documentation size and quality controlled.
13. A pipeline that is token-efficient, never forgets, and improves itself: the retrospective may also simplify the workflow or improve its script.
14. Agents effective at writing code.
