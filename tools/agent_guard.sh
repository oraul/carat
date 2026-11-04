#!/bin/sh
# The guard of the delivery agents: an allowlist of the commands each
# agent needs. A PreToolUse hook in the frontmatter of each agent under
# .claude/agents/ runs the copy on origin/main with the agent's profile and
# the tool call's JSON on stdin, and refuses the call on any status but 0;
# the guard exits 2 with the reason on stderr to refuse and 0 to allow.
#
# Usage: sh tools/agent_guard.sh PROFILE [DIR] < HOOK-JSON
#
# A Bash command is read as the shell reads it: words with their quotes
# and escapes removed, operators (; && || | &), and redirections. Refused
# outright, since the guard cannot know what they run: $ in any form
# (variables, substitutions, ANSI-C quoting), backquotes, parentheses,
# here-documents, unquoted * ? [ ] { }, a leading ~, a command named by a
# path, and an assignment before a command other than BASE, CHANGE, and
# RECORDS before tools/gates.sh. Every simple command must then match a
# form of its profile; every word is refused with a parent step (..) as a
# path segment or naming the run state's directory build/pipeline, but the
# pull request body file build/pipeline/NAME.body.md as the body gate's
# argument, never a link.
#
# Forms of every profile: ls cat head tail wc grep diff cmp sort (no -o,
# --output, --compress-program) uniq (one file at most) cut tr nl comm
# basename dirname realpath readlink stat du date pwd echo printf true;
# find without -exec -execdir -ok -okdir -delete -fprint -fprint0 -fprintf
# -fls; sed -n with a line-number print script; cd to the project or a
# worktree tmp/.NAME; git with the global options -C PATH and --no-pager
# and the verbs status log show diff rev-parse merge-base ls-files ls-tree
# cat-file blame describe shortlog rev-list grep show-ref for-each-ref
# name-rev (none with --output, --ext-diff, --textconv, --filters,
# --upload-pack, --receive-pack, --exec, or grep's -O), branch with listing
# options, remote -v, remote get-url origin, remote set-head origin main,
# fetch -q --prune origin, ls-remote with listing options, worktree add,
# remove, list, and prune of a worktree tmp/.NAME, and checkout -q --detach
# origin/main inside one (-C).
#   read         adds mkdir and rm under DIR; make -s, -C tmp/.NAME, the
#                targets dev-build test-build bench-budget metrics
#                metrics-compare bench, and PREFIX and SPINEL_CACHE_DIR at
#                the project's tmp/.toolchain and build/spinel-cache,
#                BASE_METRICS, SCENARIOS; sh tools/run_state.sh show status
#                pending get trusted check bench metrics metric note budget
#                review-due; [BASE=REV] sh tools/gates.sh GATE...; sh
#                tools/metrics.sh measure|compare
#   merger       adds sh tools/run_state.sh show status get trusted metric,
#                set CHANGE ci "red|green HEX", set CHANGE merged HEX;
#                CHANGE=NAME RECORDS=... sh tools/gates.sh merge BODY; sh
#                tools/ci_wait.sh N; git push origin --delete BRANCH, git
#                checkout -q main, git merge -q --ff-only origin/main, git
#                branch -D BRANCH, BRANCH a Conventional Branch
#   contributor  adds git -c user.name=X -c user.email=Y, git add commit mv
#                rm restore, git merge origin/main; make -s -k TARGET with
#                the variables of MAKE_VARS, no shell character in a value;
#                openspec and npx @fission-ai/openspec@latest; mkdir rm cp
#                mv touch chmod; sh tools/run_state.sh show status pending
#                get budget history, push CHANGE [--ci-fix], set CHANGE pr
#                N; sh tools/gates.sh GATE... or pr-body BODY
# Any other profile refuses every call.
#
# A write target (a redirection's target, a path argument of mkdir rm cp
# mv touch chmod, a file tool's path) has no parent step, and its real
# path, links followed, lies in the project, outside .git/ and the run
# state's directory; for read and merger it lies under the real path of
# DIR, a redirection also under build/stages/, and an agent without DIR
# edits no file. The contributor's file tools may write the body file
# itself, never through a link. A link target whose parent step follows a
# missing directory is refused, since the write resolves it lexically.
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

refuse() {
  echo "agent_guard: refused for the $profile profile: $*. Each profile runs only the commands its agent needs, listed in tools/agent_guard.sh: search with the Grep or Read tool, put text that names a refused form into a file with the Write tool, and push only through tools/run_state.sh push." >&2
  exit 2
}

case "$profile" in read|merger|contributor) ;; *) refuse "no such profile" ;; esac

# The first JSON string field KEY of the input with its escapes undone; an
# escaped newline becomes ";", so each line reads as a command of its own,
# but a newline after an odd run of backslashes is a line continuation the
# shell joins, so the pair is dropped: 'git \<newline>push' is git push.
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
          if (c == "n") {
            run = 0
            while (run < length(out) && substr(out, length(out) - run, 1) == "\\") run++
            if (run % 2 == 1) { out = substr(out, 1, length(out) - 1); continue }
            c = ";"
          }
          else if (c == "t" || c == "r") c = " "
          else if (c == "u") { i += 4; c = "?" }
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
# before the redirection's target word, or E and the reason to refuse.
lex() {
  awk '
    function fail(why) { print "E" why; exit }
    function flush() { if (inw) print "W" w; w = ""; inw = 0 }
    {
      s = $0; n = length(s); w = ""; inw = 0; q = ""
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q == "\047") { if (c == "\047") q = ""; else w = w c; continue }
        if (q == "\"") {
          if (c == "\"") { q = ""; continue }
          if (c == "$" || c == "`") fail("a $ expansion or a command substitution inside double quotes")
          if (c == "\\" && i < n && index("\"\\$`", substr(s, i + 1, 1))) { i++; w = w substr(s, i, 1); continue }
          w = w c
          continue
        }
        if (c == "\047" || c == "\"") { q = c; inw = 1; continue }
        if (c == "\\") { if (i < n) { i++; w = w substr(s, i, 1) }; inw = 1; continue }
        if (c == "$") fail("a $ expansion: a variable, a substitution, or ANSI-C quoting")
        if (c == "`") fail("a command substitution")
        if (c == "(" || c == ")") fail("a subshell, a group, or a process substitution")
        if (index("*?[]{}", c)) fail("an unquoted glob or brace character " c)
        if (c == "~" && !inw) fail("a ~ expansion")
        if (c == "#" && !inw) { while (i < n && substr(s, i + 1, 1) != ";") i++; continue }
        if (c == " ") { flush(); continue }
        if (c == ";") { flush(); print "O;"; continue }
        d = substr(s, i + 1, 1)
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
          if (inw && w ~ /^[0-9]+$/) { w = ""; inw = 0 } else flush()
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
  while :; do case "$real" in ?*/) real=${real%/} ;; *) break ;; esac; done
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

# write_target PATH KIND: KIND is redirect, command, or file.
write_target() {
  [ "$2" = file ] || [ "$1" != /dev/null ] || return 0
  parent_step "$1"
  relative "$1"
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
  case "/$rel/" in */.git/*) refuse "a write under .git, whose hooks and configuration run commands: $1" ;; esac
  case "$rel" in
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

# worktree PATH: PATH is a worktree tmp/.NAME of the project.
worktree() {
  relative "$1"
  matches "$rel" '^tmp/[.][A-Za-z0-9_-]+$' || return 1
  case "$rel" in tmp/.toolchain|tmp/.spinel) return 1 ;; esac
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
      -C) [ $# -ge 2 ] || refuse "git -C without a path"; wt=$2; shift 2 ;;
      -c)
        [ $# -ge 2 ] || refuse "git -c without a value"
        case "$profile:$2" in
          contributor:user.name=*|contributor:user.email=*) ;;
          *) refuse "a git configuration override: -c $2" ;;
        esac
        shift 2 ;;
      --no-pager|-P) shift ;;
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
          --output*|--ext-diff|--textconv|--filters|--upload-pack*|--receive-pack*|--exec*)
            refuse "git $verb $a, which writes or runs a command" ;;
          -O*|--open-files-in-pager*)
            [ "$verb" != grep ] || refuse "git grep $a, which runs a command" ;;
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
      options_in "-q --quiet --prune -p origin" "$@" || refuse "git fetch other than of origin without a refspec" ;;
    ls-remote)
      for a in "$@"; do
        case "$a" in
          --heads|--tags|-h|-t|-q|--quiet|--exit-code|--refs|origin) ;;
          -*) refuse "git ls-remote $a" ;;
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
                if [ $paths -eq 1 ]; then worktree "$a" || refuse "a worktree outside tmp/.NAME: $a"
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
              *) paths=$((paths + 1)); worktree "$a" || refuse "a worktree outside tmp/.NAME: $a" ;;
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
    push)
      only_profiles merger "git push"
      [ $# -eq 3 ] && [ "$1" = origin ] && [ "$2" = --delete ] && matches "$3" "$BRANCH" ||
        refuse "git push other than the deletion of a Conventional Branch" ;;
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
  only_profiles "read contributor" make
  shift
  while [ $# -gt 0 ]; do
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
    read:show|read:status|read:pending|read:get|read:trusted|read:check|read:bench|read:metrics|read:metric|read:note|read:budget|read:review-due) ;;
    merger:show|merger:status|merger:get|merger:trusted|merger:metric) ;;
    contributor:show|contributor:status|contributor:pending|contributor:get|contributor:budget|contributor:history) ;;
    contributor:push)
      [ $# -ge 2 ] && [ $# -le 3 ] && matches "$2" "$CHANGE_NAME" && { [ $# -eq 2 ] || [ "$3" = --ci-fix ]; } ||
        refuse "tools/run_state.sh push other than CHANGE [--ci-fix]" ;;
    merger:set|contributor:set)
      [ $# -eq 4 ] && matches "$2" "$CHANGE_NAME" || refuse "tools/run_state.sh set other than CHANGE KEY VALUE"
      case "$profile:$3" in
        merger:ci) matches "$4" '^(red|green) [0-9a-f]{7,40}$' || refuse "a CI record other than red or green and a commit" ;;
        merger:merged) matches "$4" '^[0-9a-f]{7,40}$' || refuse "a merged record other than a commit" ;;
        contributor:pr) matches "$4" '^[0-9]+$' || refuse "a pull request record other than a number" ;;
        *) refuse "tools/run_state.sh set of $3" ;;
      esac ;;
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

script_form() {
  [ $# -ge 2 ] || refuse "sh without a script"
  case "$2" in -*) refuse "a shell option: sh $2" ;; esac
  relative "$2"
  script=$rel
  [ -z "$envs" ] || [ "$script" = tools/gates.sh ] || refuse "an assignment before $2"
  shift 2
  case "$script" in
    tools/run_state.sh) run_state_form "$@" ;;
    tools/gates.sh) gates_form "$@" ;;
    tools/metrics.sh)
      only_profiles read "tools/metrics.sh"
      case "${1:-}" in measure|compare) ;; *) refuse "tools/metrics.sh other than measure or compare" ;; esac ;;
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

# judge WORD...: one simple command, its assignments first.
judge() {
  [ $# -gt 0 ] || return 0
  envs=""
  while [ $# -gt 0 ]; do
    case "$1" in
      BASE=*) matches "${1#*=}" '^[A-Za-z0-9._/~^-]+$' || refuse "a BASE other than a revision" ;;
      CHANGE=*) matches "${1#*=}" "$CHANGE_NAME" || refuse "a CHANGE other than a change name" ;;
      RECORDS=*) matches "${1#*=}" '^[a-z0-9:. -]*$' || refuse "RECORDS other than KIND:RESULT:COMMIT records" ;;
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
  case "$1" in */*) refuse "a command named by a path: $1" ;; esac
  [ -z "$envs" ] || [ "$1" = sh ] || refuse "an assignment before $1"
  case "$1" in
    ls|cat|head|tail|wc|grep|diff|cmp|cut|tr|nl|comm|basename|dirname|realpath|readlink|stat|du|date|pwd|echo|printf|true) ;;
    sort)
      for a in "$@"; do
        case "$a" in -o*|--output*|--compress-program*) refuse "sort $a, which writes or runs a command" ;; esac
      done ;;
    uniq)
      n=0
      for a in "$@"; do case "$a" in -*) ;; *) n=$((n + 1)) ;; esac; done
      [ $n -le 2 ] || refuse "uniq with an output file" ;;
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
      [ $# -eq 2 ] || refuse "cd other than to the project or a worktree tmp/.NAME"
      case "$2" in
        "$project"|"$project_real"|.) ;;
        *) worktree "$2" || refuse "cd other than to the project or a worktree tmp/.NAME: $2" ;;
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
      case "$pkg" in @fission-ai/openspec|@fission-ai/openspec@latest) ;; *) refuse "npx of other than @fission-ai/openspec" ;; esac ;;
    *) refuse "$1 is not a command of this profile" ;;
  esac
  i=0
  for w in "$@"; do
    i=$((i + 1))
    [ $i -eq $body_at ] || word_rules "$w"
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

input=$(cat)
tool=$(printf '%s' "$input" | field tool_name)
case "$tool" in
  Bash) ;;
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
