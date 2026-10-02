#!/bin/sh
# usage: ge-share-precheck.sh AUDIENCE_GROUP_EMAIL MEMBER_EMAIL...  (setup 20 GG-4.5; X-GE-22)
set -eu
. "$HOME/.platform-env"; . "$BUILD_LOG_DIR/ge-baseline/ge-helpers.sh"
ge_call GET "https://eu-discoveryengine.googleapis.com/v1/projects/${GEMINI_PROJECT}/locations/eu/collections/default_collection/engines/${GEMINI_APP_ID}:getIamPolicy" | jq -e --arg g "group:${GRP_GE_USERS}" '[.bindings[] | select(.role=="roles/discoveryengine.agentspaceUser") | .members[]] | index($g) != null' >/dev/null || { echo "FAIL ge-users@ not bound at app level"; exit 1; }
shift; rc=0
for m in "$@"; do r="$(gcloud identity groups memberships check-transitive-membership --group-email="$GRP_GE_USERS" --member-email="$m" --format='value(hasMembership)')"; echo "$m $r"; [ "$r" = True ] || rc=1; done
exit $rc
