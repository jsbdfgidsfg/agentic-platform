# tests/fixtures/sample-phase.sh: a phase that exercises every path of the runner (used by --selftest).
phase 90 "Runner self-test" "none"
requires org "resourcemanager.folders.create resourcemanager.folders.get"

step ST-1.1 AUTO "Create a folder" --needs "ORG_ID" --sets "ST_FOLDER_ID" --irreversible
s_ST_1_1_check() { nonempty r gcloud resource-manager folders list --organization="$(v ORG_ID)" --filter="displayName=st-sample" --format='value(name)'; }
s_ST_1_1_apply() {
  x gcloud resource-manager folders create --display-name=st-sample --organization="$(v ORG_ID)" || return 1
  local id; id="$(r gcloud resource-manager folders list --organization="$(v ORG_ID)" --filter="displayName=st-sample" --format='value(name)')"
  [ "$AGP_MODE" = apply ] && pset ST_FOLDER_ID "${id##*/}" || pset ST_FOLDER_ID "<from the list above>"
}

step ST-1.2 AUTO "Grant a role on the folder" --needs "ST_FOLDER_ID SA_1_ADMIN"
s_ST_1_2_check() { has_binding "user:$(v SA_1_ADMIN)" roles/resourcemanager.folderViewer gcloud resource-manager folders get-iam-policy "$(v ST_FOLDER_ID)"; }
s_ST_1_2_apply() { x gcloud resource-manager folders add-iam-policy-binding "$(v ST_FOLDER_ID)" --member="user:$(v SA_1_ADMIN)" --role=roles/resourcemanager.folderViewer --condition=None; }

step ST-1.3 CONSOLE "A person ticks a box in the Admin console" --witness
s_ST_1_3_check() { ckpt_done ST-1.3; }
s_ST_1_3_manual() { echo "Admin console > Security > a setting; then: agp-platform done ST-1.3 --witness <email>"; }

step ST-1.4 BLOCKED "Code that does not exist yet" --note "B-99"
s_ST_1_4_check() { ckpt_done ST-1.4; }
s_ST_1_4_manual() { echo "BLOCKED on B-99: the code is not written. The run continues."; }

step ST-1.5 AUTO "A REST resource" --needs "ST_FOLDER_ID"
s_ST_1_5_check() { api GET "https://example.googleapis.com/v1/folders/$(v ST_FOLDER_ID)/thing" >/dev/null; }
s_ST_1_5_apply() { local b; b="$(mktemp)"; printf '{"x":1}' > "$b"; api POST "https://example.googleapis.com/v1/folders/$(v ST_FOLDER_ID)/thing" "$b" >/dev/null; local rc=$?; rm -f "$b"; return $rc; }

step ST-1.6 AUTO-READ "A read-only verification" --needs "ST_FOLDER_ID"
s_ST_1_6_check() { return 1; }
s_ST_1_6_apply() { r gcloud resource-manager folders describe "$(v ST_FOLDER_ID)" --format='value(name)' >/dev/null; return 0; }
