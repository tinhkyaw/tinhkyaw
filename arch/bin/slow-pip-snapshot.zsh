#!/usr/bin/env zsh
PIPS_TO_IGNORE="\
jupyter|\
pygobject|\
pyqt|\
qscintilla|\
fuzzytm|\
gensim|\
smart-open|\
tensorflow\
"
p=$(
  grep -Fvxf \
    <(
      "${HOMEBREW_PREFIX}"/bin/pip3 freeze |
        cut -d '=' -f1 |
        cut -d ' ' -f1 |
        xargs "${HOMEBREW_PREFIX}"/bin/pip3 show |
        grep -i '^requires:' |
        awk -F ': ' '{ print $2 }' |
        tr '[:upper:]' '[:lower:]' |
        tr ',' '\n' |
        gsed -e 's/ //g' |
        awk NF |
        sort -u
    ) \
    <(
      "${HOMEBREW_PREFIX}"/bin/pip3 freeze |
        cut -d '=' -f1 |
        cut -d ' ' -f1 |
        tr '[:upper:]' '[:lower:]' |
        sort -u
    )
)
q=$(
  grep -Fvxf \
    <(brew info --json=v1 --installed |
      jq -r \
        'map(select((.dependencies + .build_dependencies +
         .test_dependencies)[] | contains("python"))) | .[] .name' |
      sort -u) \
    <(echo "$p")
)
d=$(
  echo "$q" |
    xargs "${HOMEBREW_PREFIX}"/bin/pip3 show |
    grep -i '^required-by:' |
    grep -in '^required-by: [a-z]' |
    cut -d ':' -f1 |
    gsed -z 's/\n/d;/g'
)
{
  echo "$q" | gsed -e "$d" |
    grep -Evi ${PIPS_TO_IGNORE}
} | sort -u >pip3s.txt
