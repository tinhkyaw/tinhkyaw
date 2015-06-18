#!/usr/bin/env bash
p='/opt/homebrew-cask/Caskroom'
for d in $(ls $p)
do
    a="$p/$d"
    n=$(ls -t $a | wc -l)
    if [ $n -gt 1 ]
    then
        i=0
        for sd in $(ls -t $a)
        do
            if [ $i -gt 0 ]
            then
                b="$a/$sd"
                echo "removing $b"
                rm -rf $b
            fi
            (( i++ ))
        done
    else
        sd=$(ls -t $a)
        echo "$a/$sd clean"
    fi
done
