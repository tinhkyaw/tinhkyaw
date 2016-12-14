#!/usr/bin/env zsh
p="/usr/local/Caskroom"
print -P "%F{blue}Begin Caskroom cleanup...%f"
for d in $(ls ${p})
do
  a="${p}/${d}"
  n=$(ls -t ${a}/.metadata | wc -l)
  if [ ${n} -gt 1 ]
  then
    i=0
    for sd in $(ls -t ${a}/.metadata)
    do
      if [ ${i} -gt 0 ]
      then
        b="${a}/.metadata/${sd}"
        print -P "%F{red}Removing %F{cyan}${b}%f"
        rm -rf ${b}
        c="${a}/${sd}"
        print -P "%F{red}Removing %F{cyan}${c}%f"
        rm -rf ${c}
      fi
      (( i++ ))
    done
  fi
done
print -P "%F{blue}Caskroom cleanup completed...%f"
