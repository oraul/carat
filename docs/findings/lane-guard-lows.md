### Two lanes share one writable toolchain and compile cache (closed with a reason)
- Location: tools/run_state.sh LANE_LINKS (tmp/.spinel, tmp/.toolchain, build/spinel-cache)
- Why: a lane's check can write the one toolchain the other lane builds with; disputed, because one shared toolchain and cache is the design of the lanes (parallel-lanes-b) and only lane-open makes the links; the part that was steerable by the branch (a tracked or committed link at those paths) is refused in this change.
- Fix: none now; a per-lane toolchain copy would double the install and the compile cache, so the sharing stays unless a lane's write to it is ever shown.
none
