#!/usr/bin/env bash
p="/usr/local/Caskroom"
echo -e "\e[94mBegin Caskroom cleanup...\e[39m"
for d in $(ls $p)
do
  a="$p/$d"
  n=$(ls -t $a/.metadata | wc -l)
  if [ $n -gt 1 ]
  then
    i=0
    for sd in $(ls -t $a/.metadata)
    do
      if [ $i -gt 0 ]
      then
        b="$a/.metadata/$sd"
        echo -e "\e[91mRemoving \e[94m$b\e[39m"
        rm -rf $b
        c="$a/$sd"
        echo -e "\e[91mRemoving \e[94m$c\e[39m"
        rm -rf $c
      fi
      (( i++ ))
    done
  fi
done
echo -e "\e[94mCaskroom cleanup completed...\e[39m"
