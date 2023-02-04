#!/usr/bin/env zsh
curl -L https://cpanmin.us |
  "${HOMEBREW_PREFIX}"/opt/perl/bin/perl - App::cpanminus
"${HOMEBREW_PREFIX}"/opt/perl/bin/cpanm \
  App::cpanoutdated File::HomeDir \
  Log::Log4perl \
  Term::ReadLine::Perl
md=$(perl -V | grep -E "^[ ]*${HOMEBREW_PREFIX}/lib/perl5/site_perl/" | gsed -e 's/ //g')
if [[ ! -d "${md}" ]]; then
  print -P "%F{yellow}Warning:%f Creating the missing dir: ${md}"
  mkdir -p "$md"
  touch "$md/.gitignore"
fi
