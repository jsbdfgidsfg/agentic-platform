#!/usr/bin/env python3
"""Writes pam/entitlements/*.json, pam/templates/*.json, pam/index.tsv, pam/role-columns.txt, pam/role-allow.tsv
and pam/no-approval.json from ~/.platform-env values (setup/12 PA-2.1). Stdlib only. Re-running rewrites the same bytes."""
import json, os, re, sys, pathlib
E = os.environ; root = pathlib.Path(__file__).resolve().parents[1]
def v(n, optional=False):
    x = E.get(n, "")
    if not x or x == "*tbd*" or re.search(r"<.*>", x):
        if optional: return None
        sys.exit(f"MISSING {n}")
    return x
RM = "cloudresourcemanager.googleapis.com"
TYPES = {"organizations": "Organization", "folders": "Folder", "projects": "Project"}
SH = "user:" + v("SA_2_ADMIN"); SR = ("user:" + v("SECURITY_REVIEWER_EMAIL", True)) if v("SECURITY_REVIEWER_EMAIL", True) else None
OWNERS = "group:" + v("GRP_PLATFORM_OWNERS"); NOTIFY = [v("GRP_PLATFORM_SECURITY")]
def doc(kind, ident, roles, max_s, requesters, approvers=None, n=1, conds=None):
    rb = [dict({"role": r}, **({"conditionExpression": conds[r]} if conds and r in conds else {})) for r in roles]
    d = {"eligibleUsers": [{"principals": sorted(requesters)}],
         "privilegedAccess": {"gcpIamAccess": {"resourceType": f"{RM}/{TYPES[kind]}", "resource": f"//{RM}/{kind}/{ident}", "roleBindings": rb}},
         "maxRequestDuration": f"{max_s}s",
         "requesterJustificationConfig": {"unstructured": {}},
         "additionalNotificationTargets": {"adminEmailRecipients": NOTIFY}}
    if approvers:
        d["approvalWorkflow"] = {"manualApprovals": {"requireApproverJustification": True, "steps": [
            {"approvalsNeeded": n, "approvers": [{"principals": sorted(approvers)}], "approverEmailRecipients": [v("SECOND_HUMAN_EMAIL")]}]}}
    return d
POLICY = ["roles/orgpolicy.policyAdmin", "roles/iam.denyAdmin", "roles/iam.principalAccessBoundaryAdmin"]
SINGLETON = ["roles/resourcemanager.projectCreator", "roles/serviceusage.serviceUsageAdmin", "roles/iam.serviceAccountCreator", "roles/resourcemanager.projectIamAdmin"]
REPAIR = ["roles/resourcemanager.projectIamAdmin", "roles/run.admin", "roles/aiplatform.admin", "roles/secretmanager.admin", "roles/datastore.owner",
          "roles/bigquery.admin", "roles/storage.admin", "roles/pubsub.admin", "roles/cloudscheduler.admin", "roles/iam.serviceAccountAdmin", "roles/serviceusage.serviceUsageAdmin"]
CORE_EXTRA = ["roles/cloudkms.admin", "roles/logging.admin", "roles/artifactregistry.admin", "roles/iam.workloadIdentityPoolAdmin", "roles/monitoring.admin",
              "roles/binaryauthorization.attestorsAdmin", "roles/resourcemanager.lienModifier", "roles/agentregistry.admin"]
ORG, FAP, CORE, CORE_N, REG = v("ORG_ID"), v("FLD_AGENTIC_PLATFORM"), v("CORE_PROJECT"), v("CORE_PROJECT_NUMBER"), v("REGION")
FACT = "serviceAccount:" + v("SA_FACTORY_APPLY")
par_kind, par_id = v("GE_CURRENT_PARENT").split("/")
sec = "platform-pager-key"
sec_cond = (f'resource.name == "projects/{CORE_N}/secrets/{sec}" || resource.name.startsWith("projects/{CORE_N}/secrets/{sec}/versions/") || '
            f'resource.name == "projects/{CORE_N}/locations/{REG}/secrets/{sec}" || resource.name.startsWith("projects/{CORE_N}/locations/{REG}/secrets/{sec}/versions/")')
rows = [  # id, var, kind, ident, alt, doc
 ("ent-platform-policy", "ENT_PLATFORM_POLICY", "organizations", ORG, "-", doc("organizations", ORG, POLICY, 3600, [OWNERS], [SH])),
 ("ent-org-sink", "ENT_ORG_SINK", "organizations", ORG, "-", doc("organizations", ORG, ["roles/logging.configWriter"], 3600, [OWNERS], [SH])),
 ("ent-k7-human", "ENT_K7_HUMAN", "organizations", ORG, "-", doc("organizations", ORG, POLICY, 3600, ["group:" + v("GRP_PLATFORM_APPROVERS")])),
 ("ent-k7-human-scheduler", "ENT_K7_HUMAN_SCHEDULER", "folders", FAP, "-", doc("folders", FAP, ["roles/cloudscheduler.admin"], 3600, ["group:" + v("GRP_PLATFORM_APPROVERS")])),
 ("ent-k7-executor", "ENT_K7_EXECUTOR", "organizations", ORG, "-", doc("organizations", ORG, POLICY, 1800, ["serviceAccount:" + v("SA_K7_EXECUTOR")])),
 ("ent-k7-executor-scheduler", "ENT_K7_EXECUTOR_SCHEDULER", "folders", FAP, "-", doc("folders", FAP, ["roles/cloudscheduler.admin"], 1800, ["serviceAccount:" + v("SA_K7_EXECUTOR")])),
 ("ent-pam-catalogue-org", "ENT_PAM_CATALOGUE_ORG", "organizations", ORG, "-", doc("organizations", ORG, ["roles/resourcemanager.organizationAdmin"], 3600, [OWNERS], [SH])),
 ("ent-folder-admin", "ENT_FOLDER_ADMIN", "folders", FAP, "-", doc("folders", FAP, ["roles/resourcemanager.folderAdmin", "roles/logging.configWriter", "roles/modelarmor.floorSettingsAdmin", "roles/cloudscheduler.admin"], 3600, [OWNERS], [SH])),
 ("ent-project-repair-core", "ENT_PROJECT_REPAIR_CORE", "folders", v("FLD_PLATFORM_CORE"), "-", doc("folders", v("FLD_PLATFORM_CORE"), REPAIR + CORE_EXTRA, 7200, [OWNERS], [SH])),
 ("ent-deploy-credential-holder-core", "ENT_DEPLOY_CREDENTIAL_HOLDER_CORE", "projects", CORE, CORE_N, doc("projects", CORE, ["roles/run.developer", "roles/iam.serviceAccountUser"], 3600, [OWNERS], [SH])),
 ("ent-secret-read-platform-pager-key", "ENT_SECRET_READ", "projects", CORE, CORE_N, doc("projects", CORE, ["roles/secretmanager.secretAccessor"], 1800, [OWNERS], [SH], conds={"roles/secretmanager.secretAccessor": sec_cond})),
 ("ent-factory-singleton-psa-nonprod", "ENT_FACTORY_SINGLETON_PSA_NONPROD", "folders", v("FLD_AGENTS_P_SA_NONPROD"), "-", doc("folders", v("FLD_AGENTS_P_SA_NONPROD"), SINGLETON, 3600, [FACT, OWNERS])),
 ("ent-factory-singleton-ctl-prod", "ENT_FACTORY_SINGLETON_CTL_PROD", "folders", v("FLD_CONTROLLERS_PROD"), "-", doc("folders", v("FLD_CONTROLLERS_PROD"), SINGLETON, 3600, [FACT, OWNERS], [SH])),
 ("ent-factory-singleton-ctl-nonprod", "ENT_FACTORY_SINGLETON_CTL_NONPROD", "folders", v("FLD_CONTROLLERS_NONPROD"), "-", doc("folders", v("FLD_CONTROLLERS_NONPROD"), SINGLETON, 3600, [FACT, OWNERS], [SH])),
 ("ent-bootstrap-module-r-nonprod", "ENT_BOOTSTRAP_MODULE_R_NONPROD", "folders", v("FLD_AGENTS_R_NONPROD"), "-", doc("folders", v("FLD_AGENTS_R_NONPROD"), SINGLETON, 3600, [OWNERS], [SH])),
 ("ent-bootstrap-module-improvers-prod", "ENT_BOOTSTRAP_MODULE_IMPROVERS_PROD", "folders", v("FLD_IMPROVERS_PROD"), "-", doc("folders", v("FLD_IMPROVERS_PROD"), SINGLETON, 3600, [OWNERS], [SH])),
 ("ent-bootstrap-module-improvers-nonprod", "ENT_BOOTSTRAP_MODULE_IMPROVERS_NONPROD", "folders", v("FLD_IMPROVERS_NONPROD"), "-", doc("folders", v("FLD_IMPROVERS_NONPROD"), SINGLETON, 3600, [OWNERS], [SH])),
 ("ent-witness-export-repair", "ENT_WITNESS_EXPORT_REPAIR", "folders", v("FLD_CONTROLLERS_PROD"), "-", doc("folders", v("FLD_CONTROLLERS_PROD"), ["roles/iam.serviceAccountAdmin"], 3600, ["group:" + v("GRP_EVE_OWNERS"), OWNERS], [SH])),
 ("ent-ge-admin", "ENT_GE_ADMIN", "projects", v("GEMINI_PROJECT"), v("GEMINI_PROJECT_NUMBER"), doc("projects", v("GEMINI_PROJECT"), ["roles/discoveryengine.agentspaceAdmin"], 3600, ["group:" + v("GRP_GE_ADMINS")])),
 ("ent-project-move-src", "ENT_PROJECT_MOVE_SRC", par_kind, par_id, "-", doc(par_kind, par_id, ["roles/resourcemanager.projectMover"], 3600, [OWNERS], [SH])),
 ("ent-project-move-dst", "ENT_PROJECT_MOVE_DST", "folders", v("FLD_GEMINI_ENTERPRISE"), "-", doc("folders", v("FLD_GEMINI_ENTERPRISE"), ["roles/resourcemanager.projectMover"], 3600, [OWNERS], [SH])),
]
if SR:
    rows.append(("ent-factory-singleton-psa-prod", "ENT_FACTORY_SINGLETON_PSA_PROD", "folders", v("FLD_AGENTS_P_SA_PROD"), "-", doc("folders", v("FLD_AGENTS_P_SA_PROD"), SINGLETON, 3600, [FACT, OWNERS], [SR, SH], n=2)))
T = lambda roles, max_s, req, appr, conds=None: doc("projects", "${PROJECT_ID}", roles, max_s, req, appr, conds=conds)
templates = {
 "ent-project-repair": T(REPAIR, 7200, [OWNERS, "group:${AGENT_OWNERS_GROUP}"], ["user:${APPROVER}"]),
 "ent-deploy-credential-holder": T(["roles/run.developer", "roles/iam.serviceAccountUser"], 3600, [OWNERS, "group:${AGENT_OWNERS_GROUP}"], ["user:${APPROVER}"]),
 "ent-secret-read": T(["roles/secretmanager.secretAccessor"], 1800, [OWNERS], ["user:${APPROVER}"],
     conds={"roles/secretmanager.secretAccessor": 'resource.name == "projects/${PROJECT_NUMBER}/locations/${SECRET_LOCATION}/secrets/${SECRET_ID}" || resource.name.startsWith("projects/${PROJECT_NUMBER}/locations/${SECRET_LOCATION}/secrets/${SECRET_ID}/versions/")'}),
 "ent-bootstrap-module": doc("folders", "${FOLDER_ID}", SINGLETON, 3600, [OWNERS], ["user:${APPROVER}"]),
}
w = lambda p, o: (root / p).write_text(json.dumps(o, indent=2, sort_keys=True) + "\n")
idx = ["id\tkind\tident\talt\tvar\tfile"]
for eid, var, kind, ident, alt, d in rows:
    w(f"entitlements/{eid}.json", d); idx.append(f"{eid}\t{kind}\t{ident}\t{alt}\t{var}\tentitlements/{eid}.json")
for name, d in templates.items():
    w(f"templates/{name}.template.json", d)
(root / "index.tsv").write_text("\n".join(idx) + "\n")
# role-columns.txt is what sweep.py refuses to see bound standing to a human, group or domain at any scope.
# Beyond the entitlement and template roles it carries: serviceAccountTokenCreator (S143, actAs by token);
# the two basic roles PAM cannot grant and therefore no entitlement lists (S018) - a standing roles/owner or
# roles/editor at the organisation or on a folder is exactly what the sweep must catch, so it is a Role-column
# role and not a special case of the project loop; resourcemanager.folderCreator, privilegedaccessmanager.admin and
# iam.securityAdmin, the three organisation rights the bootstrap exception carried (06 OB-3.7) that no entitlement
# lists, and that PA-9.3 withdraws.
EXTRA_SWEPT = {"roles/iam.serviceAccountTokenCreator", "roles/owner", "roles/editor",
               "roles/resourcemanager.folderCreator", "roles/privilegedaccessmanager.admin",
               "roles/iam.securityAdmin"}
roles = sorted({b["role"] for *_, d in rows for b in d["privilegedAccess"]["gcpIamAccess"]["roleBindings"]} |
               {b["role"] for d in templates.values() for b in d["privilegedAccess"]["gcpIamAccess"]["roleBindings"]} | EXTRA_SWEPT)
(root / "role-columns.txt").write_text("\n".join(roles) + "\n")
# role-allow.tsv: the documented standing exceptions, written down rather than left out of role-columns.txt.
# Break-glass at the organisation is handled generically by sweep.py for every role; these are the named ones.
# 04 section 5.1: PAM Admin held by platform-owners@ standing is "the one standing administrative role".
allow_rows = [("roles/privilegedaccessmanager.admin", "organizations", ORG, OWNERS, "04 section 5.1: PAM cannot bootstrap itself"),
              ("roles/privilegedaccessmanager.admin", "organizations", ORG, "group:" + v("GRP_GCP_ORG_ADMINS"), "04 section 7.1: break-glass")]
(root / "role-allow.tsv").write_text("role\tkind\tident\tmember\treason\n" + "".join("\t".join(r) + "\n" for r in allow_rows))
noappr = [{"id": eid, "scope": f"{kind}/{ident}", "reason": r, "ends": e} for eid, _, kind, ident, _, d in rows if "approvalWorkflow" not in d
          for r, e in [{"ent-ge-admin": ("SD-19: Tier C, PAM refuses self-approval; justification mandatory", "switch to SR approval as a dated change after PPL-SR (PA-8.1)"),
                        "ent-factory-singleton-psa-nonprod": ("SD-42: the twin can be built before two approvers exist", E["PSA_NONPROD_NOAPPROVAL_UNTIL"]),
                        }.get(eid, ("04 section 5.2: a fleet stop must not wait for an approver; activation pages the second human (15)", "none: by design"))]]
w("no-approval.json", {"schema": "pam-no-approval/v1", "entitlements": noappr})
print(len(rows), "entitlement files;", len(templates), "templates;", len(roles), "roles;", len(allow_rows), "allow rows;", len(noappr), "no-approval")
