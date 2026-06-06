#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  Tools/setup-branch-protection.sh [--repo owner/name] [--branch main] [--apply]

Default mode is dry-run (prints the payload and gh api command).
Use --apply to actually update branch protection via GitHub API.

Requirements:
  - gh CLI authenticated as a repo admin (gh auth status)
  - Repository admin permission for the target repo

This script configures:
  - Require a pull request before merging
  - Require status checks:
      * Swift packages (build + test)
      * iOS app (xcodebuild)
  - Require branches to be up to date before merging (strict=true)
  - Disable force pushes
  - Enable linear history
EOF
}

repo_from_git() {
  local remote
  remote="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -z "${remote}" ]]; then
    return 1
  fi

  if [[ "${remote}" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    printf '%s/%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return 0
  fi

  return 1
}

REPO=""
BRANCH="main"
APPLY="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --branch)
      BRANCH="${2:-}"
      shift 2
      ;;
    --apply)
      APPLY="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "${REPO}" ]]; then
  REPO="$(repo_from_git || true)"
fi

if [[ -z "${REPO}" ]]; then
  echo "Error: Could not infer repository. Pass --repo owner/name." >&2
  exit 1
fi

OWNER="${REPO%/*}"
NAME="${REPO#*/}"

if [[ -z "${OWNER}" || -z "${NAME}" || "${OWNER}" == "${NAME}" ]]; then
  echo "Error: Invalid --repo value '${REPO}'. Expected owner/name." >&2
  exit 1
fi

PAYLOAD="$(cat <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "Swift packages (build + test)",
      "iOS app (xcodebuild)"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0
  },
  "restrictions": null,
  "allow_force_pushes": { "enabled": false },
  "required_linear_history": { "enabled": true }
}
EOF
)"

echo "Target repository: ${OWNER}/${NAME}"
echo "Target branch: ${BRANCH}"
echo
echo "Branch protection payload:"
echo "${PAYLOAD}"
echo

if [[ "${APPLY}" != "true" ]]; then
  echo "Dry-run only. To apply, re-run with --apply."
  echo
  echo "Command that will be executed:"
  echo "gh api --method PUT repos/${OWNER}/${NAME}/branches/${BRANCH}/protection --input -"
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI not found. Install GitHub CLI first." >&2
  exit 1
fi

echo "${PAYLOAD}" | gh api \
  --method PUT \
  "repos/${OWNER}/${NAME}/branches/${BRANCH}/protection" \
  --input -

echo
echo "Done. Branch protection was updated."
