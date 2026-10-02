# Source after ~/.platform-env. PAM grant helpers for the one-grant test (setup/12 PA-1.5).
pam_request() { # ENTITLEMENT_NAME JUSTIFICATION [DURATION_S]: prints the grant name
  gcloud pam grants create --entitlement="$1" --requested-duration="${3:-1800}s" --justification="$2" --billing-project="$CICD_PROJECT" --format="value(name)"
}
pam_state() { gcloud pam grants describe "$1" --billing-project="$CICD_PROJECT" --format="value(state)"; }
pam_wait() { # GRANT STATE [TIMEOUT_S]: polls every 20 s, printing the state each time.
  # Default ceiling 86400 s: a grant request expires within 24 hours (approve-grants page), and T2 is a
  # human approval in the console, so a wait of minutes or hours is normal and is not a failure.
  # Returns 0 reached, 2 a terminal state that is not the one asked for, 3 timed out (the grant may still be live:
  # run pam_state, and pam_revoke it if it is not the state you wanted. Never re-request on a 3).
  end=$(( $(date +%s) + ${3:-86400} )); s=""
  while :; do
    s="$(pam_state "$1")"
    [ "$s" = "$2" ] && { echo "STATE $2"; return 0; }
    case "$s" in
      DENIED|REVOKED|ENDED|EXPIRED) echo "STATE $s (terminal, not $2)"; return 2;;
    esac
    [ "$(date +%s)" -ge "$end" ] && { echo "TIMEOUT waiting for $2; last state $s; run pam_state and, if it is not $2, pam_revoke"; return 3; }
    echo "waiting for $2: state $s"
    sleep 20
  done
}
tip() { # RESOURCE_PATH '"perm","perm"': Resource Manager testIamPermissions. Prints the permissions the caller holds.
  # The access token is consumed inline: it is never assigned to a variable, printed or written to disk.
  curl -sS -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "x-goog-user-project: $CICD_PROJECT" -H "Content-Type: application/json" -d "{\"permissions\":[$2]}" "https://cloudresourcemanager.googleapis.com/v3/$1:testIamPermissions"
}
pam_policy() { # organizations|folders|projects ID OUTFILE
  case "$1" in
    organizations) gcloud organizations get-iam-policy "$2" --format=json > "$3";;
    folders) gcloud resource-manager folders get-iam-policy "$2" --format=json > "$3";;
    projects) gcloud projects get-iam-policy "$2" --format=json > "$3";;
  esac
}
pam_binding() { # POLICY_FILE MEMBER ROLE: prints the conditioned binding PAM made, or NO-BINDING
  jq -r --arg m "$2" --arg r "$3" '[.bindings[] | select(.role==$r and (.members|index($m)) and .condition != null) | .condition.expression] | if length==0 then "NO-BINDING" else .[] end' "$1"
}
pam_revoke() { gcloud pam grants revoke "$1" --reason="setup 12 one-grant test complete" --billing-project="$CICD_PROJECT"; }
pam_record() { # GRANT OUTFILE: the grant with its timeline (requester, approver, activation, end)
  gcloud pam grants describe "$1" --billing-project="$CICD_PROJECT" --format=json > "$2"
  jq -r '.state, .requester, ([.timeline.events[] | keys[] | select(.!="eventTime")] | join(",")), (.externallyModified // false)' "$2"
}
