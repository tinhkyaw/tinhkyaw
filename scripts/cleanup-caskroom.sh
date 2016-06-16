#!/usr/bin/env bash
p='/usr/local/Caskroom';
echo 'Begin Caskroom cleanup...';
for d in $(ls $p);
do
  a="$p/$d";
  n=$(ls -t $a/.metadata | wc -l);
  if [ $n -gt 1 ];
  then
    i=0;
    for sd in $(ls -t $a/.metadata);
    do
      if [ $i -gt 0 ];
      then
        b="$a/.metadata/$sd"
        echo "removing $b"
        rm -rf $b
        c="$a/$sd"
        echo "removing $c"
        rm -rf $c
      fi
      (( i++ ));
    done
  fi
done
echo 'Caskroom cleanup completed...';
