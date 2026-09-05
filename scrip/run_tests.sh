#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

sources=(
  "$project_dir/src/alu.sv"
  "$project_dir/src/branch_comparator.sv"
  "$project_dir/src/control_unit.sv"
  "$project_dir/src/immediate_generator.sv"
  "$project_dir/src/load_formatter.sv"
  "$project_dir/src/next_instruction_incrementor.sv"
  "$project_dir/src/program_counter.sv"
  "$project_dir/src/register_file.sv"
  "$project_dir/src/store_formatter.sv"
  "$project_dir/src/risc_core.sv"
)

tests=(alu branch_comparator immediate_generator program_counter register_file next_instruction_incrementor load_formatter store_formatter control_unit risc_core)

for name in "${tests[@]}"; do
  iverilog -g2012 -s "tb_${name}" -o "$build_dir/$name.vvp" "${sources[@]}" "$project_dir/tests/tb_${name}.sv"
  vvp "$build_dir/$name.vvp"
done

echo "PASS: all RV32I CPU testbenches"
