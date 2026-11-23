#!/bin/sh
# The guard of the delivery agents: an allowlist of the commands each
# agent needs. A PreToolUse hook in the frontmatter of each agent under
# .claude/agents/ runs the copy at origin's main, fetched from origin's
# address, the one the hook line pins (any other is refused), into a new
# temporary bare repository with no global or system configuration, every
# object hashed on arrival, then removed (never read from the project's
# objects, configuration, or local ref origin/main, all of which branch
# code can write), with the agent's profile and the tool call's JSON on
# stdin, and refuses the call on any status but 0; the guard exits 2 with
# the reason on stderr to refuse and 0 to allow.
#
# The hook line pins origin by digest, naming no address: it accepts
# remote.origin.url, .git stripped, only when its git blob id is the one
# it lists, that of the repository's address in its https form, computed
# as printf %s FORM | git hash-object --stdin, and recomputed when the
# repository moves, with ORIGIN_IDS in .claude/workflows/deliver-change.js,
# the merge gates' green line's pin: the same, then with .git. The ssh
# and scp forms are refused, since the ssh client's own configuration,
# which no pinned git environment reaches, chooses the host they reach.
#
# Usage: sh tools/agent_guard.sh PROFILE [DIR] < HOOK-JSON
#
# A Bash command is read as the shell reads it: words with their quotes
# and escapes removed, operators (; && || | &), redirections, and
# comments, which end at the line break with no continuation. Refused
# outright, since the guard cannot know what they run: $ in any form
# (variables, substitutions, ANSI-C quoting), backquotes, parentheses,
# here-documents, unquoted * ? [ ] { }, a leading ~, a command named by a
# path, and an assignment before a command other than BASE, CHANGE, and
# RECORDS before tools/gates.sh or the merge gates. Every simple command
# must then match a form of its profile; every word is refused with a
# parent step (..) as a path segment or naming the run state's directory
# build/pipeline, but the pull request body file build/pipeline/NAME.body.md
# as the body gate's argument, never a link, and the text of a note
# (sh tools/run_state.sh note CHANGE KIND TEXT), which is only stored.
#
# Forms of every profile: ls cat head tail wc grep diff cmp sort (the
# short options of SORT_FLAGS, -k, and -t) uniq (one file at most) cut tr
# nl comm basename dirname realpath readlink stat du pwd echo printf true;
# date with its read options, -d, -r, and a +FORMAT operand only; find
# without -exec -execdir -ok -okdir -delete -fprint -fprint0 -fprintf -fls;
# sed -n with a line-number print script; cd to the project or a worktree
# tmp/.NAME; git, after GIT_CONFIG_GLOBAL=/dev/null and
# GIT_CONFIG_NOSYSTEM=1 at most, with the global options -C (the project
# or a worktree tmp/.NAME), -c core.hooksPath=/dev/null,
# --no-replace-objects (which only stops git following refs/replace), and
# --no-pager, and the verbs status log show diff rev-parse merge-base ls-files ls-tree cat-file blame describe shortlog
# rev-list grep show-ref for-each-ref name-rev (none with a prefix of
# --output, --ext-diff, --textconv, --filters, --upload-pack,
# --receive-pack, --exec, or --open-files-in-pager, nor grep with a short
# option cluster holding O), branch with listing options, remote -v,
# remote get-url origin, remote set-head origin main, fetch -q --prune
# origin or -q --refmap= origin MAIN_REFSPEC (not while origin is a local
# repository, local_origin),
# ls-remote origin with listing options and branch names, worktree add,
# remove, list, and prune of a worktree tmp/.NAME, and checkout -q
# --detach origin/main inside one (-C); sh tools/lane_facts.sh CHANGE,
# which writes nothing, the merger's not after a cd into a worktree,
# whose copy is the branch's. A tmp/.NAME that exists is a
# worktree only when it is a linked worktree of the project (worktree).
#   read         adds mkdir and rm under DIR; make -s, -C tmp/.NAME, the
#                targets dev-build test-build bench-budget metrics
#                metrics-compare bench, and PREFIX and SPINEL_CACHE_DIR at
#                the project's tmp/.toolchain and build/spinel-cache,
#                BASE_METRICS, SCENARIOS; sh tools/run_state.sh show status
#                pending get trusted check scope settled moved bench metrics
#                metric note (a late-finding, held-finding, or
#                unpushed-finding note only in the close profile)
#                budget spent review-due backlog-dups backlog-oldest;
#                [BASE=REV] sh
#                tools/gates.sh GATE...; sh tools/metrics.sh measure OUT
#                [SCENARIO...], OUT
#                build/metrics/current.tsv of the project or a worktree
#                tmp/.NAME with no link on its way, and compare BASE CURRENT
#   merger       adds sh tools/run_state.sh show status get trusted metric
#                lane-close CHANGE (the one merged: its run state holds the push and the gates' pass),
#                set CHANGE ci "red|green HEX", set CHANGE merged HEX;
#                CHANGE=NAME RECORDS=... sh tmp/.merge-gates/tools/gates.sh
#                merge BODY, never the branch's tools/gates.sh merge; sh
#                tools/ci_wait.sh N; sh tools/open_pr.sh message CHANGE
#                SHA, SHA 40 digits, after no cd into a worktree (main's
#                copy, never the branch's); git checkout -q main, git
#                merge -q --ff-only origin/main, git branch -D BRANCH,
#                BRANCH a Conventional Branch, and no git push (the
#                repository deletes a merged branch itself); git
#                hash-object --stdin, with no other option; git fsck
#                --no-dangling --no-progress origin/main, which writes
#                nothing, the green line's hash of every object before
#                the merge gates; git -C tmp/.merge-gates read-tree origin/main,
#                with no other option, which writes that worktree's index
#                alone, the green line's reset of the copy's index before
#                its diff --quiet hashes every file against main's tree
#   contributor  adds git -c user.name=X -c user.email=Y, git add commit mv
#                rm restore, git merge origin/main; make -s -k TARGET with
#                the variables of MAKE_VARS, no shell character in a value;
#                openspec and npx of the Makefile's OPENSPEC_PACKAGE
#                alone; mkdir rm cp
#                mv touch chmod; sh tools/run_state.sh show status pending
#                get budget history groom plan-apply merge-main CHANGE (after cd tmp/.lane-CHANGE)
#                reviewed-edits, check CHANGE with no COMMIT (its own
#                check, which backs no commit), push CHANGE
#                [--ci-fix | --review-fix | --main-moved | --pr-text],
#                set CHANGE pr N; sh tools/gates.sh GATE... or pr-body BODY;
#                sh tools/open_pr.sh write CHANGE TITLE and wait CHANGE
#                [SECONDS], which push nothing; never a pull request
#                create tool or API
#   runner       adds make doctor and make toolchain (no option but -s,
#                no variable); sh tools/run_state.sh show get trusted
#                plan-needed review-due, lane-open and init as CHANGE
#                BRANCH (a Conventional Branch or main), and the
#                workflow's records phase review metric ci-stages note,
#                carried CHANGE COMMIT (the check's stage records as a
#                pass, in place of a checker start),
#                (never a late, held, or unpushed finding), set
#                CHANGE records skip, and set CHANGE hold
#                security-first: the resume and record starts and
#                sprint planning's due and record starts, which write
#                no file and run no tools/gates.sh
#   close        the read profile, plus sh tools/run_state.sh phase CHANGE
#                NAME COMMIT with NAME one of CLOSE_PHASES, the phases
#                no merge gate reads, or CHANGE NAME merged (NAME merge,
#                retro, or report, at the squash commit the run state
#                resolves; merge also with the reported COMMIT), and
#                ci-stages CHANGE COMMIT (a full
#                sha), and the late, held, and unpushed finding notes
#                (recordLate): the retrospective's closing start
#                runs the run's last records, never review and never the
#                phase of check, quality, security, or bench
# The merger alone may call the GitHub merge tool (merge_tool, below). Any
# other profile refuses every call, and every profile refuses every call
# while .git/config sets a RISKY_CONFIG key or a fetch refspec other than
# a clone's.
#
# A write target (a redirection's target, a path argument of mkdir rm cp
# mv touch chmod, a file tool's path) has no parent step, and its real
# path, links followed, lies in the project, outside .git/, build/ itself,
# and the run state's directory, and names no local settings file of
# Claude Code (LOCAL_SETTINGS) nor its .claude directory, for every
# profile, written or real; for read and merger it lies under the real
# path of DIR, a redirection also under build/stages/, and an agent
# without DIR edits no file. Every call is refused while one of
# LOCAL_FILES stands untracked at the top of the project. The
# contributor's file tools may write the body file itself, never through
# a link. A link target whose parent step follows a missing directory is
# refused, since the write resolves it lexically.
#
# The guard stops an agent that text in the tree led astray; the
# contributor edits the scripts and the Makefile it runs, so for it the
# reviews, the merge gate's records, and branch protection stand behind it.
set -u

profile=${1:-}
dir=${2:-}
project=${CLAUDE_PROJECT_DIR:-$(pwd)}
MAKE_VARS='T S FILE TESTS SCENARIOS BASE_METRICS ALLOC_BUDGET ANALYSIS_ROUNDS DIAGNOSE_SKIP CARAT_BIN TEST_OPT NAME AREA DIR ACTION SPEC'
BRANCH='^(feature|bugfix|hotfix|release|chore)/[a-z0-9][a-z0-9-]*$'
CHANGE_NAME='^[a-z0-9][a-z0-9-]*$'
BODY='^build/pipeline/[a-z0-9][a-z0-9-]*[.]body[.]md$'
# The local files Claude Code reads beside the tracked ones: its settings
# (permissions and hooks), its servers, and its instructions, none of them
# reviewed. A write of one can turn the hooks off, so the next agent runs
# unguarded: no profile writes one, anywhere in the project, nor the
# .claude directory itself (a mv onto it or into it). LOCAL_FILES are the
# three at the top of the project, where the guard refuses every call
# while one stands untracked.
LOCAL_SETTINGS='(^|/)(\.claude(/+\.)*/*|\.claude/+(\./+)*settings\.local\.json|\.mcp\.json|CLAUDE\.local\.md)$'
LOCAL_FILES='.claude/settings.local.json .mcp.json CLAUDE.local.md'
CLOSE_PHASES='plan implement package ci merge retro report'
# The refspec of the green line's one fetch of main, and the fetch refspec
# a clone sets, the one under which origin/main is origin's main.
MAIN_REFSPEC='+refs/heads/main:refs/remotes/origin/main'
DEFAULT_FETCH='+refs/heads/*:refs/remotes/origin/*'

refuse() {
  echo "agent_guard: refused for the ${shown:-$profile} profile: $*. Each profile runs only the commands its agent needs, listed in tools/agent_guard.sh: search with the Grep or Read tool, put text that names a refused form into a file with the Write tool, and push only through tools/run_state.sh push." >&2
  exit 2
}

# close is the read profile with the closing phase records (run_state_form).
closing=0
case "$profile" in read|merger|contributor|runner) ;; close) shown=close closing=1 profile=read ;; *) refuse "no such profile" ;; esac

# The first JSON string field KEY of the input with its escapes undone; an
# escaped newline becomes the character \001, which lex reads as the shell
# reads a line break: inside single quotes a character of the word, at the
# end of a comment its end, after a backslash elsewhere a line continuation
# dropped with it, and otherwise the end of a command. A raw \001 becomes
# "?". An escaped carriage return becomes "?" too, since the shell reads
# it as a character of the word, not a blank; a raw one, JSON whitespace
# between fields, a blank. A \u escape of a printable ASCII character is
# that character, any other one "?", which the lexer refuses outside quotes.
field() {
  tr '\n\r\001' '  ?' | K="$1" awk '
    BEGIN { HEX = "0123456789abcdef"; NL = "\001" }
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
          if (c == "n") c = NL
          else if (c == "t") c = " "
          else if (c == "r") c = "?"
          else if (c == "u") {
            h = tolower(substr(s, i + 1, 4))
            i += 4
            c = "?"
            if (h ~ /^00[0-7][0-9a-f]$/) {
              v = (index(HEX, substr(h, 3, 1)) - 1) * 16 + index(HEX, substr(h, 4, 1)) - 1
              if (v == 10) c = NL
              else if (v == 9) c = " "
              else if (v >= 32 && v < 127) c = sprintf("%c", v)
            }
          }
        }
        out = out c
      }
      print out
      exit
    }'
}

# lex: the command's tokens, one a line: W and a word with its quotes and
# escapes removed, O and an operator, R and w (a write), r (a read), or d
# (a descriptor copy, or a write when its target is not a descriptor)
# before the redirection's target word, or E and the reason to refuse. A
# line break (\001 from field) is a ";" between commands and inside quotes;
# a backslash before it outside single quotes joins the lines, and it ends
# a comment, where a backslash escapes nothing. Only a bare digit run, no
# quote or backslash in it, is the descriptor before a redirection.
lex() {
  awk '
    function fail(why) { print "E" why; exit }
    function flush() { if (inw) print "W" w; w = ""; inw = 0; lit = 0 }
    {
      NL = "\001"
      s = $0; n = length(s); w = ""; inw = 0; lit = 0; q = ""
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        d = substr(s, i + 1, 1)
        if (q == "\047") { if (c == "\047") q = ""; else w = w (c == NL ? ";" : c); continue }
        if (q == "\"") {
          if (c == "\"") { q = ""; continue }
          if (c == "$" || c == "`") fail("a $ expansion or a command substitution inside double quotes")
          if (c == "\\" && d == NL) { i++; continue }
          if (c == "\\" && i < n && index("\"\\$`", d)) { i++; w = w d; continue }
          w = w (c == NL ? ";" : c)
          continue
        }
        if (c == "\\" && d == NL) { i++; continue }
        if (c == "\047" || c == "\"") { q = c; inw = 1; lit = 1; continue }
        if (c == "\\") { if (i < n) { i++; w = w d }; inw = 1; lit = 1; continue }
        if (c == "$") fail("a $ expansion: a variable, a substitution, or ANSI-C quoting")
        if (c == "`") fail("a command substitution")
        if (c == "(" || c == ")") fail("a subshell, a group, or a process substitution")
        if (index("*?[]{}", c)) fail("an unquoted glob or brace character " c)
        if (c == "~" && !inw) fail("a ~ expansion")
        if (c == "#" && !inw) { while (i < n && substr(s, i + 1, 1) != NL) i++; continue }
        if (c == " ") { flush(); continue }
        if (c == ";" || c == NL) { flush(); print "O;"; continue }
        if (c == "&") {
          flush()
          if (d == "&") { print "O&&"; i++ }
          else if (d == ">") { i++; if (substr(s, i + 1, 1) == ">") i++; print "Rw" }
          else print "O&"
          continue
        }
        if (c == "|") {
          flush()
          if (d == "|") { print "O||"; i++ }
          else { if (d == "&") i++; print "O|" }
          continue
        }
        if (c == "<" || c == ">") {
          if (inw && !lit && w ~ /^[0-9]+$/) { w = ""; inw = 0 } else flush()
          if (c == "<" && d == "<") fail("a here-document or a here-string")
          if (d == "&") { i++; print "Rd"; continue }
          if (d == ">" || d == "|") i++
          print (c == "<" && d != ">") ? "Rr" : "Rw"
          continue
        }
        w = w c
        inw = 1
      }
      if (q != "") fail("an unterminated quote")
      flush()
    }'
}

# real_path PATH: sets real to PATH, relative to the project, with a final
# link followed and its nearest existing directory resolved (pwd -P); a link
# chain longer than eight or a dangling link on the way is refused.
real_path() {
  real=$1
  case "$real" in /*) ;; *) real="$project/$real" ;; esac
  while :; do
    case "$real" in
      ?*/) real=${real%/} ;;
      ?*/.) real=${real%/.} ;;
      *) break ;;
    esac
  done
  hops=0
  while [ -L "$real" ]; do
    hops=$((hops + 1))
    [ $hops -le 8 ] || refuse "a chain of links: $1"
    target=$(readlink -- "$real")
    case "$target" in
      /*) real=$target ;;
      *) real="$(dirname -- "$real")/$target" ;;
    esac
  done
  up=$(dirname -- "$real")
  rest=$(basename -- "$real")
  while [ ! -d "$up" ]; do
    [ ! -L "$up" ] || refuse "a path through a dangling link: $1"
    rest="$(basename -- "$up")/$rest"
    up=$(dirname -- "$up")
  done
  # A parent step after a missing directory stays unresolved here but
  # resolves lexically when the file is written, past any link before it.
  case "/$rest/" in */../*) refuse "a parent step after a missing directory: $1" ;; esac
  real="$(cd -P -- "$up" && pwd -P)/$rest"
  case "$real" in //*) real=${real#/} ;; esac
}

real_path "$project"
project_real=$real

# matches TEXT REGEX: TEXT, one line, matches the extended REGEX.
matches() {
  case "$1" in *"
"*) return 1 ;; esac
  printf '%s\n' "$1" | grep -q -E -- "$2"
}

# relative PATH: PATH without the project's prefix, as written or real.
relative() {
  rel=${1#"$project"/}
  rel=${rel#"$project_real"/}
  rel=${rel#./}
}

parent_step() {
  case "/$1/" in */../*) refuse "a parent step (..) in $1" ;; esac
}

# The rules every word of every command obeys.
word_rules() {
  parent_step "$1"
  case "$1" in
    *build/pipeline*|*pipeline/*) refuse "a word naming the run state's directory: $1; read the run state with tools/run_state.sh show" ;;
  esac
}

# under DIR: the real path real lies in the real path of DIR.
under() {
  held=$real
  real_path "$1"
  case "$held" in
    "$real"|"$real"/*) real=$held; return 0 ;;
  esac
  real=$held
  return 1
}

# local_settings PATH WORD: PATH, WORD's written or real path relative to
# the project, is not a local settings file nor the .claude directory.
local_settings() {
  ! matches "$1" "$LOCAL_SETTINGS" || settings_write "$2"
}
settings_write() {
  refuse "a write of $1, a local settings file of Claude Code or its .claude directory, which can turn the hooks off for the next agent"
}

# write_target PATH KIND: KIND is redirect, command, or file. Only a
# redirection may name /dev/null: as the operand of rm, mv, or cp it
# would replace the device node.
write_target() {
  if [ "$2" = redirect ] && [ "$1" = /dev/null ]; then return 0; fi
  parent_step "$1"
  relative "$1"
  local_settings "$rel" "$1"
  case "$1" in /*) at=$1 ;; *) at="$project/$1" ;; esac
  if matches "$rel" "$BODY" && [ -L "$at" ]; then
    refuse "a pull request body file that is a link: $1"
  fi
  written=$rel
  real_path "$1"
  case "$real" in
    "$project_real"/*) ;;
    *) refuse "a write outside the project: $1" ;;
  esac
  rel=${real#"$project_real"/}
  local_settings "$rel" "$1"
  # The real path of each of LOCAL_FILES, for a link on the way to it (a
  # linked .claude) that neither the written nor the real name shows.
  held=$real
  for f in $LOCAL_FILES; do
    real_path "$f"
    [ "$real" != "$held" ] || settings_write "$1"
  done
  real=$held
  case "/$rel/" in */.git/*) refuse "a write under .git, whose hooks and configuration run commands: $1" ;; esac
  case "$rel" in
    build) refuse "a write of the directory that holds the run state's: $1" ;;
    build/pipeline|build/pipeline/*)
      if [ "$2" = file ] && [ "$profile" = contributor ] && [ "$written" = "$rel" ] && matches "$rel" "$BODY"; then
        return 0
      fi
      refuse "a write to the run state's directory: $1" ;;
  esac
  [ "$profile" != contributor ] || return 0
  if [ "$2" = redirect ] && under build/stages; then return 0; fi
  [ -n "$dir" ] || refuse "a write by an agent that writes no file: $1"
  under "$dir" || refuse "a write outside $dir, links followed: $1"
}

# body_arg INDEX WORD: WORD, at INDEX of the command, is the body file.
body_arg() {
  relative "$2"
  matches "$rel" "$BODY" || refuse "not a pull request body file: $2"
  [ ! -L "$project_real/$rel" ] || refuse "a pull request body file that is a link: $2"
  body_at=$1
}

only_profiles() {
  case " $1 " in *" $profile "*) ;; *) refuse "$2 is not a command of this profile" ;; esac
}

# Whether origin's url, as git resolves it with its lines joined, is set
# and names no hosted repository: a path, file:, or a remote helper's
# X::. Branch code run by the checks can point remote.origin.url at a
# repository it built, whose main a fetch would make origin/main, bringing
# its own gates and the guard the hooks read from it; the green line also
# checks the url before its fetch. An unset url fails any fetch anyway.
local_origin() {
  origin_url=$(git -C "$project_dir" remote get-url origin 2>/dev/null | tr -d '\n')
  [ -n "$origin_url" ] && ! matches "$origin_url" '^((https?|ssh|git)://[^/]|[A-Za-z0-9._-]+@[A-Za-z0-9.-]+:[^/])'
}

# worktree_name PATH: PATH is named tmp/.NAME, as a worktree of the
# project is; git worktree add and remove need no more, since git adds
# over no repository and removes only a worktree it lists.
worktree_name() {
  relative "$1"
  matches "$rel" '^tmp/[.][A-Za-z0-9_-]+$' || return 1
  case "$rel" in tmp/.toolchain|tmp/.spinel) return 1 ;; esac
}

# worktree PATH: PATH is a worktree tmp/.NAME of the project, where git and
# make may run. When it exists it must be a directory, not a link, whose
# .git file, not a link, names a worktree record of the project's own
# repository that names it back, so it shares the project's configuration
# and hooks, which the checks below judge: a repository branch code
# planted at tmp/.NAME would run its own. A path absent when the guard
# judges is admitted, so one call can add a worktree and use it; read and
# merger create nothing there but by git worktree add.
worktree() {
  worktree_name "$1" || return 1
  at=$project_real/$rel
  [ -e "$at" ] || [ -L "$at" ] || return 0
  [ -d "$at" ] && [ ! -L "$at" ] && [ -f "$at/.git" ] && [ ! -L "$at/.git" ] || return 1
  common=$(git -C "$project_dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  [ -n "$common" ] && common=$(cd "$common" 2>/dev/null && pwd -P) || return 1
  record=$(sed -n '1s/^gitdir: //p' "$at/.git")
  matches "${record#"$common"/worktrees/}" '^[A-Za-z0-9_-][A-Za-z0-9._-]*$' && [ "$record" != "${record#"$common"/worktrees/}" ] || return 1
  [ ! -L "$record" ] && [ "$(cat "$record/gitdir" 2>/dev/null)" = "$at/.git" ] && [ "$(cat "$record/commondir" 2>/dev/null)" = ../.. ]
}

# project_or_worktree PATH: PATH is the project or a worktree tmp/.NAME.
project_or_worktree() {
  case "$1" in
    "$project"|"$project_real"|.) return 0 ;;
  esac
  worktree "$1"
}

# options_in LIST WORD...: every WORD is one of LIST.
options_in() {
  list=" $1 "
  shift
  for a in "$@"; do
    case "$list" in *" $a "*) ;; *) return 1 ;; esac
  done
}

git_form() {
  shift
  wt=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -C)
        [ $# -ge 2 ] || refuse "git -C without a path"
        project_or_worktree "$2" || refuse "git -C other than the project or a worktree tmp/.NAME, since a repository elsewhere brings its own configuration: $2"
        wt=$2
        shift 2 ;;
      -c)
        [ $# -ge 2 ] || refuse "git -c without a value"
        case "$profile:$2" in
          contributor:user.name=*|contributor:user.email=*|*:core.hooksPath=/dev/null) ;;
          *) refuse "a git configuration override: -c $2" ;;
        esac
        shift 2 ;;
      --no-pager|-P|--no-replace-objects) shift ;;
      -*) refuse "the git option $1" ;;
      *) break ;;
    esac
  done
  [ $# -gt 0 ] || refuse "git without a command"
  verb=$1
  shift
  case "$verb" in
    status|log|show|diff|rev-parse|merge-base|ls-files|ls-tree|cat-file|blame|describe|shortlog|rev-list|grep|show-ref|for-each-ref|name-rev)
      for a in "$@"; do
        case "$a" in
          --?*)
            name=${a#--}
            name=${name%%=*}
            for bad in output ext-diff textconv filters upload-pack receive-pack exec open-files-in-pager; do
              case "$bad" in "$name"*) refuse "git $verb $a, a prefix of --$bad, which writes or runs a command" ;; esac
              case "$name" in "$bad"*) refuse "git $verb $a, which writes or runs a command" ;; esac
            done ;;
          -*O*) [ "$verb" != grep ] || refuse "git grep $a, whose -O runs a command" ;;
        esac
      done ;;
    branch)
      if [ "$profile" = merger ] && [ $# -eq 2 ] && [ "$1" = -D ] && matches "$2" "$BRANCH"; then return 0; fi
      options_in "--show-current --list -a --all -r --remotes -v -vv" "$@" || refuse "git branch other than a listing" ;;
    remote)
      case "$*" in
        -v|"get-url origin"|"set-head origin main") ;;
        *) refuse "git remote other than -v, get-url origin, and set-head origin main" ;;
      esac ;;
    fetch)
      # Without a refspec, or the pinned fetch of main with no configured
      # refspec read (--refmap=), as the green line runs it.
      case " $* " in
        *" $MAIN_REFSPEC "*) [ "$*" = "-q --refmap= origin $MAIN_REFSPEC" ] || [ "$*" = "--refmap= origin $MAIN_REFSPEC" ] ;;
        *) options_in "-q --quiet --prune -p origin" "$@" ;;
      esac || refuse "git fetch other than of origin without a refspec, or -q --refmap= origin $MAIN_REFSPEC"
      local_origin && refuse "git fetch while origin is \"$origin_url\", a local repository or a remote helper, not a hosted one" ;;
    ls-remote)
      remote=""
      for a in "$@"; do
        case "$a" in
          --heads|--tags|-h|-t|-q|--quiet|--exit-code|--refs) ;;
          -*) refuse "git ls-remote $a" ;;
          *)
            if [ -z "$remote" ]; then
              [ "$a" = origin ] || refuse "git ls-remote of other than origin: $a"
              remote=1
            else
              matches "$a" '^[A-Za-z0-9._/-]+$' || refuse "git ls-remote of other than branch names: $a"
            fi ;;
        esac
      done ;;
    worktree)
      sub=${1:-}
      [ $# -eq 0 ] || shift
      case "$sub" in
        add)
          paths=0
          for a in "$@"; do
            case "$a" in
              --detach|-f|--force|-q|--quiet) ;;
              -*) refuse "git worktree add $a" ;;
              *)
                paths=$((paths + 1))
                if [ $paths -eq 1 ]; then worktree_name "$a" || refuse "a worktree outside tmp/.NAME: $a"
                elif [ "$a" != origin/main ] || [ $paths -gt 2 ]; then refuse "a worktree of other than origin/main: $a"
                fi ;;
            esac
          done
          [ $paths -ge 1 ] || refuse "git worktree add without a path" ;;
        remove)
          paths=0
          for a in "$@"; do
            case "$a" in
              -f|--force) ;;
              -*) refuse "git worktree remove $a" ;;
              *) paths=$((paths + 1)); worktree_name "$a" || refuse "a worktree outside tmp/.NAME: $a" ;;
            esac
          done
          [ $paths -eq 1 ] || refuse "git worktree remove of other than one worktree" ;;
        list) options_in "--porcelain -v" "$@" || refuse "git worktree list $*" ;;
        prune) options_in "-n -v" "$@" || refuse "git worktree prune $*" ;;
        *) refuse "git worktree $sub" ;;
      esac ;;
    checkout)
      if [ "$profile" = merger ] && [ -z "$wt" ] && [ "$*" = "-q main" ]; then return 0; fi
      [ -n "$wt" ] && worktree "$wt" || refuse "git checkout outside a worktree tmp/.NAME"
      options_in "-q --quiet --detach -f --force origin/main" "$@" || refuse "git checkout other than of origin/main"
      case " $* " in *" origin/main "*) ;; *) refuse "git checkout other than of origin/main" ;; esac ;;
    merge)
      only_profiles "merger contributor" "git merge"
      if [ "$profile" = merger ]; then
        [ "$*" = "-q --ff-only origin/main" ] || [ "$*" = "--ff-only origin/main" ] ||
          refuse "git merge other than the fast-forward of main"
        return 0
      fi
      while [ $# -gt 0 ]; do
        case "$1" in
          -q|--quiet|--no-edit|--no-ff|--abort|--continue|origin/main) shift ;;
          -m) [ $# -ge 2 ] || refuse "git merge -m without a message"; shift 2 ;;
          *) refuse "git merge other than of origin/main: $1" ;;
        esac
      done ;;
    hash-object)
      # The green line's origin check hashes origin's url, writing nothing.
      only_profiles merger "git hash-object"
      [ "$*" = --stdin ] || refuse "git hash-object other than --stdin" ;;
    fsck)
      # The green line hashes every object of the store before the merge
      # gates, so no object branch code planted reaches them.
      only_profiles merger "git fsck"
      [ "$*" = "--no-dangling --no-progress origin/main" ] || refuse "git fsck other than --no-dangling --no-progress origin/main" ;;
    read-tree)
      # The green line reads main's tree into the copy's index with no
      # stat data, so its diff --quiet hashes every file of the copy; no
      # other worktree's index is the merger's to write.
      only_profiles merger "git read-tree"
      [ -n "$wt" ] && worktree "$wt" || refuse "git read-tree outside a worktree tmp/.NAME"
      relative "$wt"
      [ "$rel" = "${MERGE_GATES%%/tools/*}" ] || refuse "git read-tree in other than the merge gates' copy ${MERGE_GATES%%/tools/*}: $wt"
      [ "$*" = origin/main ] || refuse "git read-tree other than of origin/main" ;;
    add|commit|mv|rm|restore)
      only_profiles contributor "git $verb" ;;
    *) refuse "git $verb is not a command of this profile" ;;
  esac
}

# make_var NAME VALUE: a variable the profile may set, with a value no
# recipe can read as shell syntax.
make_var() {
  matches "$2" '^[]A-Za-z0-9._/ ,:+=@%[-]*$' || refuse "a shell character in the make variable $1"
  case "$profile:$1" in
    read:PREFIX) relative "$2"; [ "$rel" = tmp/.toolchain ] && [ "$2" != "$rel" ] || refuse "PREFIX other than the project's tmp/.toolchain" ;;
    read:SPINEL_CACHE_DIR) relative "$2"; [ "$rel" = build/spinel-cache ] && [ "$2" != "$rel" ] || refuse "SPINEL_CACHE_DIR other than the project's build/spinel-cache" ;;
    read:BASE_METRICS) ;;
    read:SCENARIOS) matches "$2" '^[a-z0-9 -]*$' || refuse "SCENARIOS other than scenario names" ;;
    contributor:*) case " $MAKE_VARS " in *" $1 "*) ;; *) refuse "the make variable $1" ;; esac ;;
    *) refuse "the make variable $1" ;;
  esac
}

make_form() {
  only_profiles "read contributor runner" make
  shift
  while [ $# -gt 0 ]; do
    if [ "$profile" = runner ]; then
      [ "$1" = -s ] || options_in "doctor toolchain" "$1" || refuse "make other than doctor or toolchain"
      shift
      continue
    fi
    case "$1" in
      -s) ;;
      -k) only_profiles contributor "make -k" ;;
      -C) [ $# -ge 2 ] && worktree "$2" || refuse "make -C outside a worktree tmp/.NAME"; shift ;;
      -*) refuse "the make option $1" ;;
      *=*) make_var "${1%%=*}" "${1#*=}" ;;
      *)
        if [ "$profile" = read ]; then
          options_in "dev-build test-build bench-budget metrics metrics-compare bench" "$1" || refuse "the make target $1"
        else
          matches "$1" '^[a-z][a-z0-9-]*$' || refuse "the make target $1"
        fi ;;
    esac
    shift
  done
}

run_state_form() {
  verb=${1:-}
  case "$profile:$verb" in
    read:show|read:status|read:pending|read:get|read:trusted|read:check|read:scope|read:bench|read:base-figures|read:metrics|read:metric|read:budget|read:spent|read:review-due|read:backlog-dups|read:backlog-oldest) ;;
    merger:show|merger:status|merger:get|merger:trusted|merger:metric) ;;
    merger:lane-close)
      # The change's name is a path component of the worktree lane-close
      # removes: it must be the change being merged, the one run state
      # holding the pushed head as gated too (the merge gates reset every
      # other run state's gated), not another lane's (sprint-guard-lows).
      [ $# -eq 2 ] && matches "$2" "$CHANGE_NAME" || refuse "tools/run_state.sh $verb other than CHANGE"
      merged_head=$(sed -n 's/^  "pushed": "\([0-9a-f]\{40\}\)",\{0,1\}$/\1/p' "$project_dir/build/pipeline/$2.json" 2>/dev/null | sed -n 1p)
      [ -f "$project_dir/build/pipeline/$2.json" ] && [ ! -L "$project_dir/build/pipeline/$2.json" ] && [ -n "$merged_head" ] &&
        grep -q -E "^  \"gated\": \"$merged_head\",?\$" "$project_dir/build/pipeline/$2.json" ||
        refuse "tools/run_state.sh lane-close of $2, whose run state does not record the push and the merge gates' pass at one head: only the change being merged" ;;
    contributor:merge-main)
      # merge-main merges into the branch of the directory it runs in: that
      # directory must be this change's worktree tmp/.lane-CHANGE, so a
      # name of another lane is no way to reach its worktree.
      [ $# -eq 2 ] && matches "$2" "$CHANGE_NAME" || refuse "tools/run_state.sh $verb other than CHANGE"
      [ -n "$cd_worktree" ] && worktree_name "$cd_worktree" && [ "$rel" = "tmp/.lane-$2" ] ||
        refuse "tools/run_state.sh merge-main $2 outside its worktree tmp/.lane-$2" ;;
    contributor:show|contributor:status|contributor:pending|contributor:get|contributor:budget|contributor:history|contributor:groom|contributor:plan-apply|contributor:reviewed-edits) ;;
    # The runner: the resume recipe and the records the workflow wrote
    # (cheap-tier), the note text data as for read. Sprint planning's notes
    # and plan notes, which quote reviewed code, run on the read profile
    # (the security reviewer's record mode), which records no review or
    # phase.
    runner:show|runner:get|runner:trusted|runner:plan-needed|runner:review-due|runner:phase|runner:review|runner:metric|runner:ci-stages) ;;
    runner:note)
      # As for read: the late, held, and unpushed finding notes are the
      # close profile's alone, which seed reads back as findings.
      case "${3:-}" in
        late-finding|held-finding|unpushed-finding)
          refuse "tools/run_state.sh note of ${3}, which only the workflow's close profile records" ;;
      esac
      [ $# -ne 4 ] || data_at=6 ;;
    runner:carried)
      # The carried check (cache-reuse): the workflow's one command in place
      # of a checker start, a CHANGE and the commit it backs.
      [ $# -eq 3 ] && matches "$2" "$CHANGE_NAME" && matches "$3" '^[0-9a-f]{7,40}$' ||
        refuse "tools/run_state.sh carried other than CHANGE COMMIT" ;;
    runner:lane-open|runner:init)
      [ $# -eq 3 ] && matches "$2" "$CHANGE_NAME" && { [ "$3" = main ] || matches "$3" "$BRANCH"; } ||
        refuse "tools/run_state.sh $verb other than CHANGE BRANCH" ;;
    runner:set)
      [ $# -eq 4 ] && matches "$2" "$CHANGE_NAME" && { { [ "$3" = records ] && [ "$4" = skip ]; } || { [ "$3" = hold ] && [ "$4" = security-first ]; }; } ||
        refuse "tools/run_state.sh set other than CHANGE records skip or CHANGE hold security-first" ;;
    contributor:check)
      # The contributor checks its own head (contributor-self-check): never
      # with a COMMIT, which would make the check skip or carry stage records.
      [ $# -eq 2 ] && matches "$2" "$CHANGE_NAME" || refuse "tools/run_state.sh check other than CHANGE, with no commit" ;;
    contributor:push)
      [ $# -ge 2 ] && [ $# -le 3 ] && matches "$2" "$CHANGE_NAME" && { [ $# -eq 2 ] || [ "$3" = --ci-fix ] || [ "$3" = --review-fix ] || [ "$3" = --main-moved ] || [ "$3" = --pr-text ]; } ||
        refuse "tools/run_state.sh push other than CHANGE [--ci-fix | --review-fix | --main-moved | --pr-text]" ;;
    merger:set|contributor:set)
      [ $# -eq 4 ] && matches "$2" "$CHANGE_NAME" || refuse "tools/run_state.sh set other than CHANGE KEY VALUE"
      case "$profile:$3" in
        merger:ci) matches "$4" '^(red|green) [0-9a-f]{7,40}$' || refuse "a CI record other than red or green and a commit" ;;
        merger:merged) matches "$4" '^[0-9a-f]{7,40}$' || refuse "a merged record other than a commit" ;;
        contributor:pr) matches "$4" '^[0-9]+$' || refuse "a pull request record other than a number" ;;
        *) refuse "tools/run_state.sh set of $3" ;;
      esac ;;
    read:note)
      # The late, held, and unpushed finding notes are the workflow's close
      # records (recordLate), which seed reads back as findings: no other
      # read start writes them (pipeline-lows-a).
      case "${3:-}" in
        late-finding|held-finding|unpushed-finding)
          [ "$closing" = 1 ] || refuse "tools/run_state.sh note of ${3}, which only the workflow's close profile records" ;;
      esac
      # The note's text is data run_state.sh only stores, never a path:
      # a finding naming the run state's directory or a parent step is
      # recorded, not refused (merge-path-lows); its word is the sixth of
      # sh tools/run_state.sh note CHANGE KIND TEXT.
      [ $# -ne 4 ] || data_at=6 ;;
    read:moved)
      [ $# -eq 3 ] && matches "$2" "$CHANGE_NAME" && matches "$3" '^[0-9a-f]{7,40}$' ||
        refuse "tools/run_state.sh moved other than CHANGE COMMIT" ;;
    read:settled)
      [ $# -eq 3 ] && matches "$2" "$CHANGE_NAME" && matches "$3" '^[0-9a-f]{7,40}$' ||
        refuse "tools/run_state.sh settled other than CHANGE COMMIT" ;;
    read:ci-stages)
      [ "$closing" = 1 ] && [ $# -eq 3 ] && matches "$2" "$CHANGE_NAME" && matches "$3" '^[0-9a-f]{40}$' ||
        refuse "tools/run_state.sh ci-stages, which only the close profile runs, as CHANGE COMMIT" ;;
    read:phase)
      [ "$closing" = 1 ] && matches "$2" "$CHANGE_NAME" && options_in "$CLOSE_PHASES" "$3" && {
        { [ $# -eq 4 ] && matches "$4" '^[0-9a-f]{7,40}$'; } ||
        { [ $# -eq 4 ] && [ "$4" = merged ] && options_in "merge retro report" "$3"; } ||
        { [ $# -eq 5 ] && [ "$3" = merge ] && [ "$4" = merged ] && matches "$5" '^[0-9a-f]{7,40}$'; }
      } ||
        refuse "tools/run_state.sh phase, which the workflow runs; the close profile records only CHANGE NAME COMMIT, NAME one of $CLOSE_PHASES, or CHANGE NAME merged, NAME merge, retro, or report, the merge with the reported COMMIT" ;;
    *) refuse "tools/run_state.sh $verb, which the workflow or another agent runs" ;;
  esac
}

gates_form() {
  [ $# -gt 0 ] || refuse "tools/gates.sh without a gate"
  case "$profile:$1" in
    merger:merge|contributor:pr-body)
      [ $# -eq 2 ] || refuse "tools/gates.sh $1 other than with the body file"
      body_arg 4 "$2" ;;
    *)
      for a in "$@"; do
        matches "$a" '^[a-z][a-z-]*$' || refuse "tools/gates.sh with other than gate names: $a"
      done ;;
  esac
  for e in $envs; do
    case "$profile:$e" in
      *:BASE|merger:CHANGE|merger:RECORDS|contributor:CHANGE) ;;
      *) refuse "an assignment of $e before tools/gates.sh" ;;
    esac
  done
}

# metrics_out PATH: PATH, the OUT of tools/metrics.sh measure, is
# METRICS_OUT of the project or of a worktree tmp/.NAME, with no link on
# its way. The guard does not follow cd, so a relative PATH is checked in
# the project and in every worktree.
METRICS_OUT=build/metrics/current.tsv
metrics_out() {
  relative "$1"
  out=$rel
  case "$out" in
    "$METRICS_OUT")
      roots=.
      case "$1" in
        /*) ;;
        *)
          # Globbing is off (set -f); a name worktree takes splits on no
          # space.
          for w in $(ls -A "$project_real/tmp" 2>/dev/null); do
            [ -d "$project_real/tmp/$w" ] && worktree "tmp/$w" && roots="$roots tmp/$w"
          done ;;
      esac ;;
    tmp/.*/"$METRICS_OUT")
      roots=${out%/"$METRICS_OUT"}
      worktree "$roots" || refuse "tools/metrics.sh measure into other than a worktree tmp/.NAME: $1" ;;
    *) refuse "tools/metrics.sh measure into other than $METRICS_OUT of the project or a worktree tmp/.NAME: $1" ;;
  esac
  for r in $roots; do
    at=$r/$METRICS_OUT
    [ "$r" != . ] || at=$METRICS_OUT
    real_path "$at"
    [ "$real" = "$project_real/$at" ] || refuse "tools/metrics.sh measure into a path through a link: $1"
  done
}

# The merge gates the merger runs: those of the worktree of origin/main the
# workflow's command adds, which the branch cannot have edited.
MERGE_GATES=tmp/.merge-gates/tools/gates.sh
script_form() {
  [ $# -ge 2 ] || refuse "sh without a script"
  case "$2" in -*) refuse "a shell option: sh $2" ;; esac
  relative "$2"
  script=$rel
  [ -z "$envs" ] || [ "$script" = tools/gates.sh ] || [ "$script" = "$MERGE_GATES" ] || refuse "an assignment before $2"
  shift 2
  case "$script" in
    tools/run_state.sh) run_state_form "$@" ;;
    tools/gates.sh)
      [ "$profile" != runner ] || refuse "tools/gates.sh is not a command of this profile"
      [ "$profile:${1:-}" != merger:merge ] || refuse "the branch's tools/gates.sh merge; the merger runs $MERGE_GATES, the copy of origin/main"
      gates_form "$@" ;;
    "$MERGE_GATES")
      only_profiles merger "$MERGE_GATES"
      [ "${1:-}" = merge ] || refuse "$MERGE_GATES other than merge BODY"
      gates_form "$@" ;;
    tools/metrics.sh)
      only_profiles read "tools/metrics.sh"
      case "${1:-}" in
        measure)
          [ $# -ge 2 ] || refuse "tools/metrics.sh measure without OUT"
          metrics_out "$2"
          shift 2
          for a in "$@"; do
            matches "$a" '^[a-z0-9-]+$' || refuse "tools/metrics.sh measure with other than scenario names: $a"
          done ;;
        compare) [ $# -eq 3 ] || refuse "tools/metrics.sh compare other than BASE CURRENT" ;;
        *) refuse "tools/metrics.sh other than measure or compare" ;;
      esac ;;
    tools/open_pr.sh)
      # The pull request opened on the branch push: the contributor writes
      # pr.md before its push and waits for the pull request after it; the
      # merger prints the squash message from it at the pushed head; read,
      # gate, rule, and open are the open-pr workflow's alone.
      case "${1:-}" in
        write)
          only_profiles contributor "tools/open_pr.sh write"
          [ $# -eq 3 ] && matches "$2" "$CHANGE_NAME" || refuse "tools/open_pr.sh write other than CHANGE TITLE" ;;
        wait)
          only_profiles contributor "tools/open_pr.sh wait"
          { [ $# -eq 2 ] || { [ $# -eq 3 ] && matches "$3" '^[0-9]{1,3}$'; }; } && matches "$2" "$CHANGE_NAME" ||
            refuse "tools/open_pr.sh wait other than CHANGE [SECONDS]" ;;
        message)
          only_profiles merger "tools/open_pr.sh message"
          # Main's copy in the main checkout: a worktree's copy is the
          # branch's, which code run by the checks can have rewritten.
          [ -z "$cd_worktree" ] || refuse "tools/open_pr.sh message after cd $cd_worktree: run main's copy in the main checkout"
          [ $# -eq 3 ] && matches "$2" "$CHANGE_NAME" && matches "$3" '^[0-9a-f]{40}$' ||
            refuse "tools/open_pr.sh message other than CHANGE SHA (40 digits)" ;;
        *) refuse "tools/open_pr.sh other than write, wait, or message" ;;
      esac ;;
    tools/lane_facts.sh)
      # The merger runs main's copy in the main checkout, as for open_pr.sh
      # message: a worktree's copy is the branch's, and the script finds
      # the lane through git-common-dir, so its lines are the same there.
      [ "$profile" != merger ] || [ -z "$cd_worktree" ] ||
        refuse "tools/lane_facts.sh after cd $cd_worktree for the merger: run main's copy in the main checkout"
      [ $# -eq 1 ] && matches "$1" "$CHANGE_NAME" || refuse "tools/lane_facts.sh other than CHANGE" ;;
    tools/ci_wait.sh)
      only_profiles merger "tools/ci_wait.sh"
      [ $# -eq 1 ] && matches "$1" '^[0-9]+$' || refuse "tools/ci_wait.sh other than SECONDS" ;;
    *) refuse "the script $script is not one this profile runs" ;;
  esac
}

# files_form: mkdir rm cp mv touch chmod, every argument but a short
# option a write target.
files_form() {
  cmd=$1
  shift
  ends=""
  for a in "$@"; do
    if [ -z "$ends" ]; then
      case "$a" in
        --) ends=1; continue ;;
        -[A-Za-z]*) matches "$a" '^-[A-Za-z]+$' && continue; refuse "the $cmd option $a" ;;
        -*) refuse "the $cmd option $a" ;;
      esac
    fi
    write_target "$a" command
  done
}

# sort_form: sort with short options of SORT_FLAGS and -k -t with their
# values only, since GNU sort clusters short options (-uo FILE) and takes
# a long option by any unambiguous prefix (--outp, --compress-prog).
SORT_FLAGS=bdfghiMnRrsuVzcCm
sort_form() {
  shift
  value=""
  ends=""
  for a in "$@"; do
    if [ -n "$value" ]; then value=""; continue; fi
    [ -z "$ends" ] || continue
    case "$a" in
      --) ends=1 ;;
      -) ;;
      --*) refuse "the sort option $a, since a long option can write a file or run a command" ;;
      -*)
        rest=${a#-}
        while [ -n "$rest" ]; do
          ch=${rest%"${rest#?}"}
          rest=${rest#?}
          case "$ch" in
            k|t) [ -n "$rest" ] || value=1; rest="" ;;
            *)
              case "$SORT_FLAGS" in
                *"$ch"*) ;;
                *) refuse "the sort option -$ch in $a; sort takes only -$SORT_FLAGS, -k, and -t" ;;
              esac ;;
          esac
        done ;;
    esac
  done
}

# uniq_form: uniq with at most one operand, `-` and the words after `--`
# included, since a second operand is the file uniq writes.
uniq_form() {
  shift
  n=0
  ends=""
  for a in "$@"; do
    if [ -z "$ends" ]; then
      case "$a" in
        --) ends=1; continue ;;
        -) ;;
        -*) continue ;;
      esac
    fi
    n=$((n + 1))
  done
  [ $n -le 1 ] || refuse "uniq with a second operand, which uniq writes as its output file"
}

# date_form: date with its read options, -d and -r with their values, and
# a +FORMAT operand only, since -s, --set (or any prefix of it, which GNU
# date takes), and a date operand set the clock the run state's at.*
# times read.
date_form() {
  shift
  value=""
  for a in "$@"; do
    if [ -n "$value" ]; then value=""; continue; fi
    case "$a" in
      -u|--utc|--universal|-R|--rfc-email|-I|-Idate|-Ihours|-Iminutes|-Iseconds|-Ins|--iso-8601|--iso-8601=date|--iso-8601=hours|--iso-8601=minutes|--iso-8601=seconds|--iso-8601=ns|--rfc-3339=date|--rfc-3339=seconds|--rfc-3339=ns|--date=*|--reference=*|+*) ;;
      -d|-r) value=1 ;;
      *) refuse "date $a, which can set the clock; date takes only its read options, -d, -r, and a +FORMAT operand" ;;
    esac
  done
  [ -z "$value" ] || refuse "date -d or -r without its value"
}

# judge WORD...: one simple command, its assignments first.
judge() {
  [ $# -gt 0 ] || return 0
  envs=""
  while [ $# -gt 0 ]; do
    case "$1" in
      BASE=*) matches "${1#*=}" '^[A-Za-z0-9._/~^-]+$' || refuse "a BASE other than a revision" ;;
      CHANGE=*) matches "${1#*=}" "$CHANGE_NAME" || refuse "a CHANGE other than a change name" ;;
      RECORDS=*) matches "${1#*=}" '^[a-z0-9:. -]*$' || refuse "RECORDS other than KIND:RESULT:COMMIT records" ;;
      GIT_CONFIG_GLOBAL=*) [ "${1#*=}" = /dev/null ] || refuse "a GIT_CONFIG_GLOBAL other than /dev/null" ;;
      GIT_CONFIG_NOSYSTEM=*) [ "${1#*=}" = 1 ] || refuse "a GIT_CONFIG_NOSYSTEM other than 1" ;;
      [A-Za-z_]*=*)
        case "${1%%=*}" in
          *[!A-Za-z0-9_]*) break ;;
          *) refuse "an assignment of ${1%%=*} before a command" ;;
        esac ;;
      *) break ;;
    esac
    envs="$envs ${1%%=*}"
    word_rules "$1"
    shift
  done
  [ $# -gt 0 ] || refuse "an assignment without a command"
  body_at=0
  data_at=0
  case "$1" in */*) refuse "a command named by a path: $1" ;; esac
  case "$1:$envs" in
    sh:*|*:) ;;
    git:*) for e in $envs; do case "$e" in GIT_CONFIG_GLOBAL|GIT_CONFIG_NOSYSTEM) ;; *) refuse "an assignment of $e before git" ;; esac; done ;;
    *) refuse "an assignment before $1" ;;
  esac
  case "$1" in
    ls|cat|head|tail|wc|grep|diff|cmp|cut|tr|nl|comm|basename|dirname|realpath|readlink|stat|du|pwd|echo|true) ;;
    date) date_form "$@" ;;
    printf)
      case "${2:-}" in -*) refuse "printf with the option ${2}, since -v assigns a variable whose subscript runs a command" ;; esac ;;
    sort) sort_form "$@" ;;
    uniq) uniq_form "$@" ;;
    find)
      for a in "$@"; do
        case "$a" in -exec|-execdir|-ok|-okdir|-delete|-fprint|-fprint0|-fprintf|-fls) refuse "find $a, which writes or runs a command" ;; esac
      done ;;
    sed)
      [ $# -ge 3 ] && [ "$2" = -n ] && matches "$3" '^([0-9]+|[$])(,([0-9]+|[$]))?p$' ||
        refuse "sed other than sed -n with a line-number print script"
      shift 3
      for a in "$@"; do case "$a" in -*) refuse "the sed option $a" ;; esac; done ;;
    cd)
      [ $# -eq 2 ] && project_or_worktree "$2" || refuse "cd other than to the project or a worktree tmp/.NAME: ${2:-}"
      case "$2" in
        "$project"|"$project_real") cd_worktree="" ;;
        .) ;;
        *) cd_worktree=$2 ;;
      esac ;;
    git) git_form "$@" ;;
    make) make_form "$@" ;;
    sh) script_form "$@" ;;
    mkdir|rm)
      [ "$profile" != merger ] || refuse "$1 is not a command of this profile"
      files_form "$@" ;;
    cp|mv|touch|chmod)
      only_profiles contributor "$1"
      files_form "$@" ;;
    openspec)
      only_profiles contributor openspec ;;
    npx)
      only_profiles contributor npx
      pkg=${2:-}
      case "$pkg" in -y|--yes) pkg=${3:-} ;; esac
      case "$pkg" in @fission-ai/openspec@2.1.1) ;; *) refuse "npx of other than the Makefile's OPENSPEC_PACKAGE" ;; esac ;;
    *) refuse "$1 is not a command of this profile" ;;
  esac
  i=0
  for w in "$@"; do
    i=$((i + 1))
    [ $i -eq $body_at ] || [ $i -eq $data_at ] || word_rules "$w"
  done
}

# redirect KIND TARGET
redirect() {
  word_rules "$2"
  case "$1" in
    r) ;;
    d) matches "$2" '^([0-9]+|-)$' || write_target "$2" redirect ;;
    *) write_target "$2" redirect ;;
  esac
}

# Repository configuration keys that run a command or redirect origin or
# the files git reads: a copy of RISKY_CONFIG in tools/rules.sh, which this
# script, read from main as a string, cannot source (a tools/tools_test.sh
# case keeps the two equal). While the project's .git/config sets one,
# which branch code run by the checks can write, every call is refused, so
# no git command an agent runs starts a command the branch chose.
RISKY_CONFIG='^(core\.(fsmonitor|hookspath|sshcommand|gitproxy|pager|editor|askpass|alternaterefscommand|worktree)|diff\.external|diff\..+\.(textconv|command)|filter\..+|merge\..+\.driver|sequence\.editor|credential\..+|gpg\..+|uploadpack\..+|url\..+\.(insteadof|pushinsteadof)|remote\.origin\.(pushurl|uploadpack|receivepack|proxy|vcs)|http\..+|protocol\..+|include\..+|includeif\..+|extensions\.worktreeconfig)$'
# The guard's git reads no global or system configuration, which branch
# code can write too (a global insteadOf would answer for a fake origin).
GIT_CONFIG_GLOBAL=/dev/null
GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL GIT_CONFIG_NOSYSTEM
project_dir=${CLAUDE_PROJECT_DIR:-.}
git_common=$(git -C "$project_dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
risky=$(git -C "$project_dir" config --local --name-only --list 2>/dev/null | grep -i -E "$RISKY_CONFIG" | sort -u | tr '\n' ' ')
[ -z "$risky" ] || refuse "every call while the repository configuration sets ${risky% }, which runs a command or redirects origin"
# A fetch refspec other than a clone's maps another ref onto origin/main,
# whose guard the hooks and whose gates the merge read: every call is
# refused while one is set, before any fetch can use it.
fetch_spec=$(git -C "$project_dir" config --local --get-all remote.origin.fetch 2>/dev/null)
[ -z "$fetch_spec" ] || [ "$fetch_spec" = "$DEFAULT_FETCH" ] ||
  refuse "every call while remote.origin.fetch is \"$(printf '%s' "$fetch_spec" | tr '\n' ' ')\", not $DEFAULT_FETCH; restore it with git config"
# A hook in the hooks directory runs on a checkout, a fetch, or a commit
# as surely as a configured one: while one other than a sample is in the
# common git directory's hooks folder, every call is refused (any
# core.hooksPath is refused above).
hooks=${git_common:+$git_common/hooks}
planted=$([ -z "$hooks" ] || ! [ -d "$hooks" ] || ls -A "$hooks" | grep -v -E "[.]sample\$" | tr "\n" " "; true)
[ -z "$planted" ] || refuse "every call while the hooks directory holds ${planted% }, which git runs; remove it"
# A local settings file at the top of the project (LOCAL_FILES), which no
# profile writes, may still come from a copy into the project or from
# outside: while one stands untracked, out of every reviewed diff, every
# call is refused. A tracked one is the reviews'.
for f in $LOCAL_FILES; do
  if { [ -e "$project_dir/$f" ] || [ -L "$project_dir/$f" ]; } &&
    ! git -C "$project_dir" ls-files --error-unmatch -- "$f" > /dev/null 2>&1; then
    refuse "every call while the untracked $f stands at the top of the project, which Claude Code reads as its settings, servers, or instructions and which can turn the hooks off; remove it"
  fi
done

# The merge tool, for the merger only: a squash whose expected head
# (expectedHeadSha, the parameter GitHub refuses any other head by,
# all 40 digits) exactly one run state under build/pipeline/ names, holding
# it both as pushed and as gated, which only main's merge gates write when
# every gate passed and every push clears, while origin/main is the main
# origin reports. The change's own run state names its pushed head, so a
# run state branch code planted to name that head too makes two and is
# refused; the merge gates also reset every run state's gated first.
merge_tool() {
  only_profiles merger "the merge tool"
  [ "$(printf '%s' "$input" | field merge_method)" = squash ] || refuse "a merge other than a squash"
  sha=$(printf '%s' "$input" | field expectedHeadSha)
  matches "$sha" '^[0-9a-f]{40}$' || refuse "a merge without the pushed head as its expected head (expectedHeadSha, 40 digits)"
  naming=$(grep -s -l -F "$sha" "$project_dir"/build/pipeline/*.json | wc -l | tr -d ' ')
  [ "$naming" -le 1 ] || refuse "a merge of $sha, which $naming run states name: remove the one the change did not write"
  found=""
  for f in "$project_dir"/build/pipeline/*.json; do
    [ -f "$f" ] && [ ! -L "$f" ] || continue
    grep -q -E "^  \"pushed\": \"$sha\",?$" "$f" || continue
    grep -q -E "^  \"gated\": \"$sha\",?\$" "$f" && found=$f
  done
  [ -n "$found" ] || refuse "a merge of $sha, at which no run state records both the push and the merge gates' pass (gated)"
  squash_message
  local_main=$(git -C "$project_dir" rev-parse --verify -q 'origin/main^{commit}')
  remote_main=$(git -C "$project_dir" ls-remote origin refs/heads/main 2>/dev/null | cut -f1)
  [ -n "$remote_main" ] && [ "$local_main" = "$remote_main" ] ||
    refuse "a merge while origin/main is ${local_main:-missing} and origin's main ${remote_main:-unknown}: fetch, or the ref was rewritten"
}

# The squash message (commit_message), which becomes the body of the
# commit on main: exactly the body of the change's archived pr.md at the
# pushed head (its lines after the title and the blank line), one blank
# line, and SQUASH_TRAILER last, trailing blank lines ignored on both
# sides; anything else, a shortened body included, is refused naming the
# first line that differs. The bytes are compared exactly: json_text
# decodes the message whole, every escape included, and only the display
# of a differing line shows a control or non-ASCII byte as "?".
SQUASH_TRAILER='Co-Authored-By: Claude <noreply@anthropic.com>'
# json_text KEY prints the string value of KEY decoded exactly (\uXXXX
# and surrogate pairs as UTF-8, \b \f \n \r \t as their bytes), nothing
# when KEY is absent; fails on a raw control byte, a NUL, a lone
# surrogate, a bad escape, or an unterminated string.
json_text() {
  LC_ALL=C K="$1" awk '
    function hex(h,   v, i, d) {
      v = 0
      for (i = 1; i <= 4; i++) {
        d = index("0123456789abcdef", substr(h, i, 1))
        if (!d) return -1
        v = v * 16 + d - 1
      }
      return v
    }
    function utf8(v) {
      if (v < 128) return sprintf("%c", v)
      if (v < 2048) return sprintf("%c%c", 192 + int(v / 64), 128 + v % 64)
      if (v < 65536) return sprintf("%c%c%c", 224 + int(v / 4096), 128 + int(v / 64) % 64, 128 + v % 64)
      return sprintf("%c%c%c%c", 240 + int(v / 262144), 128 + int(v / 4096) % 64, 128 + int(v / 64) % 64, 128 + v % 64)
    }
    { all = all (NR > 1 ? "\n" : "") $0 }
    END {
      if (!match(all, "\"" ENVIRON["K"] "\"[ \t\n\r]*:[ \t\n\r]*\"")) exit 0
      s = substr(all, RSTART + RLENGTH)
      n = length(s)
      out = ""
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (c == "\"") { printf "%s", out; exit 0 }
        if (c ~ /[\001-\037]/) exit 1
        if (c == "\\") {
          i++
          c = substr(s, i, 1)
          if (c == "n") c = "\n"
          else if (c == "t") c = "\t"
          else if (c == "r") c = "\r"
          else if (c == "b") c = "\b"
          else if (c == "f") c = "\f"
          else if (c == "u") {
            v = hex(tolower(substr(s, i + 1, 4)))
            i += 4
            if (v >= 55296 && v < 56320 && substr(s, i + 1, 2) == "\\u") {
              w = hex(tolower(substr(s, i + 3, 4)))
              if (w >= 56320 && w < 57344) { v = 65536 + (v - 55296) * 1024 + w - 56320; i += 6 }
            }
            if (v <= 0 || (v >= 55296 && v < 57344)) exit 1
            c = utf8(v)
          } else if (c != "\"" && c != "\\" && c != "/") exit 1
        }
        out = out c
      }
      exit 1
    }'
}
squash_message() {
  change=${found##*/}
  change=${change%.json}
  matches "$change" '^[a-z0-9][a-z0-9-]*$' || refuse "a merge for the run state $found, not a change name"
  # The archive's own entries, not every file of every archived change.
  pr_md=""
  for dir in $(git -C "$project_dir" ls-tree --name-only "$sha" -- openspec/changes/archive/ 2>/dev/null |
    grep -x -E "openspec/changes/archive/[0-9]{4}-[0-9]{2}-[0-9]{2}-$change"); do
    [ "$(git -C "$project_dir" cat-file -t "$sha:$dir/pr.md" 2>/dev/null)" = blob ] || continue
    [ -z "$pr_md" ] || refuse "a merge of $sha, which holds no one archived pr.md of $change"
    pr_md=$dir/pr.md
  done
  [ -n "$pr_md" ] || refuse "a merge of $sha, which holds no one archived pr.md of $change"
  # The decoded message goes on a file, never the environment, whose size
  # limit would stop awk from running.
  message_file=$(mktemp "${TMPDIR:-/tmp}/carat-squash.XXXXXX") || refuse "a merge whose message has no temporary file"
  trap 'rm -f "$message_file"' EXIT
  printf '%s' "$input" | json_text commit_message > "$message_file" ||
    refuse "a commit message with a raw control byte, a NUL, a lone surrogate, or a bad escape"
  [ -n "$(tr -d '\n' < "$message_file")" ] || refuse "a merge without a commit message: pass the body of $pr_md, a blank line, and the trailer"
  # The comparison prints "same" only on equality, so an awk that never
  # ran refuses rather than allows.
  differs=$(git -C "$project_dir" show "$sha:$pr_md" | sed '1,2d' |
    LC_ALL=C F="$message_file" T="$SQUASH_TRAILER" awk '
      function cut(s) { gsub(/[\001-\037\177-\377]/, "?", s); return length(s) > 80 ? substr(s, 1, 80) "..." : s }
      { want[++n] = $0 }
      END {
        while (n > 0 && want[n] == "") n--
        want[++n] = ""
        want[++n] = ENVIRON["T"]
        g = 0
        while ((getline line < ENVIRON["F"]) > 0) got[++g] = line
        while (g > 0 && got[g] == "") g--
        for (i = 1; i <= n || i <= g; i++) {
          if (i > g) {
            while (want[i] == "") i++
            printf "the message ends at line %d, before line %d, \"%s\"", g, i, cut(want[i])
            exit
          }
          if (i > n) { printf "the message goes on past the trailer at line %d with \"%s\"", i, cut(got[i]); exit }
          if (got[i] != want[i]) { printf "line %d of the message is \"%s\" where it should be \"%s\"", i, cut(got[i]), cut(want[i]); exit }
        }
        printf "same"
      }')
  [ "$differs" = same ] || refuse "a squash message other than the body of $pr_md, a blank line, and the trailer: ${differs:-the comparison did not run}"
}

input=$(cat)
tool=$(printf '%s' "$input" | field tool_name)
case "$tool" in
  Bash) ;;
  mcp__github__merge_pull_request)
    merge_tool
    exit 0 ;;
  Write|Edit|MultiEdit|NotebookEdit)
    path=$(printf '%s' "$input" | field file_path)
    [ -n "$path" ] || path=$(printf '%s' "$input" | field notebook_path)
    [ -n "$path" ] || refuse "a file edit without a path"
    write_target "$path" file
    exit 0 ;;
  *) refuse "the tool ${tool:-without a name}, which this guard does not judge" ;;
esac

tokens=$(printf '%s' "$input" | field command | lex)
default_ifs=$IFS
IFS='
'
set -f
pending=""
# A cd into a worktree tmp/.NAME, which every later segment of the call
# runs in until a cd back to the project clears it (tools/open_pr.sh
# message refuses it).
cd_worktree=""
set --
for t in $tokens; do
  IFS=$default_ifs
  case "$t" in
    E*) refuse "${t#E}" ;;
    W*)
      if [ -n "$pending" ]; then
        redirect "$pending" "${t#W}"
        pending=""
      else
        set -- "$@" "${t#W}"
      fi ;;
    R*) [ -z "$pending" ] || refuse "a redirection without a target"; pending=${t#R} ;;
    O*) [ -z "$pending" ] || refuse "a redirection without a target"; judge "$@"; set -- ;;
  esac
done
IFS=$default_ifs
[ -z "$pending" ] || refuse "a redirection without a target"
judge "$@"
exit 0
