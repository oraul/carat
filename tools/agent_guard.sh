#!/bin/sh
# The guard of the delivery agents. A PreToolUse hook in the frontmatter of
# each agent under .claude/agents/ runs it with the agent's profile and the
# tool call's JSON on stdin; it exits 2 with the reason on stderr to refuse
# the call and 0 to allow it.
#
# Usage: sh tools/agent_guard.sh PROFILE [DIR] < HOOK-JSON
#   read         the agents that never edit (scout, planner, checker, the
#                quality and security reviewers, benchmark, ci-watcher,
#                reporter, retrospective): no git command that writes the
#                history, the index, the tree, or a remote; no gh command; no
#                run state command that only the workflow or the contributor
#                runs, and no environment override of tools/run_state.sh; no
#                command naming the run state's directory
#   merger       the read rules, but the fast-forward of main, the deletion of
#                the change branch, and the merge gates' body file
#                build/pipeline/CHANGE.body.md are allowed
#   contributor  no git push (tools/run_state.sh push runs the gates first),
#                no gh command, no phase, review, stage, or init of the run
#                state, no environment override of it, and no command or file
#                edit naming its directory
# Any other profile refuses every call. A file tool (Write, Edit,
# NotebookEdit) of a read or merger agent may write only under DIR of the
# project (CLAUDE_PROJECT_DIR), none without one; the contributor's may
# write anywhere but the run state's directory. Text that names a refused
# command (a pack, a queue, a commit message) goes into a file through the
# Write tool, since a heredoc carries it in the command.
#
# It reads the command's text, so it stops an agent that text in the tree
# led astray, not one that hides a command behind a variable; the merge
# gate's comparison with the workflow's records (tools/gates.sh records) and
# branch protection stand behind it.
set -u

profile=${1:-}
dir=${2:-}

refuse() {
  echo "agent_guard: refused for the $profile profile: $*. Search for text with the Grep or Read tool and write text that names such a command with the Write tool; the workflow records phases and reviews, and only the contributor pushes, through tools/run_state.sh push." >&2
  exit 2
}

# The first JSON string field KEY of the input with its escapes undone; an
# escaped newline becomes ";", so each line reads as a command of its own.
field() {
  tr '\n\r' '  ' | K="$1" awk '
    {
      if (!match($0, "\"" ENVIRON["K"] "\"[ \t]*:[ \t]*\"")) exit
      s = substr($0, RSTART + RLENGTH)
      out = ""
      n = length(s)
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (c == "\"") break
        if (c == "\\") {
          i++
          c = substr(s, i, 1)
          if (c == "n") c = ";"
          else if (c == "t" || c == "r") c = " "
          else if (c == "u") { i += 4; c = "?" }
        }
        out = out c
      }
      print out
      exit
    }'
}

input=$(cat)
tool=$(printf '%s' "$input" | field tool_name)
path=$(printf '%s' "$input" | field file_path)
[ -n "$path" ] || path=$(printf '%s' "$input" | field notebook_path)
text=$(printf '%s' "$input" | field command)
[ "$tool" = Bash ] || text=$path

has() {
  printf '%s\n' "$text" | grep -q -E -- "$1"
}

# A word's start and end, and git with its global options (-C dir, -c x=y,
# --no-pager, --git-dir=x).
B='(^|[^A-Za-z0-9_.-])'
E='([^A-Za-z0-9_-]|$)'
GIT="${B}git( +-{1,2}[A-Za-z][A-Za-z-]*(=[^ ;&|]*)?( +[^ ;&|-][^ ;&|]*)?)* +"
WRITES='push|commit|add|merge|rebase|reset|tag|cherry-pick|revert|am|stash|restore|rm|mv|clean|pull|apply'
RUN_STATE="run_state[.]sh[\"']? +[\"']?"

case "$profile" in
  read)
    git_writes=$WRITES
    run_state_writes='phase|review|stage|push|history|init' ;;
  merger)
    # The branch deletion of the merger's step 5, a Conventional Branch
    # alone at the end of its command, and the body file of its step 2.
    text=$(printf '%s\n' "$text" | sed -E \
      -e 's#git +push +origin +--delete +(feature|bugfix|hotfix|release|chore)/[a-z0-9][a-z0-9-]* *([;&|)]|$)#deleted-branch \2#g' \
      -e 's#build/pipeline/[a-z0-9][a-z0-9-]*[.]body[.]md([^A-Za-z0-9._-]|$)#body-file\1#g')
    git_writes=$(printf '%s' "$WRITES" | sed 's/|merge|/|/')
    run_state_writes='phase|review|stage|push|history|init' ;;
  contributor)
    git_writes=push
    run_state_writes='phase|review|stage|init' ;;
  *)
    refuse "no such profile" ;;
esac

# A file tool: the path is all there is to judge.
if [ "$tool" != Bash ] && [ -n "$path" ]; then
  if [ "$profile" != contributor ]; then
    [ -n "$dir" ] || refuse "a file edit by an agent that writes no file: $path"
    case "$path" in
      *..*) refuse "a path with a parent step: $path" ;;
      "$dir"/*|"${CLAUDE_PROJECT_DIR:-.}/$dir"/*) ;;
      *) refuse "a file edit outside $dir: $path" ;;
    esac
  fi
  has "build/pipeline|pipeline/" && refuse "an edit of the run state's directory: $path"
  exit 0
fi

has "${GIT}(${git_writes})${E}" && refuse "a git command that writes the history, the index, the tree, or a remote"
has "${B}gh +[a-z]" && refuse "a gh command; the agents use the GitHub tools they list"
has "${RUN_STATE}(${run_state_writes})${E}" && refuse "a run state command that the workflow or the contributor runs"
if has "run_state[.]sh" && has "${B}(MAKE|STAGES|RUN_STATE_DIR|STAGE_DIR|METRICS_FILE)="; then
  refuse "an environment override of tools/run_state.sh"
fi
has "build/pipeline|pipeline/" && refuse "a command naming the run state's directory; read it with tools/run_state.sh show"
exit 0
