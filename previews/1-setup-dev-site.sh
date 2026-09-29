#!/usr/bin/env bash
#
# 1-setup-dev-site.sh -- check that the staging site is set up correctly, and
# print the exact command or DNS record for whatever is missing.
#
#     previews/1-setup-dev-site.sh
#
# Run this once when first setting up previews, and any time the staging site
# misbehaves. It is READ-ONLY: it inspects the remote, GitHub Pages and DNS, and
# then tells you what to do. It never creates a repository, changes DNS, or
# pushes anything, because those are the steps worth doing deliberately.
#
# The checks, in dependency order:
#
#   1. configuration is loaded (DEV_REMOTE / DEV_DOMAIN / DEV_BASE_URL agree)
#   2. the staging repository exists and is reachable
#   3. the staging branch exists on it
#   4. GitHub Pages is enabled and serving that branch
#   5. the custom domain, if any, matches DEV_DOMAIN
#   6. DNS resolves to GitHub Pages
#   7. HTTPS is provisioned and enforced
#
# Requires the `gh` CLI, authenticated (`gh auth status`).
#
# ---------------------------------------------------------------------------

set -uo pipefail   # deliberately NOT -e: this script reports problems rather
                   # than aborting on the first one

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=dev-site-lib.sh
source "$script_dir/dev-site-lib.sh"

problems=0
note()  { printf '  \033[32mok\033[0m    %s\n' "$1"; }
warn()  { printf '  \033[33mnote\033[0m  %s\n' "$1"; }
fail()  { printf '  \033[31mFIX\033[0m   %s\n' "$1"; problems=$((problems + 1)); }

echo ""
echo "Staging site configuration"
echo "  remote:    $DEV_REMOTE"
echo "  branch:    $DEV_BRANCH"
echo "  domain:    ${DEV_DOMAIN:-<none: serving from the github.io address>}"
echo "  base URL:  $DEV_BASE_URL"
echo ""

# ---------------------------------------------------------------------------
# 1. Configuration sanity. The single most common mistake is running the
#    publisher with a stale DEV_* override in the shell, so the committed
#    defaults in dev-site-lib.sh are not the ones actually in effect.
# ---------------------------------------------------------------------------
echo "Configuration"
if [[ -n $DEV_DOMAIN && $DEV_BASE_URL != "https://$DEV_DOMAIN" ]]; then
  fail "DEV_BASE_URL should be https://$DEV_DOMAIN when DEV_DOMAIN is set"
else
  note "DEV_DOMAIN and DEV_BASE_URL agree"
fi

# Derive owner/repo from the remote so the gh calls below can be built.
slug_path="$(printf '%s' "$DEV_REMOTE" | sed -e 's|^https://github.com/||' -e 's|^git@github.com:||' -e 's|\.git$||')"
if [[ $slug_path != */* ]]; then
  fail "cannot parse owner/repo out of DEV_REMOTE ($DEV_REMOTE); skipping GitHub checks"
  echo ""
  exit 1
fi
note "staging repository is $slug_path"

# ---------------------------------------------------------------------------
# 2 + 3. Repository and branch.
# ---------------------------------------------------------------------------
echo ""
echo "Repository"
if ! gh repo view "$slug_path" --json name >/dev/null 2>&1; then
  fail "repository does not exist or is not visible. Create it with:
            gh repo create $slug_path --public"
else
  visibility="$(gh repo view "$slug_path" --json visibility --jq .visibility 2>/dev/null)"
  note "exists (visibility: $visibility)"
  if [[ $visibility != "PUBLIC" ]]; then
    warn "GitHub Pages on a private repository needs a paid plan, and custom
            domains are unavailable there"
  fi

  if gh api "repos/$slug_path/branches/$DEV_BRANCH" >/dev/null 2>&1; then
    note "branch '$DEV_BRANCH' exists"
  else
    fail "branch '$DEV_BRANCH' does not exist yet. It is created by the first
            publish, so just run:
            previews/2-publish-dev.sh <slug>"
  fi
fi

# ---------------------------------------------------------------------------
# 4 + 5 + 7. GitHub Pages: enabled, right branch, right domain, HTTPS.
#
# Pages usually enables itself the moment a gh-pages branch appears, so a 404
# here normally just means nothing has been published yet.
# ---------------------------------------------------------------------------
echo ""
echo "GitHub Pages"
pages_json="$(gh api "repos/$slug_path/pages" 2>/dev/null)"
if [[ -z $pages_json ]]; then
  fail "Pages is not enabled. Publishing once usually enables it automatically;
            to do it by hand:
            printf '{\"source\":{\"branch\":\"$DEV_BRANCH\",\"path\":\"/\"}}' |
              gh api -X POST repos/$slug_path/pages --input -"
else
  read_field() { printf '%s' "$pages_json" | python3 -c "
import json,sys
d = json.load(sys.stdin)
keys = '$1'.split('.')
for k in keys:
    d = (d or {}).get(k) if isinstance(d, dict) else None
print('' if d is None else d)
"; }

  p_branch="$(read_field source.branch)"
  p_path="$(read_field source.path)"
  p_cname="$(read_field cname)"
  p_status="$(read_field status)"
  p_https="$(read_field https_enforced)"
  p_cert="$(read_field https_certificate.state)"

  if [[ $p_branch == "$DEV_BRANCH" && $p_path == "/" ]]; then
    note "serving $p_branch at $p_path (status: $p_status)"
  else
    fail "Pages serves '$p_branch' at '$p_path', expected '$DEV_BRANCH' at '/'.
            Fix in Settings -> Pages, or:
            printf '{\"source\":{\"branch\":\"$DEV_BRANCH\",\"path\":\"/\"}}' |
              gh api -X PUT repos/$slug_path/pages --input -"
  fi

  if [[ -z $DEV_DOMAIN ]]; then
    if [[ -n $p_cname ]]; then
      fail "Pages has custom domain '$p_cname' but DEV_DOMAIN is empty. Either set
            DEV_DOMAIN=$p_cname, or clear the domain in Settings -> Pages."
    else
      note "no custom domain, as configured"
    fi
  elif [[ $p_cname == "$DEV_DOMAIN" ]]; then
    note "custom domain is $p_cname"
  elif [[ -z $p_cname ]]; then
    warn "custom domain not set yet. The next previews/2-publish-dev.sh writes the CNAME
            file, which is what tells Pages to use it."
  else
    fail "Pages custom domain is '$p_cname' but DEV_DOMAIN is '$DEV_DOMAIN'.
            One of the two is wrong -- check for a stale DEV_DOMAIN override."
  fi

  if [[ -n $DEV_DOMAIN ]]; then
    if [[ $p_https == "True" || $p_https == "true" ]]; then
      note "HTTPS enforced (certificate: ${p_cert:-unknown})"
    else
      fail "HTTPS is not enforced. Certificates are issued a few minutes after the
            domain is set; once the certificate state is 'approved', run:
            printf '{\"https_enforced\":true}' |
              gh api -X PUT repos/$slug_path/pages --input -"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 6. DNS. Only meaningful when a custom domain is configured.
#
# GitHub's anycast addresses for apex domains are 185.199.108-111.153. A
# subdomain should be a CNAME to <owner>.github.io instead, because that follows
# GitHub's own redirects; a zone apex cannot be a CNAME at all, which is why the
# apex case needs four A records.
# ---------------------------------------------------------------------------
echo ""
echo "DNS"
if [[ -z $DEV_DOMAIN ]]; then
  note "no custom domain, nothing to resolve"
else
  owner="${slug_path%%/*}"
  # A hostname with two labels (example.org) is an apex; more is a subdomain.
  dots="$(printf '%s' "$DEV_DOMAIN" | tr -cd '.' | wc -c | tr -d ' ')"

  if [[ $dots -le 1 ]]; then
    expected_note="apex domain: four A records to 185.199.108-111.153"
    got="$(dig +short A "$DEV_DOMAIN" | sort | tr '\n' ' ')"
    if [[ $got == *"185.199.108.153"* && $got == *"185.199.111.153"* ]]; then
      note "A records point at GitHub Pages ($got)"
    else
      fail "$expected_note
            currently: ${got:-<nothing>}
            Add at your DNS host, with hostname '@':
              @  A  185.199.108.153
              @  A  185.199.109.153
              @  A  185.199.110.153
              @  A  185.199.111.153"
    fi
  else
    got="$(dig +short CNAME "$DEV_DOMAIN" | tr -d '\n')"
    if [[ $got == "$owner.github.io." || $got == "$owner.github.io" ]]; then
      note "CNAME points at $got"
    else
      fail "subdomain should be a CNAME to $owner.github.io
            currently: ${got:-<nothing>}
            Add at your DNS host:
              ${DEV_DOMAIN%%.*}  CNAME  $owner.github.io."
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Serving check: the end-to-end answer, independent of all the above.
# ---------------------------------------------------------------------------
echo ""
echo "Serving"
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$DEV_BASE_URL/" 2>/dev/null)"
case "$code" in
  200) note "$DEV_BASE_URL/ returns 200" ;;
  301|302) note "$DEV_BASE_URL/ redirects ($code) -- normal if a custom domain was just added" ;;
  404) fail "$DEV_BASE_URL/ returns 404. Nothing published yet, or Pages is serving
            the wrong branch." ;;
  000) fail "$DEV_BASE_URL/ did not respond. Usually DNS not resolving yet, or a
            certificate still being issued." ;;
  *)   fail "$DEV_BASE_URL/ returned HTTP $code" ;;
esac

echo ""
if (( problems == 0 )); then
  echo "All checks passed. Publish a preview with:  previews/2-publish-dev.sh <slug>"
else
  echo "$problems item(s) need attention -- see the FIX lines above."
fi
echo ""
exit $(( problems > 0 ? 1 : 0 ))
