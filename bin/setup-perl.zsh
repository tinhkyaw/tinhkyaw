#!/usr/bin/env zsh
# =============================================================================
# setup-perl.zsh — Install cpanminus and required CPAN modules
# =============================================================================
#
# Usage:
#   setup-perl.zsh
#
# Description:
#   Bootstraps cpanminus via cpanmin.us into the Homebrew Perl installation,
#   installs a curated set of CPAN modules, then ensures all expected
#   site_perl / vendor_perl directory trees exist (some are missing by
#   default and cause warnings in downstream tools).
#
# Dependencies:
#   curl, perl (via HOMEBREW_PREFIX/opt/perl), gsed
#
# Environment:
#   HOMEBREW_PREFIX   Set by Homebrew (required for Perl path resolution)
# =============================================================================

setopt ERR_EXIT PIPE_FAIL NO_UNSET

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Verify that the given commands are available.
#
# Arguments:
#   1+  Command names to check (e.g. curl perl gsed)
check_deps() {
    local missing=()
    for cmd in "$@"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if (( ${#missing} > 0 )); then
        echo "Error: missing required dependencies: ${missing[*]}" >&2
        echo "Install with: brew install ${missing[*]}" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------

check_deps curl gsed

readonly PERL="${HOMEBREW_PREFIX}/opt/perl/bin/perl"
readonly CPANM="${HOMEBREW_PREFIX}/opt/perl/bin/cpanm"

if [[ ! -x "${PERL}" ]]; then
  echo "Error: Homebrew Perl not found at ${PERL}" >&2
  echo "Install with: brew install perl" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# cpanminus
# ---------------------------------------------------------------------------

# Bootstrap cpanminus from cpanmin.us into the Homebrew Perl prefix.
# -fsSL: fail on error, silent, follow redirects.
curl -fsSL https://cpanmin.us | "${PERL}" - App::cpanminus

# ---------------------------------------------------------------------------
# CPAN modules
# ---------------------------------------------------------------------------

"${CPANM}" \
  App::cpanoutdated \
  File::HomeDir \
  Log::Log4perl \
  Term::ReadLine::Perl \
  YAML::Tiny

# ---------------------------------------------------------------------------
# Ensure site_perl / vendor_perl directories exist
# ---------------------------------------------------------------------------

# Some Perl tooling emits warnings (or fails) when expected lib directories
# are absent. Create them and add an empty .gitignore so they are not
# accidentally committed if this repo is inside HOMEBREW_PREFIX.
for sp in site vendor; do
  while IFS= read -r md; do
    if [[ ! -d "${md}" ]]; then
      print -P "%F{yellow}Warning:%f Creating missing Perl dir: ${md}"
      mkdir -p "${md}"
      touch "${md}/.gitignore"
    fi
  done < <(
    perl -V \
      | grep -E "^[[:space:]]+${HOMEBREW_PREFIX}/lib/perl5/${sp}_perl/" \
      | gsed -e 's/[[:space:]]//g'
  )
done
