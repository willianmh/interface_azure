#!/bin/bash

SMALL=1

# compile_bench(bench, nprocs, class)
compile_bench() {
  local bench="${1}"
  local nprocs="${2}"
  local class="${3}"

  make -j2 "${bench}" NPROCS="${nprocs}" CLASS="${class}"
}
if [[ ${SMALL} ]]; then
	for class in S; do
		compile_bench lu 16 "${class}"
		compile_bench sp 16 "${class}"
		compile_bench sp 16 "${class}"
		compile_bench bt 16 "${class}"
		compile_bench bt 16 "${class}"
	done
else
	for class in A B C D; do
		compile_bench lu 32 "${class}"
		compile_bench sp 25 "${class}"
		compile_bench sp 36 "${class}"
		compile_bench bt 25 "${class}"
		compile_bench bt 36 "${class}"
	done
fi
