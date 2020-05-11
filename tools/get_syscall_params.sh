#!/bin/bash

set -euo pipefail

if [[ "${#}" -ne 1 ]]; then
    echo 'expected a name of an output file'
    exit 1
fi

# redirect stdout to the file
exec >"${1}"

echo "// Code generated by $(basename ${0}) ${*}; DO NOT EDIT"
echo
echo 'package straceback'
echo
echo 'func gatherSyscallsStatic() error {'
echo -e '\tcSyscalls = make(map[string]Syscall)'
echo
echo -e '\tvar err error'
echo -e '\tvar name string'
echo -e '\tvar cSyscall *Syscall'
echo
sudo find /sys/kernel/debug/tracing/events/syscalls/ -name 'sys_enter_*' -type d | \
cut --characters=53- | \
while read name ; do
  echo -e "\tname = relateSyscallName(\"${name}\")"
  echo -en "\tcSyscall, err = parseSyscall(name, string(\`"
  # filter out the ID line, it seems to differ from kernel version to
  # kernel version, and we don't care about IDs when parsing params
  sudo cat "/sys/kernel/debug/tracing/events/syscalls/sys_enter_${name}/format" | grep -v '^ID'
  echo "\`))"
  echo -e "\tif err != nil {"
  echo -e "\t\treturn err"
  echo -e "\t}"
  echo -e "\tcSyscalls[name] = *cSyscall"
done
echo -e '\treturn nil'
echo '}'