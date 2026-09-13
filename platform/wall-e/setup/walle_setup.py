#!/usr/bin/env python3
"""Stand up Wall-E to Stage 0, as far as a script honestly can.

This implements platform/wall-e/SETUP.md, the 18-phase runbook. SETUP.md is the
authoritative source: where ARCHITECTURE.md or the design set disagrees with it,
this script follows SETUP.md and the disagreement is recorded in README.md.

Objective restated 2026-09-13; see the platform HLD
(platform/agentic-platform/01-hld.md §13.1 and §18 item 5).
Reversed 2026-09-13: the robot is a SUPER ADMIN on a dedicated licensed user
account (decision P33), not the holder of a narrow custom role. What that
changes here, and what compensates (platform HLD §13.1):
  - no Wall-E custom admin role is created or assigned any more; the
    "Wall-E — Reader" / "Wall-E — Operator (Stage 1)" roles are RETIRED names
    that verify reports as a finding if they still exist or are assigned;
  - Super Admin is granted by a HUMAN super admin at the platform's tier gate
    (manual step M2C, never by this script, never attested by --yes), with a
    second human super admin approving under Workspace multi-party approval;
  - verify's hardening check is INVERTED: the robot must be a super admin once
    the signed grant record is on file (and must not be one before), with the
    account hygiene set, the roster rule, and "never the only or the recovery
    super admin" asserted;
  - two OAuth clients on the one account, two secrets, two readers, two Cloud
    Run services: walle-actions (narrow client, band A) and
    walle-actions-super (broad client, bands B and C); cloud-platform is
    consented in NEITHER, and the self-test asserts it (the CI assertion);
  - the hard-denied list is data here (HARD_DENIED), handed to the denial
    suite, because Google no longer refuses anything at its end: the action
    services are the only gate and the consented scopes the only
    Google-enforced ceiling.

Things in the runbook that cannot be automated, or must not be. Each of them
prints an exact ordered instruction block, blocks until the operator confirms,
and is verified afterwards wherever an API can see the result:

  Phase 3   security key registration, then 2SV enforcement, then the password
  Phase 4   the login reporting rule, under Rules
  Phase 5   "Share data with Google Cloud services"
  Phase 9   the OAuth consent screen and the two OAuth clients
  Phase 9   the robot's own consents, which are interactive by design
  Gate      the Super Admin grant itself (M2C), at the tier gate only

Nothing here opens a browser for the robot's consent. A desktop OAuth flow
launched from a terminal opens the machine's *default* browser, which is signed
in as the operator, and the consent is then stored against a super admin. That
is SETUP.md section 7.1, the most likely single mistake in the whole build, and
the mechanism that causes it is the browser launch.

Safety properties this file is written to hold:
  - every create is get-or-create; re-running any subcommand is safe
  - nothing is deleted outside "teardown", which requires typing the project id
  - no secret value is ever printed or logged, and the ROBOT's refresh token is
    never written to disk: it goes from the token exchange straight into Secret
    Manager. The one secret this script does persist is the OPERATOR's own
    OAuth token, cached 0600 at OPERATOR_TOKEN_CACHE so phases 1 and 2 do
    not re-consent on every run. It is the operator's own super-admin
    credential, it is re-consentable at zero cost, and setting
    OPERATOR_TOKEN_CACHE="" disables the cache entirely.
  - placeholders in the config are a refusal, not a warning
  - four projects, one rule (platform/project-topology.md, 2026-09-13): PROJECT
    is Wall-E's own project (WALLE_PROJECT elsewhere in the wiki); the Gemini
    Enterprise app lives in GEMINI_PROJECT, Eve in EVE_PROJECT, Mo in
    MO_PROJECT. This script creates NOTHING of Eve's or Mo's, and every grant
    it makes to a principal from another project is a grant ON a Wall-E
    resource (a Cloud Run service, a BigQuery dataset, the engine), never a
    project-level role in Wall-E's project. gcloud() and gcloud_probe_json()
    append --project PROJECT by default, so every read of another project's
    resource goes through gcloud_probe_json_in() with that project named.
  - --dry-run prints every command and every API call and changes nothing. It
    issues read-only probes only: no subprocess with mutating=True runs, no
    Admin SDK write is attempted, and the checks whose *probe* is itself a
    write (the BigQuery DELETE probe) return SKIP rather than executing. The
    Workspace users.update write probe is gone (2026-09-13): against a super
    admin it would SUCCEED and be an unaudited robot write.
  - no silent continue-on-error anywhere
  - every mutating Workspace call prints a summary and, unless --yes, asks.
    --yes covers writes this script makes; it never attests a console step a
    human was supposed to perform (see confirm_manual).
"""

from __future__ import annotations

import argparse
import base64
import binascii
import datetime
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Callable, Dict, Iterable, List, Optional, Sequence, Tuple

# --------------------------------------------------------------------------- #
# Constants that encode decisions from the runbook. Changing one of these is a
# design change, not a configuration change.
# --------------------------------------------------------------------------- #

TOOL_NAME = "walle_setup"

# SETUP.md 1.3. Frozen at consent, permanently. Err wide on read, narrow on write.
# Since 2026-09-13 this is CLIENT 1, the NARROW client read only by
# walle-actions (band A, the catalogue). With Super Admin behind the account
# Google authorises by scope, not by role, so this list is the one
# Google-enforced ceiling left on anything that runs unattended (platform HLD
# §13.1 item 3). Note: admin.directory.user is enough for users.makeAdmin, so
# only the hard-denied list stops that call (HLD §13.1, "Minting super admins").
ROBOT_SCOPES: Tuple[str, ...] = (
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.group",
    "https://www.googleapis.com/auth/admin.directory.orgunit.readonly",
    "https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly",
    "https://www.googleapis.com/auth/admin.reports.audit.readonly",
    "https://www.googleapis.com/auth/admin.reports.usage.readonly",
    "https://www.googleapis.com/auth/apps.licensing",
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/gmail.labels",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/chat.messages",
    "https://www.googleapis.com/auth/calendar.events",
    "https://www.googleapis.com/auth/userinfo.email",
    "openid",
)

# CLIENT 2, the BROAD client read only by walle-actions-super (band B and the
# band-C handoff). Added 2026-09-13. Its scope list is itself a
# super-admin-signed decision (decision 3 re-cut, wall-e/01-hld.md "Decisions
# this page opens or changes") and is *tbd*: this script does not invent it.
# It is read from the config key SUPER_SCOPES (comma-separated) and `consent
# --super` is refused unless SUPER_SCOPES_DECISION names the signed record.
#
# In NEITHER client, ever (platform HLD §13.1 item 3, platform 02 PSA3): a
# cloud-platform token on a super-admin account is a path into the GCP
# organisation. Both documented forms are refused — cloud-platform and
# cloud-platform.read-only (https://developers.google.com/identity/protocols/oauth2/scopes,
# read 2026-09-13) — by validate_config, by run_consent before any URL is
# printed, by verify, and by the self-test (the CI assertion).
FORBIDDEN_SCOPE_MARKERS: Tuple[str, ...] = (
    "https://www.googleapis.com/auth/cloud-platform",
)
# userinfo.email and openid are what fetch_consented_email needs to refuse a
# grant stored against the wrong account (SETUP.md 7.1); client 2 needs them too.
SCOPES_REQUIRED_IN_EVERY_CLIENT: Tuple[str, ...] = (
    "https://www.googleapis.com/auth/userinfo.email",
    "openid",
)


def forbidden_scopes(scopes: Iterable[str]) -> List[str]:
    """Every scope in `scopes` that is cloud-platform in any form."""
    return sorted(
        s for s in (x.strip() for x in scopes)
        if any(s == m or s.startswith(m + ".") for m in FORBIDDEN_SCOPE_MARKERS)
    )


def parse_scope_list(value: str) -> List[str]:
    return [s.strip() for s in (value or "").split(",") if s.strip()]


# SETUP.md Phase 15. Eve never writes to Workspace, at any stage, ever.
# Eve's consent is NOT run by this script any more: Eve's OAuth client and
# consent screen are per-project objects and live in EVE_PROJECT, so the
# consent is a step of Eve's runbook (eve/07-build-runbook.md Phase 9,
# project-topology.md §7.1 Phase 15). The list stays here as the frozen
# reference that runbook must request verbatim; nothing below reads it.
EVE_SCOPES: Tuple[str, ...] = (
    "https://www.googleapis.com/auth/admin.directory.user.readonly",
    "https://www.googleapis.com/auth/admin.directory.group.readonly",
    "https://www.googleapis.com/auth/admin.directory.orgunit.readonly",
    "https://www.googleapis.com/auth/admin.directory.rolemanagement.readonly",
    "https://www.googleapis.com/auth/admin.reports.audit.readonly",
    "https://www.googleapis.com/auth/admin.reports.usage.readonly",
    "https://www.googleapis.com/auth/apps.licensing",
    "https://www.googleapis.com/auth/userinfo.email",
    "openid",
)

# The operator's own consent, used by this script for phases 1 and 2 and by
# the Workspace half of verify. This is NOT the robot's grant and is not frozen:
# it is the operator's own super-admin session, and it may be re-consented freely.
OPERATOR_SCOPES: Tuple[str, ...] = (
    "https://www.googleapis.com/auth/admin.directory.user",
    "https://www.googleapis.com/auth/admin.directory.group",
    "https://www.googleapis.com/auth/admin.directory.orgunit",
    "https://www.googleapis.com/auth/admin.directory.rolemanagement",
    "https://www.googleapis.com/auth/apps.groups.settings",
    "https://www.googleapis.com/auth/userinfo.email",
    "openid",
)

APIS_TO_ENABLE: Tuple[str, ...] = (
    "aiplatform.googleapis.com",
    # Two APIs an earlier revision enabled here are deliberately absent
    # (SETUP.md Phase 6, 2026-09-13). discoveryengine.googleapis.com: the
    # Gemini Enterprise app and its service agent live in GEMINI_PROJECT, where
    # that project's owner enables it; Google's cross-project page names no API
    # to enable in the agent project. Assumption: not required here; enable it
    # by hand only if Phase 13's registration fails without it, and record the
    # error in the build log. cloudkms.googleapis.com: Eve's key is in
    # EVE_PROJECT and the pinned-PEM verification path needs no KMS API; enable
    # it by hand only on the optional publicKeyViewer fallback (topology row
    # 14), and say so in the build log.
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "firestore.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudtasks.googleapis.com",
    "pubsub.googleapis.com",
    "bigquery.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "iamcredentials.googleapis.com",
    "billingbudgets.googleapis.com",
    "storage.googleapis.com",
    "admin.googleapis.com",
    "licensing.googleapis.com",
    "gmail.googleapis.com",
    "chat.googleapis.com",
    "calendar-json.googleapis.com",
    # Addition to SETUP.md Phase 6: this script sets group access settings
    # through the Groups Settings API rather than leaving them to the console.
    "groupssettings.googleapis.com",
)

# Wall-E's own five. eve-controller@ is NOT here any more: every Eve identity
# is created in EVE_PROJECT by Eve's runbook and every Mo identity in
# MO_PROJECT by Mo's (project-topology.md §2). Phase 6 creates nothing of theirs.
# walle-actions-super added 2026-09-13: the second service has its own service
# account, its own secret pair and its own audit rows (platform HLD §13.1
# item 3; platform 04 §5.2 names walle-actions-super@).
SERVICE_ACCOUNT_IDS: Tuple[str, ...] = (
    "walle-actions",
    "walle-actions-super",
    "walle-agent",
    "walle-dispatcher",
    "walle-operators-caller",
)

# The two action services (2026-09-13). Band A through the first, bands B and
# C through the second (platform HLD §13.1, "The three bands").
ACTIONS_SERVICE = "walle-actions"
SUPER_SERVICE = "walle-actions-super"

# Foreign identities this script names (never creates), derived in
# derive_config from EVE_PROJECT and MO_PROJECT. Any of them holding a
# PROJECT-level role in Wall-E's project is a verify failure (topology row 26).
FOREIGN_IDENTITY_KEYS: Tuple[str, ...] = (
    "SA_EVE_V0", "SA_EVE", "SA_EVE_VERIFIER", "SA_EVE_CONSOLE",
    "SA_MO_METRICS", "SA_MO_ANALYST", "SA_MO_NARRATOR",
)

ACTIONS_PROJECT_ROLES: Tuple[str, ...] = (
    "roles/datastore.user",
    "roles/pubsub.publisher",
    "roles/cloudtasks.enqueuer",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
)
# walle-actions-super@ (2026-09-13): what the HLD's component map draws for
# the second service — Firestore (approvals, halt flags), Pub/Sub, logs,
# metrics — and deliberately NOT cloudtasks.enqueuer: band B has no plan
# items, no queue and no dispatcher entry (wall-e/01-hld.md "The request path").
SUPER_PROJECT_ROLES: Tuple[str, ...] = (
    "roles/datastore.user",
    "roles/pubsub.publisher",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
)
DISPATCH_PROJECT_ROLES: Tuple[str, ...] = (
    "roles/datastore.user",
    "roles/logging.logWriter",
)
# Empty on purpose. roles/datastore.viewer for eve-controller@ was a
# project-level role in Wall-E's project granted to an identity from
# EVE_PROJECT, which project-topology.md forbids (row 12). Its replacement — a
# database-scoped IAM Condition, or a list endpoint on walle-actions — is
# decision 44 and is *tbd*; until it lands nothing is granted here and
# check_project_roles asserts that no foreign identity holds anything at
# project level.
EVE_PROJECT_ROLES: Tuple[str, ...] = ()

WALLE_SECRETS: Tuple[str, ...] = (
    "walle-oauth-client",
    "walle-refresh-token",
    "walle-confirm-hmac",
    # Added 2026-09-13: client 2, the broad client, and its refresh token.
    # Names from wall-e/01-hld.md's component map.
    "walle-super-oauth-client",
    "walle-super-refresh-token",
)
# Exactly one reader per secret (platform HLD §13.1 item 3: "Client 1, narrow,
# readable only by walle-actions; client 2, broad, readable only by
# walle-actions-super"). Config key of the reader's service-account email.
# walle-confirm-hmac stays with walle-actions: nothing on the platform pages
# gives the band-B service a use for it (its approvals are on the IAP surface).
SECRET_READERS: Dict[str, str] = {
    "walle-oauth-client": "SA_ACTIONS",
    "walle-refresh-token": "SA_ACTIONS",
    "walle-confirm-hmac": "SA_ACTIONS",
    "walle-super-oauth-client": "SA_ACTIONS_SUPER",
    "walle-super-refresh-token": "SA_ACTIONS_SUPER",
}
NARROW_CLIENT_SECRETS: Tuple[str, str] = ("walle-oauth-client", "walle-refresh-token")
SUPER_CLIENT_SECRETS: Tuple[str, str] = ("walle-super-oauth-client", "walle-super-refresh-token")
# Eve's two secrets live in EVE_PROJECT and are created by Eve's runbook. Named
# here ONLY so the verify half that reads Eve's project can assert that no
# Wall-E principal can read them; nothing in this script creates or deletes them.
EVE_SECRETS: Tuple[str, ...] = ("eve-oauth-client", "eve-refresh-token")

# project-topology.md §3 rows 4 and 6: dataset-level READER entries on Wall-E's
# datasets for principals from EVE_PROJECT and MO_PROJECT, made by THIS runbook
# because the datasets are Wall-E's. (config key of the principal, config key of
# the dataset, stage the principal exists from, topology row). Row 5
# (eve-verifier@ on walle_workspace_logs) is proposed under decision 47 and is
# *tbd*; row 21 (the validator custodian) has no identity yet, *tbd*.
CROSS_PROJECT_DATASET_READERS: Tuple[Tuple[str, str, str, str], ...] = (
    ("SA_EVE_V0", "AUDIT_DATASET", "S0", "4"),
    ("SA_EVE", "AUDIT_DATASET", "S3", "4"),
    ("SA_EVE_VERIFIER", "AUDIT_DATASET", "S3", "4"),
    ("SA_MO_METRICS", "AUDIT_DATASET", "S0", "6"),
    ("SA_MO_METRICS", "LOGS_DATASET", "S0", "6"),
)

# Where Wall-E's repository pins Eve's public key per key version (topology row
# 14): verification of an Eve approval needs no cross-project KMS grant at all.
EVE_PUBLIC_KEYS_SUBDIR: Tuple[str, ...] = ("contracts", "eve-public-keys")
# Google's documented cross-project grant, the FALLBACK of decision 42: applied
# in Wall-E's project only when the spike on file says the engine-scoped custom
# role was not enough. It carries reasoningEngines.create/delete/update as well
# as query, which is why it is never the default.
GEMINI_FALLBACK_ROLE = "roles/discoveryengine.serviceAgent"

PUBSUB_TOPICS: Tuple[str, ...] = (
    "walle-events",
    "walle-triggers",
    "walle-inbox",
    "walle-dead-letter",
)

AUDIT_TABLES: Tuple[str, ...] = (
    "actions",
    "runs",
    "plans",
    "approvals",
    "verifications",
    "config_versions",
)

# 400 days, SETUP.md Phase 7. Seconds for bq, milliseconds when read back.
PARTITION_EXPIRATION_SECONDS = 34560000

# SETUP.md Phase 10's nineteen names (2026-09-13). The set is what matters, so
# this script asserts names, not a count. EVE_PUBLIC_KEY_PEM and
# READ_CALLER_ALLOWLIST are the four-project additions: the pinned-PEM
# directory is the PRIMARY verification input (EVE_KMS_KEY is the optional
# fallback), and the read endpoints are allowlisted rather than open to any
# run.invoker holder (project-topology.md §3.1).
ACTIONS_ENV_NAMES: Tuple[str, ...] = (
    "WORKSPACE_DOMAIN",
    "ROBOT_ACCOUNT",
    "OPERATOR_GROUP",
    "READER_GROUP",
    "PROTECTED_GROUP",
    "SECRET_LOCATION",
    "REFRESH_TOKEN_SECRET",
    "REFRESH_TOKEN_VERSION",
    "OAUTH_CLIENT_SECRET",
    "CONFIRM_HMAC_SECRET",
    "EVE_PUBLIC_KEY_PEM",
    "EVE_KMS_KEY",
    "AUDIT_DATASET",
    "TASKS_QUEUE",
    "EXEC_CALLER_ALLOWLIST",
    "CONTROL_CALLER_ALLOWLIST",
    "READ_CALLER_ALLOWLIST",
    "INTERNAL_CALLER_ALLOWLIST",
    "AUDIENCE",
)
# walle-actions-super's env (2026-09-13). Its own secret pair and version pin,
# and its own two allowlists, which are deliberately SHORT: platform HLD §15
# boundary 2 / wall-e/01-hld.md boundary 2 give it "its own run.invoker set:
# the agent's identity and eve-controller@ (halt only); never Mo". So EXEC is
# the agent only (band B/C requests come from a human in chat through the
# agent), CONTROL is eve-controller@ only, and there is no READ and no
# INTERNAL list: no dispatcher route (by IAM) and no Mo, eve-console@ or
# eve-verifier@ on this service.
# EXTENDED 2026-09-13 (review-findings pass; project-topology.md row 27, eve/03
# section 14): CONTROL is eve-controller@ AND eve-verifier@, halt path only.
# Eve's reconciler limb runs as eve-verifier@ and raises every super-admin-lane
# halt (reconciliation_gap, the tenant-integrity rules, log_pipeline_silent);
# without it those halts could not reach this service. EVE_PUBLIC_KEY_PEM because Eve's halt is
# verified with "the same invoker principal, same key".
SUPER_ENV_NAMES: Tuple[str, ...] = (
    "WORKSPACE_DOMAIN",
    "ROBOT_ACCOUNT",
    "OPERATOR_GROUP",
    "PROTECTED_GROUP",
    "SECRET_LOCATION",
    "REFRESH_TOKEN_SECRET",
    "REFRESH_TOKEN_VERSION",
    "OAUTH_CLIENT_SECRET",
    "EVE_PUBLIC_KEY_PEM",
    "AUDIT_DATASET",
    "EXEC_CALLER_ALLOWLIST",
    "CONTROL_CALLER_ALLOWLIST",
    "AUDIENCE",
)
# Where the action image carries the pinned PEMs (SETUP.md Phase 8.1 / 10):
# EVE_PUBLIC_KEYS_SUBDIR of the repository, copied into the image at build.
EVE_PUBLIC_KEY_PEM_PATH = "/app/contracts/eve-public-keys"

DEFAULT_PLAYBOOK_JOBS: Tuple[str, ...] = (
    "licence-reclaim-suspended",
    "leaver-group-hygiene",
    "stale-account-report",
    "admin-change-digest",
)
WATCH_RENEW_JOB = "walle-gmail-watch-renew"

# --------------------------------------------------------------------------- #
# Phases 12b, 12c and 13b (chapters 12, 11 and 13). Every name below is the one
# the runbook uses; the gcloud invocations are SETUP.md's, verbatim.
# --------------------------------------------------------------------------- #

# SETUP.md Phase 12b. identity_type is fixed at create and cannot be patched.
AGENT_IDENTITY_MODES: Tuple[str, ...] = ("AGENT_IDENTITY", "SERVICE_ACCOUNT")
AGENT_IDENTITY_API = "agentidentity.googleapis.com"
# Must stay DISABLED: with it off no auth provider can ever be exercised here.
AGENT_IDENTITY_CREDENTIALS_API = "agentidentitycredentials.googleapis.com"
AGENT_TRUST_DOMAIN_PREFIX = "agents.global.org-"
AGENT_KEY_CONSTRAINTS: Tuple[str, ...] = (
    "iam.managed.disableServiceAccountKeyCreation",
    "iam.disableServiceAccountKeyUpload",
)
# Phase 12b step 6: the baseline the principal gets, and nothing else.
AGENT_BASELINE_ROLES: Tuple[str, ...] = (
    "roles/aiplatform.expressUser",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/browser",
    "roles/logging.logWriter",
)
# Their contents are undocumented, so they are read back and grepped.
AGENT_AUTOMATIC_ROLES: Tuple[str, ...] = (
    "roles/aiplatform.agentDefaultAccess",
    "roles/aiplatform.agentContextEditor",
)
FORBIDDEN_ROLE_PERMISSION_MARKERS: Tuple[str, ...] = ("secretmanager.", "setIamPolicy")
# Phase 12b step 7. NOTE: every permission name here must be verified against
# the list of permissions supported in deny policies before a real run; the
# research did not check it, and an unsupported name fails the create.
DENY_POLICY_ID = "walle-deny-agents"
DENY_POLICY_PERMISSIONS: Tuple[str, ...] = (
    "secretmanager.googleapis.com/versions.access",
    "aiplatform.googleapis.com/reasoningEngines.setIamPolicy",
    "run.googleapis.com/services.setIamPolicy",
)
# The opt-out that unbinds tokens from the certificate. Never set, anywhere.
TOKEN_SHARING_OPTOUT = "GOOGLE_API_PREVENT_AGENT_TOKEN_SHARING_FOR_GCP_SERVICES"
# Phase 12c step 5: telemetry on, and tool arguments kept OUT of Cloud Trace.
AGENT_TELEMETRY_ENV: Tuple[Tuple[str, str], ...] = (
    ("GOOGLE_CLOUD_AGENT_ENGINE_ENABLE_TELEMETRY", "true"),
    ("OTEL_SEMCONV_STABILITY_OPT_IN", "gen_ai_latest_experimental"),
    ("OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT", "EVENT_ONLY"),
    ("ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS", "false"),
)
SPIKE_DISPLAY_NAME = "walle-spike"

# SETUP.md Phase 12c. Everything starts inspect-only; the flips are `armor --enforce`.
MODEL_ARMOR_APIS: Tuple[str, ...] = (
    "modelarmor.googleapis.com",
    "networkservices.googleapis.com",
    "networksecurity.googleapis.com",
)
CONTENT_LOG_BUCKET = "walle-content-logs"
CONTENT_LOG_SINK = "walle-content-sink"
CONTENT_LOG_EXCLUSION = "walle-content"
ARMOR_TEMPLATES: Tuple[str, ...] = ("walle-ingress-prompt", "walle-ingress-response")
ARMOR_RAI_FILTERS = (
    '[{"filterType":"HATE_SPEECH","confidenceLevel":"MEDIUM_AND_ABOVE"},'
    '{"filterType":"HARASSMENT","confidenceLevel":"MEDIUM_AND_ABOVE"},'
    '{"filterType":"DANGEROUS","confidenceLevel":"MEDIUM_AND_ABOVE"},'
    '{"filterType":"SEXUALLY_EXPLICIT","confidenceLevel":"MEDIUM_AND_ABOVE"}]'
)
INGRESS_GATEWAY_NAME = "walle-ingress"
ARMOR_EXTENSION_NAME = "walle-ma-content-authz-ext"
ARMOR_POLICY_NAME = "walle-ma-content-authz-policy"
# Where the YAML this script writes and imports is committed: verify reads the
# extension file back and asserts failOpen is still false.
ARMOR_CONFIG_SUBDIR = ("config", "armor")
# Floor administration needs the global endpoint. Passed as the environment
# form of `gcloud config set api_endpoint_overrides/modelarmor` so it scopes to
# the floor commands only: set persistently it would also redirect the regional
# `templates create` on the next re-run.
MODEL_ARMOR_GLOBAL_ENDPOINT_ENV = {
    "CLOUDSDK_API_ENDPOINT_OVERRIDES_MODELARMOR": "https://modelarmor.googleapis.com/"
}

# SETUP.md Phase 13b.
# Changed 2026-09-13 (P71, platform 05 §2.2, platform HLD §18 item 25): the Agent
# Registry is ONE shared registry in CORE_PROJECT, written by factory-apply@;
# agentregistry.googleapis.com is absent from the tier folders' restrictServiceUsage
# allow-lists, so enabling it in Wall-E's project would be refused. REGISTRY_APIS
# is what Wall-E's project enables for its egress gateway; the per-project list
# (with agentregistry and apphub) survives only as the recorded fallback, used
# when REGISTRY_LOCAL_FALLBACK_DECISION names the dated record overturning P71's
# exclusion.
REGISTRY_APIS: Tuple[str, ...] = (
    "iap.googleapis.com",
    "dns.googleapis.com",
    "compute.googleapis.com",
)
REGISTRY_APIS_LOCAL_FALLBACK: Tuple[str, ...] = (
    "agentregistry.googleapis.com",
    "apphub.googleapis.com",
) + REGISTRY_APIS
EGRESS_GATEWAY_NAME = "walle-egress"
IAP_EXTENSION_NAME = "walle-iap-ext"
IAP_POLICY_NAME = "walle-iap-policy"
REGISTRY_AUDIT_FILTER = (
    'protoPayload.serviceName="agentregistry.googleapis.com" AND '
    'protoPayload.methodName=~"services\\.(create|update|delete)|bindings\\.|skills\\."'
)
# The egress gateway is a default-deny hostname allowlist for the reasoning
# layer. These are the hosts that must NEVER appear in it: the design's whole
# point is that the agent reaches Workspace and the secrets only through the
# action service. A registration naming any of them is a refusal, not a warning.
FORBIDDEN_EGRESS_HOST_MARKERS: Tuple[str, ...] = (
    "secretmanager",
    "firestore",
    "admin.googleapis.com",
    "bigquery",
    # Workspace hosts
    "gmail.googleapis.com",
    "chat.googleapis.com",
    "calendar-json.googleapis.com",
    "licensing.googleapis.com",
    "groupssettings.googleapis.com",
    "drive.googleapis.com",
    "people.googleapis.com",
    "cloudidentity.googleapis.com",
    "www.googleapis.com",
    "workspace.google.com",
)
# A card that advertises a write, an approval or a control operation is wrong
# by construction (13-agent-interconnection.md section 3.5).
FORBIDDEN_CARD_SKILL_MARKERS: Tuple[str, ...] = (
    "write", "approve", "control", "execute", "suspend", "delete", "update", "halt",
)

# Admin SDK privilege names differ between editions and Google publishes no
# complete catalogue (SETUP.md Phase 2 step 4). Every family below is resolved
# against the tenant's live privileges list; the first candidate that exists
# wins, and a family that matches nothing is a loud failure, never a silent
# skip.
#
# Reversed 2026-09-13 (platform HLD §13.1, §18 item 5): these families used to
# build two WALL-E roles, a customer-scoped Stage 0 reader and an OU-scoped
# Stage 1 operator. Wall-E holds Super Admin instead, which cannot be limited
# to an organisational unit or subset by privilege, so no Wall-E custom role
# exists and nothing here is resolved for the robot. The read families are
# kept for the one role this script still creates: Eve's read-only role.
# Eve's widened read privilege set (evidence perimeter, E-16) is fixed by Eve's
# runbook before her one-sitting consent; until it lands, this is the set.
EVE_PRIVILEGE_CANDIDATES: Tuple[Tuple[str, Tuple[str, ...]], ...] = (
    ("users read", ("USERS_RETRIEVE", "USER_READ")),
    ("groups read", ("GROUPS_RETRIEVE", "GROUP_READ")),
    ("org units read", ("ORGANIZATION_UNITS_RETRIEVE",)),
    ("reports audit read", ("SECURITY_REPORTS", "REPORTS_ACCESS", "ADMIN_DASHBOARD")),
    ("reports usage read", ("USAGE_REPORTS", "REPORTS_ACCESS", "ADMIN_DASHBOARD")),
    ("admin roles read", ("ROLE_MANAGEMENT_RETRIEVE", "ROLE_MANAGEMENT")),
)

# A denylist of write-shaped substrings cannot prove "no write privilege at
# all". Google publishes no complete privilege catalogue (SETUP.md Phase 2
# step 4), and the most dangerous names carry no write-shaped marker at all:
# USERS_ALL, GROUPS_ALL, ORGANIZATION_UNITS_ALL and ADMIN_APIS_ALL are the
# whole-service grants (create, update, delete), SUPER_ADMIN and ROOT_APP_ADMIN
# are total, and USER_SECURITY is password reset and session revocation. So the
# classification is INVERTED: this is the exact set of read privileges Eve's
# role is permitted to hold, and anything not named here counts as a write.
# (Until 2026-09-13 the same allowlist was READ_PRIVILEGE_ALLOWLIST and bounded
# Wall-E's Stage 0 role; that role is retired.)
EVE_READ_PRIVILEGE_ALLOWLIST: frozenset = frozenset(
    name
    for _family, candidates in EVE_PRIVILEGE_CANDIDATES
    for name in candidates
)


def is_write_privilege(name: str) -> bool:
    """True unless this privilege is on Eve's read allowlist.

    Unknown is a write. A privilege this script has never resolved has no
    business in a role it is about to assign to Eve's robot customer-scoped,
    and treating the unknown as harmless is how USERS_ALL passes a denylist.
    """
    return name.strip().upper() not in EVE_READ_PRIVILEGE_ALLOWLIST


# RETIRED 2026-09-13 (platform HLD §18 item 5). These were Wall-E's two custom
# admin roles ("Wall-E — Reader", customer-scoped, Stage 0; "Wall-E —
# Operator (Stage 1)", OU-scoped, assigned to nobody). Kept as names only, so
# verify can report a leftover role as a finding and FAIL if one is still
# assigned (the roster rule: the robot holds Super Admin and nothing else),
# status can show them, and teardown / rollback --phase 2 can remove them.
# Nothing in this script creates them any more.
RETIRED_WALLE_ROLE_NAMES: Tuple[str, ...] = (
    "Wall-E — Reader",
    "Wall-E — Operator (Stage 1)",
)
# A Workspace admin role is a tenant object with no GCP project. What moved to
# EVE_PROJECT is the role's OAuth consent (client and token), which Eve's
# runbook now performs; the role itself is still created here in Phase 2.
# Eve's robot is NEVER a super admin (platform HLD §4.6, R7).
ROLE_EVE_NAME = "Eve — Verifier"

# --------------------------------------------------------------------------- #
# The hard-denied list, as data (added 2026-09-13).
#
# Source: platform HLD §13.1 item 2 and wall-e/01-hld.md "The controls that
# replace role scoping". Hard-denied in EVERY lane — band A (walle-actions
# /v1/execute), band B (walle-actions-super /v1/execute-generic) and the
# band-C handoff (/v1/handoff refuses these instead of returning console
# steps) — with a breaker trip and a severity-1 page. The list is signed by
# the owner as P29 (open on 2026-09-13); until then this is the HLD's text.
#
# This script enforces none of it: the action services do. It exists here as
# DATA so the denial suite tests every row (cmd_denials hands the resolved list
# to tests/denials.py through WALLE_HARD_DENIED_FILE) and so the self-test can
# assert the list is complete and the vocabulary closed.
#
# The reason vocabulary is closed (platform HLD §12.3 audit.schema).
# Assumption: the per-row reason mapping below is this script's reading of
# the HLD, which names the five reasons but not which row carries which; the
# P29 signature settles it.
# --------------------------------------------------------------------------- #

HARD_DENIED_REASONS: Tuple[str, ...] = (
    "self_modification_denied",
    "escalation_denied",
    "posture_change_denied",
    "irreversible_denied",
    "money_denied",
)
HARD_DENIED_LANES: Tuple[str, ...] = ("A", "B", "C")

# The control groups the HLD names by local part, resolved against DOMAIN.
# OPERATORS and PROTECTED come from the config (walle-operators@,
# walle-protected@ in the HLD's spelling). walle-super-approvers@ is the band-B
# SUPER approver group of platform 04 §6.4. The mo-* groups are matched by
# prefix.
HARD_DENIED_CONTROL_GROUP_LOCAL_PARTS: Tuple[str, ...] = (
    "eve-owners", "ge-admins", "platform-approvers", "walle-super-approvers",
)
HARD_DENIED_CONTROL_GROUP_PREFIXES: Tuple[str, ...] = ("mo-",)

# kind: "target"  — any request whose target (user, group, OU, role) is this;
#       "method"  — Admin SDK Directory methods, with an optional condition;
#       "setting" — a tenant or GCP setting, reachable in the console only,
#                   so it matters to the band-C handoff above all.
# Method names verified against the Directory API REST reference on
# 2026-09-13: https://developers.google.com/workspace/admin/directory/reference/rest
HARD_DENIED: Tuple[Dict[str, Any], ...] = (
    {"id": "HD-01", "kind": "target", "what": "anything targeting the robot account",
     "targets": ("$ROBOT",), "reason": "self_modification_denied"},
    {"id": "HD-02", "kind": "target", "what": "anything targeting the robot's OU",
     "targets": ("$SVC_OU",), "reason": "self_modification_denied"},
    # HD-03 to HD-05 carry self_modification_denied, as 03-lld.md's hard-denied table
    # assigns them: disabling the controller or the control groups modifies the
    # envelope Wall-E runs inside. escalation_denied is for granting privilege
    # (makeAdmin, a Super Admin assignment). Aligned 2026-09-13.
    {"id": "HD-03", "kind": "target", "what": "anything targeting Eve's robot",
     "targets": ("$EVE_ROBOT",), "reason": "self_modification_denied"},
    {"id": "HD-04", "kind": "target", "what": "Eve's admin role",
     "targets": ("role:" + ROLE_EVE_NAME,), "reason": "self_modification_denied"},
    {"id": "HD-05", "kind": "target", "what": "the control groups",
     "targets": ("$OPERATORS", "$PROTECTED", "$CONTROL_GROUPS", "prefix:mo-"),
     "reason": "self_modification_denied"},
    {"id": "HD-06", "kind": "setting",
     "what": "the two OAuth clients (their GCP objects and their API-controls trust entries)",
     "targets": ("secret:walle-oauth-client", "secret:walle-super-oauth-client"),
     "reason": "self_modification_denied"},
    {"id": "HD-07", "kind": "setting", "what": "the activity rules that alert on the robot",
     "targets": ("rule:Wall-E robot interactive login",), "reason": "posture_change_denied"},
    {"id": "HD-08", "kind": "setting", "what": "\"Share data with Google Cloud services\"",
     "targets": (), "reason": "posture_change_denied"},
    {"id": "HD-09", "kind": "setting", "what": "the SecOps export setting",
     "targets": (), "reason": "posture_change_denied"},
    {"id": "HD-10", "kind": "setting", "what": "the organisation sinks",
     "targets": ("sink:walle-workspace-audit", "sink:walle-audit-bq"),
     "reason": "posture_change_denied"},
    {"id": "HD-11", "kind": "method", "what": "users.makeAdmin, on anyone",
     "methods": ("directory.users.makeAdmin",), "condition": "always",
     "reason": "escalation_denied"},
    {"id": "HD-12", "kind": "method",
     "what": "roleAssignments.insert of Super Admin or of a role carrying admin-role management",
     "methods": ("directory.roleAssignments.insert",),
     "condition": "role.isSuperAdminRole or role carries admin-role management",
     "reason": "escalation_denied"},
    {"id": "HD-13", "kind": "method", "what": "users.delete of any admin",
     "methods": ("directory.users.delete",),
     "condition": "target isAdmin or isDelegatedAdmin", "reason": "irreversible_denied"},
    {"id": "HD-14", "kind": "setting", "what": "deletion of the tenant account",
     "targets": (), "reason": "irreversible_denied"},
    {"id": "HD-15", "kind": "method", "what": "other admins' security settings and backup codes",
     "methods": ("directory.verificationCodes.generate",
                 "directory.verificationCodes.invalidate",
                 "directory.verificationCodes.list",
                 "directory.twoStepVerification.turnOff",
                 "directory.asps.delete", "directory.tokens.delete",
                 "directory.users.signOut",
                 # Added 2026-09-13 (review-findings pass): resetting another
                 # admin's password or recovery fields, or suspending them, is
                 # account takeover, and wall-e/03-lld.md's row already names
                 # "password or recovery-field changes". Assumption: this reading
                 # of "security settings" is confirmed by the P29 signature.
                 "directory.users.update", "directory.users.patch"),
     "condition": "target isAdmin or isDelegatedAdmin; for directory.users.update and "
                  "directory.users.patch, only when the body touches password, "
                  "changePasswordAtNextLogin, hashFunction, recoveryEmail, recoveryPhone "
                  "or suspended",
     "security_fields": ("password", "changePasswordAtNextLogin", "hashFunction",
                         "recoveryEmail", "recoveryPhone", "suspended"),
     "reason": "escalation_denied"},
    {"id": "HD-16", "kind": "setting", "what": "the super-admin self-recovery setting",
     "targets": (), "reason": "posture_change_denied"},
    {"id": "HD-17", "kind": "setting", "what": "domain-wide delegation, any change",
     "targets": (), "reason": "posture_change_denied"},
    # platform 04 §8.4, P66: "MPA off" is hard-denied and severity 1, and the
    # robot is never an approver on the multi-party approval surface.
    {"id": "HD-18", "kind": "setting",
     "what": "turning Workspace multi-party approval off, or approving through it",
     "targets": (), "reason": "posture_change_denied"},
)


def hard_denied_resolved(cfg: Dict[str, str]) -> List[Dict[str, Any]]:
    """HARD_DENIED with $KEY targets resolved from the config, for the suite.

    Unresolvable targets stay visible as "<KEY unset>" rather than vanishing:
    a row that silently lost its target would test nothing and read as green.
    """
    domain = cfg.get("DOMAIN", "")
    groups = ["%s@%s" % (local, domain or "<DOMAIN unset>")
              for local in HARD_DENIED_CONTROL_GROUP_LOCAL_PARTS]
    out: List[Dict[str, Any]] = []
    for row in HARD_DENIED:
        resolved: List[str] = []
        for target in row.get("targets", ()):
            if target == "$CONTROL_GROUPS":
                resolved.extend(groups)
            elif target.startswith("$"):
                resolved.append(cfg.get(target[1:], "") or "<%s unset>" % target[1:])
            else:
                resolved.append(target)
        entry = dict(row)
        entry["targets"] = resolved
        entry["methods"] = list(row.get("methods", ()))
        entry["lanes"] = list(HARD_DENIED_LANES)
        entry["severity"] = 1
        out.append(entry)
    return out


def hard_denied_problems() -> List[str]:
    """Static consistency of the list: closed vocabulary, unique ids, shapes."""
    problems: List[str] = []
    seen = set()
    for row in HARD_DENIED:
        if row.get("id") in seen:
            problems.append("duplicate id %s" % row.get("id"))
        seen.add(row.get("id"))
        if row.get("reason") not in HARD_DENIED_REASONS:
            problems.append("%s carries reason %r outside the closed vocabulary"
                            % (row.get("id"), row.get("reason")))
        if row.get("kind") not in ("target", "method", "setting"):
            problems.append("%s has kind %r" % (row.get("id"), row.get("kind")))
        if row.get("kind") == "method" and not row.get("methods"):
            problems.append("%s is a method row with no method" % row.get("id"))
        if row.get("kind") == "target" and not row.get("targets"):
            problems.append("%s is a target row with no target" % row.get("id"))
    return problems

GEMINI_ROUTING_DESCRIPTION = (
    "Answers questions about the Google Workspace directory: users, groups, "
    "organisational units, licences, admin-role holders, sign-in activity and "
    "audit reports. Does not send mail on your behalf, does not change any user "
    "or group, and cannot suspend accounts. For anything outside Workspace "
    "administration, do not route here."
)

REQUIRED_CONFIG_KEYS: Tuple[str, ...] = (
    "DOMAIN",
    # PROJECT is Wall-E's project (WALLE_PROJECT elsewhere in the wiki);
    # PROJECT_NUMBER is its number. Documented once, here, and once in SETUP.md
    # §1.6; not renamed (project-topology.md §6). The three others are the
    # projects this script must name when it grants across a boundary.
    "PROJECT",
    "GEMINI_PROJECT",
    "EVE_PROJECT",
    "MO_PROJECT",
    "REGION",
    "BQ_LOCATION",
    "ORG_ID",
    "BILLING",
    "CUSTOMER_ID",
    "ROBOT",
    "EVE_ROBOT",
    "OPERATORS",
    "READERS",
    "PROTECTED",
    "SVC_OU",
    "PILOT_OU",
    "SANDBOX_OU",
    "WALLE_REPO",
    "FLOOR_LIST_PATH",
    "OPERATOR_EMAIL",
    "OPERATOR_NAME",
    "OPERATOR_OAUTH_CLIENT_FILE",
    "SANDBOX_ACCOUNTS",
    "BUDGET_AMOUNT",
)

# Which of the keys above each subcommand actually uses. Validation is scoped to
# this, not to the union: `walle gcp` builds a GCP project and needs neither
# OPERATOR_OAUTH_CLIENT_FILE (Admin SDK consent, phases 1/2/15) nor
# SANDBOX_ACCOUNTS (phase 1 step 6), and refusing to run it over those is a
# usability trap for someone following the runbook one phase at a time.
# Under-listing here is safe: the key is still fetched with ctx.need(), which
# names it and says which phase produces it. Over-listing is the bug.
_WORKSPACE_KEYS: Tuple[str, ...] = (
    "DOMAIN", "CUSTOMER_ID", "ROBOT", "EVE_ROBOT", "OPERATORS", "READERS",
    "PROTECTED", "SVC_OU", "PILOT_OU", "SANDBOX_OU", "SANDBOX_ACCOUNTS",
    "WALLE_REPO", "FLOOR_LIST_PATH", "OPERATOR_EMAIL", "OPERATOR_NAME",
    "OPERATOR_OAUTH_CLIENT_FILE",
)
_GCP_KEYS: Tuple[str, ...] = (
    "PROJECT", "REGION", "BQ_LOCATION", "ORG_ID", "BILLING", "BUDGET_AMOUNT",
    "WALLE_REPO", "OPERATORS",
    # Phase 6 creates the project under the folder that holds all four
    # (project-topology.md §5) and reads GEMINI_PROJECT's number for the
    # build log (gemini_project_number); Phase 7 makes the dataset-level
    # READER grants to Eve's and Mo's identities, which are named from their
    # projects. Every key a subcommand uses is validated for that subcommand.
    "FOLDER_ID", "GEMINI_PROJECT", "EVE_PROJECT", "MO_PROJECT",
    # The PARENT of Wall-E's project: the P-SA tier folder fld-agents-p-sa-prod
    # (agentic-platform/02-landing-zone-and-tiers.md section 2), never FOLDER_ID
    # itself. A project parented straight to the platform folder inherits the
    # floor but none of its tier's stricter policies (PREREQUISITES.md s.10 #36).
    "WALLE_FOLDER_ID",
)
_DEPLOY_KEYS: Tuple[str, ...] = (
    "DOMAIN", "PROJECT", "REGION", "BQ_LOCATION", "ORG_ID", "ROBOT",
    "OPERATORS", "READERS", "PROTECTED", "WALLE_REPO", "SVC_OU", "PILOT_OU",
    "SANDBOX_OU",
    # Phase 12b. INGRESS_GATEWAY and AGENT_IDENTITY_SPIKE_RESULT are optional
    # here and are checked at runtime: the first binds the gateway only when
    # set, the second is required only on the SERVICE_ACCOUNT fallback.
    "AGENT_IDENTITY_MODE",
    # Phase 10: run.invoker and the caller allowlists carry Eve's and Mo's
    # cross-project emails, and EVE_KMS_KEY points at Eve's project. Phase 12:
    # the engine policy names the Gemini project's service agent by NUMBER
    # (GEMINI_PROJECT_NUMBER is looked up from GEMINI_PROJECT when unset).
    "EVE_PROJECT", "MO_PROJECT", "GEMINI_PROJECT",
)
# Phase 12c. MODEL_ARMOR_ENFORCE_DECISION is checked only under --enforce.
_ARMOR_KEYS: Tuple[str, ...] = (
    "PROJECT", "REGION", "ORG_ID", "FOLDER_ID", "OPERATORS", "WALLE_REPO",
    "CONTENT_LOG_RETENTION_DAYS",
)
# Phase 13b. MO_PRINCIPAL is no longer here: the agentregistry.viewer grants to
# Eve and Mo were project-level roles in Wall-E's project for foreign
# identities and are dropped (project-topology.md decision 43).
# 2026-09-13 (P71): CI_DEPLOYER is needed only on the local fallback, and
# CORE_PROJECT is checked by registry_project() so the fallback does not need it.
_REGISTRY_KEYS: Tuple[str, ...] = (
    "PROJECT", "REGION", "ORG_ID", "EGRESS_GATEWAY",
    "WALLE_REPO",
)
# Phase 12b step 3, on a throwaway engine.
_SPIKE_KEYS: Tuple[str, ...] = (
    "PROJECT", "REGION", "ORG_ID", "WALLE_REPO", "AGENT_IDENTITY_SPIKE_RESULT",
)
CONFIG_KEYS_FOR_SUBCOMMAND: Dict[str, Tuple[str, ...]] = {
    # preflight is the "full picture" command: it reports on everything and
    # never refuses, so it is handled separately in main().
    "preflight": REQUIRED_CONFIG_KEYS,
    "workspace": _WORKSPACE_KEYS,
    "gcp": _GCP_KEYS,
    # Phase 9 only. Phase 15 (Eve's consent) is Eve's runbook: EVE_ROBOT is no
    # longer needed here. `consent --super` (client 2, 2026-09-13) additionally
    # reads SUPER_SCOPES and SUPER_SCOPES_DECISION with ctx.need at run time.
    "consent": ("DOMAIN", "PROJECT", "REGION", "ROBOT"),
    "deploy": _DEPLOY_KEYS,
    "spike": _SPIKE_KEYS,
    "armor": _ARMOR_KEYS,
    "registry": _REGISTRY_KEYS,
    # The app is read from GEMINI_PROJECT; the engine it fronts stays in PROJECT.
    "register": ("PROJECT", "GEMINI_PROJECT", "GEMINI_APP_ID", "GEMINI_APP_LOCATION",
                 "REGION", "DOMAIN", "READERS", "OPERATORS", "BQ_LOCATION"),
    "triggers": ("PROJECT", "REGION", "ROBOT", "OPERATORS"),
    "verify": REQUIRED_CONFIG_KEYS,
    # DOMAIN, SVC_OU, EVE_ROBOT and PROTECTED added 2026-09-13: the hard-denied
    # rows resolve their targets from them, and an unresolved target tests nothing.
    "denials": ("PROJECT", "REGION", "ORG_ID", "ROBOT", "OPERATORS", "SANDBOX_ACCOUNTS",
                "DOMAIN", "SVC_OU", "EVE_ROBOT", "PROTECTED"),
    "stage0": REQUIRED_CONFIG_KEYS,
    "rollback": ("PROJECT", "REGION", "CUSTOMER_ID", "OPERATOR_OAUTH_CLIENT_FILE"),
    # status reports on the cross-project grants this script owns, so it must
    # be able to name the foreign principals and the Gemini service agent.
    "status": ("PROJECT", "REGION", "EVE_PROJECT", "MO_PROJECT", "GEMINI_PROJECT"),
    "teardown": ("PROJECT", "REGION"),
    "dump-privileges": ("CUSTOMER_ID", "OPERATOR_EMAIL", "OPERATOR_OAUTH_CLIENT_FILE"),
}

# The alternate delimiter for gcloud's escaped-list syntax on --set-env-vars.
# gcloud topic escaping: "the delimiter is a sequence of one or more characters
# that may not appear in any value in the list". SETUP.md said "^@^" and was
# wrong — almost every value here is an email address, so gcloud split
# ROBOT_ACCOUNT=walle-bot@example.com into two items and aborted with "Bad syntax
# for dict arg: [example.com]". ";" appears in no name and no value: not in an
# address, not in a comma-joined allowlist, not in an OU path or a URL. It is
# validated against both names and values in env_flag_value, and against the
# config in validate_config.
ENV_DELIMITER = ";"

# Every value below lands inside the Cloud Run --set-env-vars escaped list, so
# the delimiter must appear in none of them (see env_flag_value).
ENV_DELIMITED_CONFIG_KEYS: Tuple[str, ...] = (
    "DOMAIN", "ROBOT", "EVE_ROBOT", "OPERATORS", "READERS", "PROTECTED",
    "SVC_OU", "PILOT_OU", "SANDBOX_OU", "SA_ACTIONS", "SA_ACTIONS_SUPER", "SA_AGENT",
    "SA_DISPATCH",
    "SA_EVE", "SA_EVE_VERIFIER", "SA_EVE_CONSOLE", "SA_MO_ANALYST", "MO_PRINCIPAL",
    "SA_OPS_CALLER", "AUDIT_DATASET", "LOGS_DATASET", "TASKS_QUEUE",
    "KMS_KEYRING", "KMS_KEY", "PROJECT", "REGION",
    # EVE_PROJECT is embedded in SA_EVE and in EVE_KMS_KEY; MO_PROJECT in
    # SA_MO_ANALYST.
    "EVE_PROJECT", "MO_PROJECT",
)

PLACEHOLDER_RE = re.compile(r"<[^>]*>")
PLACEHOLDER_LITERALS = frozenset({"CHANGEME", "TBD", "tbd", "changeme", "REPLACE_ME"})


# --------------------------------------------------------------------------- #
# Errors and output
# --------------------------------------------------------------------------- #


class WalleError(Exception):
    """Anything that must stop the run. There is no recoverable class here."""


class ManualStepRequired(WalleError):
    """An API path exists but is refused; the operator must finish it by hand."""


def _is_tty() -> bool:
    return sys.stdin.isatty() and sys.stdout.isatty()


def say(msg: str = "") -> None:
    print(msg, flush=True)


def step(msg: str) -> None:
    print("  → " + msg, flush=True)


def warn(msg: str) -> None:
    print("  !! " + msg, file=sys.stderr, flush=True)


def section(title: str) -> None:
    print("", flush=True)
    print("=" * 78, flush=True)
    print(title, flush=True)
    print("=" * 78, flush=True)


def die(msg: str) -> None:
    raise WalleError(msg)


def render_table(rows: Sequence[Sequence[str]], headers: Sequence[str]) -> str:
    """Fixed-width table. Used by verify and status, which are read by eye."""
    all_rows = [list(headers)] + [list(r) for r in rows]
    widths = [0] * len(headers)
    for row in all_rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(str(cell)))
    lines = []
    for idx, row in enumerate(all_rows):
        cells = [str(c).ljust(widths[i]) for i, c in enumerate(row)]
        lines.append("  ".join(cells).rstrip())
        if idx == 0:
            lines.append("  ".join("-" * w for w in widths))
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

_ENV_LINE_RE = re.compile(r"^\s*(?:export\s+)?([A-Z][A-Z0-9_]*)\s*=\s*(.*)$")


def find_config_path(explicit: Optional[str]) -> str:
    """Config is a shell-sourceable env file, so the operator can source it too."""
    candidates = []
    if explicit:
        candidates.append(explicit)
    if os.environ.get("WALLE_CONFIG"):
        candidates.append(os.environ["WALLE_CONFIG"])
    candidates.append(os.path.expanduser("~/.walle-env"))
    candidates.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), "walle.env"))
    for path in candidates:
        if path and os.path.isfile(os.path.expanduser(path)):
            return os.path.expanduser(path)
    die(
        "no config file found. Looked at: "
        + ", ".join(candidates)
        + "\nCopy walle.env.example to ~/.walle-env and fill it in."
    )
    return ""  # unreachable, keeps type checkers quiet


def load_config(path: str) -> Dict[str, str]:
    """Parse KEY=value, honouring quotes and ${VAR} expansion from earlier keys."""
    values: Dict[str, str] = {}
    with open(path, "r", encoding="utf-8") as handle:
        for raw in handle:
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            match = _ENV_LINE_RE.match(line)
            if not match:
                continue
            key, value = match.group(1), match.group(2).strip()
            if "#" in value and not (value.startswith('"') or value.startswith("'")):
                value = value.split("#", 1)[0].strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                value = value[1:-1]
            values[key] = _expand(value, values)
    return values


def _expand(value: str, known: Dict[str, str]) -> str:
    def repl(match: "re.Match[str]") -> str:
        name = match.group(1) or match.group(2)
        return known.get(name, os.environ.get(name, ""))

    return re.sub(r"\$\{([A-Z0-9_]+)\}|\$([A-Z0-9_]+)", repl, value)


def derive_config(cfg: Dict[str, str]) -> Dict[str, str]:
    """Values SETUP.md 1.7 derives rather than asks for."""
    project = cfg.get("PROJECT", "")
    region = cfg.get("REGION", "")
    cfg.setdefault("SA_ACTIONS", "walle-actions@%s.iam.gserviceaccount.com" % project)
    cfg.setdefault(
        "SA_ACTIONS_SUPER", "walle-actions-super@%s.iam.gserviceaccount.com" % project
    )
    cfg.setdefault("SA_AGENT", "walle-agent@%s.iam.gserviceaccount.com" % project)
    cfg.setdefault("SA_DISPATCH", "walle-dispatcher@%s.iam.gserviceaccount.com" % project)
    cfg.setdefault(
        "SA_OPS_CALLER", "walle-operators-caller@%s.iam.gserviceaccount.com" % project
    )
    # Eve's and Mo's identities live in THEIR projects (project-topology.md
    # §6, "forms to retire"): never derived from PROJECT. Left unset when the
    # project is unset, so ctx.need() names the missing key instead of
    # building an address in no project at all.
    eve_project = cfg.get("EVE_PROJECT", "")
    if eve_project:
        for key, account in (
            ("SA_EVE_V0", "eve-v0"), ("SA_EVE", "eve-controller"),
            ("SA_EVE_VERIFIER", "eve-verifier"), ("SA_EVE_CONSOLE", "eve-console"),
        ):
            cfg.setdefault(key, "%s@%s.iam.gserviceaccount.com" % (account, eve_project))
    mo_project = cfg.get("MO_PROJECT", "")
    if mo_project:
        for key, account in (
            ("SA_MO_METRICS", "mo-metrics"), ("SA_MO_ANALYST", "mo-analyst"),
            ("SA_MO_NARRATOR", "mo-narrator"),
        ):
            cfg.setdefault(key, "%s@%s.iam.gserviceaccount.com" % (account, mo_project))
        # The registry and the run.invoker grant must agree on who Mo is.
        cfg.setdefault("MO_PRINCIPAL", "serviceAccount:" + cfg["SA_MO_ANALYST"])
    cfg.setdefault("AR_REPO", "%s-docker.pkg.dev/%s/walle" % (region, project))
    cfg.setdefault("STAGING_BUCKET", "gs://%s-agent-staging" % project)
    # Eve's key ring and key, in EVE_PROJECT, owned and created by Eve's
    # runbook (Phase 11). Wall-E only NAMES them: in EVE_KMS_KEY, the optional
    # KMS fallback for verifying an approval, and in the cross-project half of
    # verify. Ring name per project-topology.md §2 (Eve's row); *tbd* until
    # Eve's pages confirm it.
    cfg.setdefault("KMS_KEYRING", "eve")
    cfg.setdefault("KMS_KEY", "eve-approval")
    cfg.setdefault("AUDIT_DATASET", "walle_audit")
    cfg.setdefault("LOGS_DATASET", "walle_workspace_logs")
    cfg.setdefault("TASKS_QUEUE", "walle-plan-items")
    cfg.setdefault("ENGINE_DISPLAY_NAME", "wall-e")
    cfg.setdefault("PLAYBOOK_JOBS", ",".join(DEFAULT_PLAYBOOK_JOBS))
    cfg.setdefault("PLAYBOOK_SCHEDULE", "0 7 * * MON")
    cfg.setdefault("TIMEZONE", "Europe/Paris")
    cfg.setdefault("BUDGET_AMOUNT", "200EUR")
    cfg.setdefault(
        "OPERATOR_TOKEN_CACHE", os.path.expanduser("~/.walle/operator-token.json")
    )
    # Phases 12b, 12c, 13b. The identity default is the design's choice
    # (decision 19); the fallback needs the spike's recorded result.
    cfg.setdefault("AGENT_IDENTITY_MODE", "AGENT_IDENTITY")
    cfg.setdefault("CONTENT_LOG_RETENTION_DAYS", "30")
    cfg.setdefault("EGRESS_GATEWAY", EGRESS_GATEWAY_NAME)
    return cfg


def keys_needed_by(subcommand: Optional[str]) -> Tuple[str, ...]:
    """The config keys one subcommand uses. Unknown subcommand: everything."""
    if not subcommand:
        return REQUIRED_CONFIG_KEYS
    return CONFIG_KEYS_FOR_SUBCOMMAND.get(subcommand, REQUIRED_CONFIG_KEYS)


def subcommands_needing(key: str) -> List[str]:
    """Which subcommands use this key, so a refusal can say who wants it."""
    return sorted(
        name
        for name, keys in CONFIG_KEYS_FOR_SUBCOMMAND.items()
        if name != "preflight" and key in keys
    )


def validate_config(
    cfg: Dict[str, str], subcommand: Optional[str] = None
) -> List[str]:
    """Return every problem, so preflight can print them all at once.

    Scoped to the keys `subcommand` actually uses. All-or-nothing validation
    made `walle gcp` refuse to run over OPERATOR_OAUTH_CLIENT_FILE and
    SANDBOX_ACCOUNTS, neither of which it touches.
    """
    problems: List[str] = []
    required = keys_needed_by(subcommand)
    for key in required:
        value = cfg.get(key, "")
        if not value:
            wanted_by = subcommands_needing(key)
            problems.append(
                "%s is missing or empty (needed by: %s)"
                % (key, ", ".join(wanted_by) if wanted_by else "this subcommand")
            )
            continue
        if PLACEHOLDER_RE.search(value) or value in PLACEHOLDER_LITERALS:
            problems.append("%s still holds a placeholder: %s" % (key, value))
    for key, value in sorted(cfg.items()):
        if key in required or key in REQUIRED_CONFIG_KEYS:
            continue
        # A derived or optional key with a placeholder in it is still a refusal:
        # it is not "not filled in yet", it is a value that will be deployed.
        if value and (PLACEHOLDER_RE.search(value) or value in PLACEHOLDER_LITERALS):
            problems.append("%s still holds a placeholder: %s" % (key, value))
    region = cfg.get("REGION", "")
    if region and region != "europe-west1":
        problems.append(
            "REGION is %s. SETUP.md 1.7 pins europe-west1: Agent Runtime GA plus EU "
            "residency. Changing it invalidates the residency posture in "
            "ARCHITECTURE.md section 9." % region
        )
    if cfg.get("BQ_LOCATION") and cfg["BQ_LOCATION"] != "EU":
        problems.append("BQ_LOCATION must be EU (SETUP.md Phase 7)")
    domain = cfg.get("DOMAIN", "")
    for key in ("ROBOT", "EVE_ROBOT", "OPERATORS", "READERS", "PROTECTED"):
        value = cfg.get(key, "")
        if value and domain and not value.endswith("@" + domain):
            problems.append("%s (%s) is not in DOMAIN %s" % (key, value, domain))
    # 2026-09-13, platform HLD §13.1 items 3 and 6.
    # cloud-platform in any form, in either client's list, is a refusal before
    # anything runs: on a super-admin account it is a path into the GCP
    # organisation. ROBOT_SCOPES is a constant and asserted by the self-test;
    # SUPER_SCOPES is config and asserted here.
    for label, scopes in (("ROBOT_SCOPES", list(ROBOT_SCOPES)),
                          ("SUPER_SCOPES", parse_scope_list(cfg.get("SUPER_SCOPES", "")))):
        bad = forbidden_scopes(scopes)
        if bad:
            problems.append(
                "%s carries %s. cloud-platform is never consented on the robot, in "
                "either client (platform HLD §13.1 item 3)" % (label, ", ".join(bad)))
    super_scopes = parse_scope_list(cfg.get("SUPER_SCOPES", ""))
    if super_scopes and not PLACEHOLDER_RE.search(cfg.get("SUPER_SCOPES", "")):
        odd = [s for s in super_scopes
               if s != "openid" and not s.startswith("https://www.googleapis.com/auth/")]
        if odd:
            problems.append("SUPER_SCOPES holds values that are not Google OAuth scopes: %s"
                            % ", ".join(odd))
        absent = [s for s in SCOPES_REQUIRED_IN_EVERY_CLIENT if s not in super_scopes]
        if absent:
            problems.append(
                "SUPER_SCOPES lacks %s; without them the consent cannot prove which "
                "account consented (SETUP.md 7.1)" % ", ".join(absent))
    # Added 2026-09-13: a gate key that names a file which does not exist is a
    # config error, not "gate not passed". Only an EMPTY value means the gate is
    # not passed (the spike gates refuse the same way).
    for key in ("SUPER_ADMIN_GRANT_DECISION", "SUPER_SCOPES_DECISION"):
        value = cfg.get(key, "")
        if value and not PLACEHOLDER_RE.search(value) and \
                not os.path.isfile(os.path.expanduser(value)):
            problems.append("%s (%r) does not name an existing file; leave it empty until "
                            "the signed record exists" % (key, value))
    roster = [a.strip() for a in cfg.get("SUPER_ADMIN_ROSTER", "").split(",") if a.strip()]
    if roster and not PLACEHOLDER_RE.search(cfg.get("SUPER_ADMIN_ROSTER", "")):
        eve = cfg.get("EVE_ROBOT", "").lower()
        if eve and eve in (a.lower() for a in roster):
            problems.append("SUPER_ADMIN_ROSTER lists EVE_ROBOT; Eve's robot is never a "
                            "super admin (platform HLD §4.6)")
        for address in roster:
            if domain and not address.lower().endswith("@" + domain.lower()):
                problems.append("SUPER_ADMIN_ROSTER entry %s is not in DOMAIN %s"
                                % (address, domain))
    sandbox = [a.strip() for a in cfg.get("SANDBOX_ACCOUNTS", "").split(",") if a.strip()]
    if sandbox and len(sandbox) < 3 and "SANDBOX_ACCOUNTS" in required:
        # Only a refusal for the subcommands that use it. A malformed value a
        # different subcommand needs must not block this one: that was the
        # all-or-nothing behaviour this scoping exists to remove.
        problems.append(
            "SANDBOX_ACCOUNTS needs at least three synthetic accounts "
            "(SETUP.md Phase 1 step 6)"
        )
    for key in ("SVC_OU", "PILOT_OU", "SANDBOX_OU"):
        value = cfg.get(key, "")
        if value and not value.startswith("/"):
            problems.append("%s must be an absolute OU path starting with /" % key)
    # Every value below lands inside the escaped --set-env-vars list, and gcloud
    # requires the delimiter to appear in NO value (gcloud topic escaping). The
    # old guard looked for "@" in DOMAIN and the OU paths — four values that by
    # construction never contain one — while the seven that always do (every
    # address and every service account) went unchecked, which is exactly how
    # the ^@^ delimiter shipped broken.
    for key in ENV_DELIMITED_CONFIG_KEYS:
        if ENV_DELIMITER in cfg.get(key, ""):
            problems.append(
                "%s contains %r, which is the Cloud Run env delimiter"
                % (key, ENV_DELIMITER)
            )
    # Phases 12b, 12c, 13b. A wrong identity mode deploys an engine whose
    # identity can never be changed in place, so it is refused up front.
    mode = cfg.get("AGENT_IDENTITY_MODE", "")
    if mode and mode not in AGENT_IDENTITY_MODES:
        problems.append(
            "AGENT_IDENTITY_MODE must be one of %s, not %r"
            % ("/".join(AGENT_IDENTITY_MODES), mode)
        )
    retention = cfg.get("CONTENT_LOG_RETENTION_DAYS", "")
    if retention and not retention.isdigit():
        problems.append("CONTENT_LOG_RETENTION_DAYS must be a number of days, not %r"
                        % retention)
    folder = cfg.get("FOLDER_ID", "")
    if folder and "FOLDER_ID" in required and not folder.isdigit():
        problems.append("FOLDER_ID must be the numeric folder id, not %r" % folder)
    parent = cfg.get("WALLE_FOLDER_ID", "")
    if parent and "WALLE_FOLDER_ID" in required:
        if not parent.isdigit():
            problems.append("WALLE_FOLDER_ID must be the numeric folder id, not %r" % parent)
        elif parent == folder:
            problems.append(
                "WALLE_FOLDER_ID equals FOLDER_ID: Wall-E's project would sit directly under "
                "the platform folder and inherit none of the P-SA tier's policies. Set it to "
                "the id of fld-agents-p-sa-prod (agentic-platform/02 section 2)")
    ci = cfg.get("CI_DEPLOYER", "")
    if ci and "CI_DEPLOYER" in required and "@" not in ci:
        problems.append("CI_DEPLOYER must be a service account email, not %r" % ci)
    # Four projects, four distinct ids (project-topology.md §2). Two keys
    # naming the same project would silently put an Eve or Mo grant back
    # inside Wall-E's project, which is the placement this topology removes.
    named = [(k, cfg.get(k, "")) for k in ("PROJECT", "GEMINI_PROJECT", "EVE_PROJECT",
                                            "MO_PROJECT")]
    seen: Dict[str, str] = {}
    for key, value in named:
        if not value or PLACEHOLDER_RE.search(value):
            continue
        if value in seen:
            problems.append(
                "%s and %s are both %r. The Gemini app, Wall-E, Eve and Mo each "
                "live in their own project (project-topology.md)." % (seen[value], key, value)
            )
        seen.setdefault(value, key)
    gemini_number = cfg.get("GEMINI_PROJECT_NUMBER", "")
    if gemini_number and not gemini_number.isdigit():
        problems.append("GEMINI_PROJECT_NUMBER must be the numeric project number, not %r"
                        % gemini_number)
    # A copy-paste of Wall-E's own number reproduces exactly the pre-change
    # failure: an engine policy naming service-<WALLE number>@gcp-sa-
    # discoveryengine, a principal that never calls (project-topology.md §6).
    if gemini_number and cfg.get("PROJECT_NUMBER") and gemini_number == cfg["PROJECT_NUMBER"]:
        problems.append(
            "GEMINI_PROJECT_NUMBER equals PROJECT_NUMBER; the app's number is the Gemini "
            "project's, never Wall-E's"
        )
    # Every foreign identity lives in its own project. The example config
    # exports SA_EVE, SA_EVE_VERIFIER, SA_EVE_CONSOLE and SA_EVE_V0 explicitly
    # and derive_config's setdefault does not override them, so an operator
    # who edits one to eve-*@${PROJECT} (the old placement) would otherwise
    # pass validation and Phase 7 / Phase 10 would write that address into a
    # dataset access array and a run.invoker binding. Refuse it up front, the
    # way MO_PRINCIPAL is refused; verify's project_roles / control_caller
    # checks stay as the second line.
    project = cfg.get("PROJECT", "")
    eve_project = cfg.get("EVE_PROJECT", "")
    mo_project = cfg.get("MO_PROJECT", "")
    homes = {
        "SA_EVE_V0": ("EVE_PROJECT", eve_project), "SA_EVE": ("EVE_PROJECT", eve_project),
        "SA_EVE_VERIFIER": ("EVE_PROJECT", eve_project),
        "SA_EVE_CONSOLE": ("EVE_PROJECT", eve_project),
        "SA_MO_METRICS": ("MO_PROJECT", mo_project), "SA_MO_ANALYST": ("MO_PROJECT", mo_project),
        "SA_MO_NARRATOR": ("MO_PROJECT", mo_project),
        "MO_PRINCIPAL": ("MO_PROJECT", mo_project),
    }
    for key, (home_key, home) in homes.items():
        value = cfg.get(key, "")
        if not value or PLACEHOLDER_RE.search(value):
            continue
        email = value.split(":", 1)[-1]
        if project and email.endswith("@%s.iam.gserviceaccount.com" % project):
            problems.append(
                "%s (%s) is spelled in Wall-E's own project %s; Eve's and Mo's identities "
                "live in EVE_PROJECT / MO_PROJECT and appear here as grantees only "
                "(project-topology.md §6)" % (key, email, project)
            )
        elif home and not email.endswith("@%s.iam.gserviceaccount.com" % home):
            problems.append(
                "%s (%s) is not a service account in %s %s; it must be "
                "<account>@%s.iam.gserviceaccount.com" % (key, email, home_key, home, home)
            )
    return problems


# --------------------------------------------------------------------------- #
# Context and the command runner
# --------------------------------------------------------------------------- #


class Result:
    """A finished subprocess. Never carries a secret: callers pass those on stdin."""

    def __init__(self, code: int, out: str, err: str) -> None:
        self.code = code
        self.out = out
        self.err = err

    @property
    def ok(self) -> bool:
        return self.code == 0


class Ctx:
    def __init__(self, cfg: Dict[str, str], args: argparse.Namespace) -> None:
        self.cfg = cfg
        self.dry_run: bool = bool(getattr(args, "dry_run", False))
        self.yes: bool = bool(getattr(args, "yes", False))
        self.verbose: bool = bool(getattr(args, "verbose", False))
        self.args = args
        self._admin: Optional[Any] = None
        self._settings: Optional[Any] = None
        self._creds: Optional[Any] = None
        self._notes: List[str] = []
        # Policy files and YAML that gcloud takes by path. Never a secret.
        self._scratch_dir: Optional[str] = None

    def scratch_file(self, name: str, text: str) -> str:
        """Write a non-secret file gcloud will read by path; return the path.

        Lives in a per-run temporary directory, so a --dry-run can still show
        the exact command it would issue, file argument included.
        """
        if self._scratch_dir is None:
            self._scratch_dir = tempfile.mkdtemp(prefix="walle-")
        path = os.path.join(self._scratch_dir, name)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(text)
        return path

    def get(self, key: str, default: str = "") -> str:
        return self.cfg.get(key, default)

    def need(self, key: str) -> str:
        value = self.cfg.get(key, "")
        if not value:
            die(
                "%s is not set. It is produced by an earlier phase; re-source your "
                "config after that phase, or fill it in." % key
            )
        return value

    def note(self, text: str) -> None:
        self._notes.append(text)

    def print_notes(self) -> None:
        if not self._notes:
            return
        section("Notes to carry into the build log")
        for line in self._notes:
            say("  - " + line)


def run(
    ctx: Ctx,
    argv: Sequence[str],
    mutating: bool = True,
    check: bool = True,
    stdin_data: Optional[bytes] = None,
    stdin_is_secret: bool = False,
    stdout_is_secret: bool = False,
    env: Optional[Dict[str, str]] = None,
) -> Result:
    """Run one command. Never uses a shell, so nothing needs quoting.

    Reads still execute under --dry-run: they change nothing and their output is
    what makes the dry run informative. Mutations print and stop.

    stdout_is_secret is not cosmetic. Without it, --verbose echoes the child's
    stdout, so `walle verify --verbose` and `walle consent --verbose` print the
    base64 refresh token and the OAuth client secret to the terminal and into
    any captured build log — the one value the whole no-DWD design exists to
    bound. It also keeps that stdout out of the WalleError text on failure.
    """
    printable = shlex.join(list(argv))
    if stdin_data is not None:
        printable += " < %s" % ("<secret, redacted>" if stdin_is_secret else "<stdin>")
    if mutating or ctx.verbose or ctx.dry_run:
        prefix = "WOULD RUN: " if (mutating and ctx.dry_run) else "RUN: "
        say("  " + prefix + printable)
    if mutating and ctx.dry_run:
        return Result(0, "", "")

    full_env = dict(os.environ)
    if env:
        full_env.update(env)
    try:
        proc = subprocess.run(
            list(argv),
            input=stdin_data,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=full_env,
        )
    except OSError as exc:
        raise WalleError(
            "cannot run %r: %s\nRun 'walle preflight' first: it checks every tool "
            "this script shells out to." % (argv[0], exc)
        )
    out = proc.stdout.decode("utf-8", "replace")
    err = proc.stderr.decode("utf-8", "replace")
    result = Result(proc.returncode, out, err)
    if ctx.verbose and out.strip():
        if stdout_is_secret:
            say("      | <secret payload, %d bytes, redacted>" % len(out))
        else:
            for line in out.strip().splitlines()[:40]:
                say("      | " + line)
    if check and not result.ok:
        raise WalleError(
            "command failed (exit %d): %s\n--- stdout ---\n%s\n--- stderr ---\n%s"
            % (
                result.code,
                printable,
                "<redacted>" if stdout_is_secret else out.strip(),
                err.strip(),
            )
        )
    return result


def read_only_run(ctx: Ctx, argv: Sequence[str], **kwargs: Any) -> Result:
    """A read whose stdout is a secret and must never reach a log.

    Separate from run() so no future caller can forget the flag: everything
    that reads a credential goes through here.
    """
    kwargs.setdefault("check", True)
    return run(ctx, argv, mutating=False, stdout_is_secret=True, **kwargs)


def probe(ctx: Ctx, argv: Sequence[str]) -> Result:
    """A read whose failure is information, not an error. Used by get-or-create."""
    return run(ctx, argv, mutating=False, check=False)


def gcloud(ctx: Ctx, *argv: str, **kwargs: Any) -> Result:
    project = ctx.get("PROJECT")
    args = ["gcloud"] + list(argv)
    if project and "--project" not in argv and not _has_scope_flag(argv):
        args += ["--project", project]
    return run(ctx, args, **kwargs)


def _has_scope_flag(argv: Sequence[str]) -> bool:
    """Org- and billing-scoped commands reject --project."""
    for token in argv:
        if token.startswith("--organization") or token.startswith("--billing-account"):
            return True
        if token.startswith("--folder"):
            return True
    return False


ABSENT_MARKERS: Tuple[str, ...] = (
    "not found",
    "notfound",
    "not_found",
    "does not exist",
    "cannot find",
    "no such",
    "was not found",
)


def gcloud_probe_json(ctx: Ctx, *argv: str) -> Optional[Any]:
    """None means 'does not exist'. Any other failure is raised, not swallowed."""
    args = ["gcloud"] + list(argv) + ["--format=json"]
    if ctx.get("PROJECT") and "--project" not in argv and not _has_scope_flag(argv):
        args += ["--project", ctx.get("PROJECT")]
    result = probe(ctx, args)
    if result.ok:
        text = result.out.strip()
        return json.loads(text) if text else None
    lowered = (result.err or "").lower()
    if any(marker in lowered for marker in ABSENT_MARKERS):
        return None
    if "permission" in lowered or "denied" in lowered or "forbidden" in lowered:
        raise WalleError(
            "permission denied reading %s\n%s" % (" ".join(argv), result.err.strip())
        )
    raise WalleError("unexpected error reading %s\n%s" % (" ".join(argv), result.err.strip()))


def gcloud_probe_json_in(ctx: Ctx, project_id: str, *argv: str) -> Optional[Any]:
    """gcloud_probe_json against ANOTHER project, named explicitly.

    gcloud() and gcloud_probe_json() append --project PROJECT (Wall-E's) to
    every call that carries no scope flag. A read of Eve's key policy, Eve's
    secrets or the Gemini project's number issued through them would silently
    land in Wall-E's project and answer "does not exist". Every cross-project
    read goes through here, and the self-test asserts that no command naming
    a resource of another project carries Wall-E's project id.
    """
    if not project_id:
        die("a cross-project read was attempted with no project id (%s)" % " ".join(argv))
    if project_id == ctx.get("PROJECT"):
        die("gcloud_probe_json_in was called with Wall-E's own project for %s" % " ".join(argv))
    return gcloud_probe_json(ctx, *(list(argv) + ["--project", project_id]))


def confirm(ctx: Ctx, question: str) -> None:
    """Blocks. --yes skips it; a non-interactive shell without --yes is a refusal.

    Under --dry-run this prints and returns, and that is only safe because
    nothing after it may mutate: every mutation is gated separately, either by
    run(mutating=True) returning early, by api_mutate, or by refuse_in_dry_run
    at the few places that call an SDK write directly. A confirm() that
    auto-returns is not permission to perform a write.
    """
    if ctx.dry_run:
        say("  [confirm] %s -> dry run, and nothing past here may mutate" % question)
        return
    if ctx.yes:
        say("  [confirm] %s -> auto-yes" % question)
        return
    if not _is_tty():
        die("%s\nNo terminal to ask on, and --yes was not given." % question)
    answer = input("  %s [y/N] " % question).strip().lower()
    if answer not in ("y", "yes"):
        die("refused by operator")


def confirm_manual(ctx: Ctx, ident: str, what: str) -> None:
    """Attest a step a HUMAN performed in a console. --yes cannot satisfy this.

    --yes exists to skip confirmations on writes this script makes. It must
    never assert that somebody created a reporting rule, registered a security
    key or marked an OAuth client Trusted. SETUP.md Phase 4 calls the login
    rule "the highest-value single control in the whole design", and section
    7.2 says an untrusted client dies weeks later with an error that looks
    nothing like the cause.
    """
    if ctx.dry_run:
        say("  [dry run] would BLOCK here until %s is confirmed by a human" % ident)
        return
    if not _is_tty():
        die(
            "%s is a console step performed by a person, and there is no terminal "
            "to confirm it on. --yes does not cover manual steps: it would record "
            "'%s' as attested when nobody opened the console. Re-run this "
            "subcommand from a terminal." % (ident, what)
        )
    answer = input("  Type %s to confirm you have done it: " % ident).strip().upper()
    if answer != ident.upper():
        die("%s not confirmed. Nothing beyond this point is safe to run." % ident)


def refuse_in_dry_run(ctx: Ctx, what: str) -> bool:
    """True when a caller that is about to write for real must stand down.

    Used by the handful of places that call a Google SDK directly instead of
    going through run() or api_mutate, where nothing else would stop them.
    """
    if ctx.dry_run:
        say("  [dry run] NOT doing: %s" % what)
        return True
    return False


# --------------------------------------------------------------------------- #
# Manual steps. Each one blocks, and is verified afterwards where an API can
# see the result. The phase numbers are SETUP.md's.
# --------------------------------------------------------------------------- #


class ManualStep:
    def __init__(
        self,
        ident: str,
        phase: str,
        title: str,
        why: str,
        lines: Sequence[str],
        verifier: Optional[str] = None,
        subcommand: str = "",
    ) -> None:
        self.ident = ident
        self.phase = phase
        self.title = title
        self.why = why
        self.lines = list(lines)
        self.verifier = verifier
        self.subcommand = subcommand


def manual_steps(ctx: Ctx) -> List[ManualStep]:
    def c(key: str, default: str = "") -> str:
        """An unset key and a key set to "" are the same thing here."""
        return ctx.cfg.get(key) or default
    return [
        ManualStep(
            "M0",
            "Phase 0 (addition)",
            "Create an OAuth client for this setup tool",
            "SETUP.md does phases 1 and 2 by hand in the console, so it never needs "
            "one. This script uses the Admin SDK as you, which needs a client. It "
            "must NOT be the robot's client: one client, one token (SETUP.md 7.4).",
            [
                "GCP console -> APIs & Services -> OAuth consent screen: Internal, In production.",
                "Credentials -> Create credentials -> OAuth client ID -> Desktop app.",
                "Name it something like 'wall-e setup tool (operator)'.",
                "Download the JSON and put its path in OPERATOR_OAUTH_CLIENT_FILE.",
                "This client is yours, not the robot's. Never reuse it for Phase 9.",
            ],
            verifier="verify_operator_client_file",
            subcommand="workspace",
        ),
        ManualStep(
            "M1",
            "Phase 1 steps 2 and 6",
            "Set the password on every account this script creates, and vault it",
            "Rule: this script never prints or writes a secret. It creates each "
            "account with a random password it immediately forgets, so the real "
            "password is set once, in the console, and goes straight to the vault.",
            [
                "Admin console -> Directory -> Users -> %s -> Reset password." % c("ROBOT", ""),
                "Generate a long random password. Copy it into the corporate vault.",
                "Untick 'Ask for a password change at the next sign-in'.",
                "Confirm there is NO recovery email and NO recovery phone on the account.",
                "Repeat for %s." % c("EVE_ROBOT", ""),
                "Sandbox accounts: any password, they are synthetic. Vault not required.",
                "Never rotate the robot's password casually after Phase 9: with Gmail "
                "scopes granted, a password change invalidates the refresh token.",
            ],
            verifier="verify_no_recovery_contacts",
            subcommand="workspace",
        ),
        ManualStep(
            "M2A",
            "Phase 3 (first half)",
            "Register the security keys — do NOT enforce 2SV yet",
            "Enforcing hardware-key-only on an account with no key registered locks "
            "the account out permanently: by then the recovery email, the recovery "
            "phone and the code fallbacks are all gone, and the recovery path costs "
            "a full Phase 9 re-bootstrap. Splitting the step is the only way the "
            "ordering can be enforced by machine: this half is verified before the "
            "second half is even printed.",
            [
                "In the clean browser profile, sign in as %s." % c("ROBOT", ""),
                "Register TWO physical security keys on the account. Label them, "
                "record who has access, and put both in the safe.",
                "Repeat for %s with its own key." % c("EVE_ROBOT", ""),
                "Do NOT touch the 2-step verification enforcement setting yet.",
            ],
            verifier="verify_2sv_enrolled",
            subcommand="workspace",
        ),
        ManualStep(
            "M2B",
            "Phase 3 (second half)",
            "Now enforce 2SV, security key only, scoped to the service OU",
            "Only reachable once M2A verified that a key is actually enrolled on "
            "both robots.",
            [
                "Admin console -> Security -> Authentication -> 2-step verification, "
                "scoped to %s." % c("SVC_OU", ""),
                "Enforcement: ON. Methods: security key only. No 'allow codes'. This is "
                "the TENANT's policy on the robot OU: Google's own admin-2SV mandate is "
                "a gradual, edition-scoped rollout, not a universal rule (platform HLD "
                "§4.6, corrected 2026-09-13).",
                "Same OU: less secure app access OFF; Google session control and Google "
                "Cloud session control at 1 hour with security-key re-authentication, "
                "no 'remember this device'; login challenges at the strictest setting. "
                "The Admin console session itself is Google's fixed one hour and is not "
                "a setting.",
                "Super-admin self-recovery: OFF at the TOP organisational unit (it is set "
                "per OU or configuration group and defaults to On for Enterprise "
                "Standard/Plus), and confirm no child OU or configuration group turns it "
                "back on (platform HLD §13.1 item 6).",
                "Reversed 2026-09-13: this step used to say 'Confirm %s is NOT a super "
                "admin.' The robot WILL be one, but NOT here: Super Admin is granted "
                "only at the platform's tier gate, as M2C, after this hardening is "
                "verified. Until then it must hold no admin role at all." % c("ROBOT", ""),
                "Sign out, sign back in, and confirm you are forced through the key. "
                "If a code fallback is offered, enforcement is wrong for this OU.",
                "Repeat the sign-out check for %s, which is never a super admin."
                % c("EVE_ROBOT", ""),
            ],
            verifier="verify_2sv_enforced",
            subcommand="workspace",
        ),
        ManualStep(
            "M2C",
            "Tier gate (platform HLD §0.4), added 2026-09-13",
            "Grant Super Admin to the robot — at the tier gate, by a human, never by this script",
            "The objective gives Wall-E a licensed user account with Super Admin "
            "(decision P33). Super Admin cannot be limited to an OU or subset by "
            "privilege, so the grant is a gate with its own checklist, not a runbook "
            "phase. users.makeAdmin and any Super Admin roleAssignments.insert are on "
            "the hard-denied list, so the robot's own credential can never do it, and "
            "this script refuses to: it only prints this block, blocks, and verifies.",
            [
                "PRECONDITIONS, every one, or stop here: the signed record at "
                "SUPER_ADMIN_GRANT_DECISION (%s) — decision P33, the TISAX deviation and "
                "row one of the risk register; every row of the platform's P line green "
                "(Eve's observe-and-report layer live and drilled, the witness "
                "organisation, the SIEM with 24x7 acknowledgement, the penetration test, "
                "the DPIA started, the works-council information, the two lists signed "
                "(P29), the perimeter decision); the second human outside the Wall-E "
                "administration line named." % c("SUPER_ADMIN_GRANT_DECISION", "<unset>"),
                "The roster: at least TWO human super admins on separate admin accounts "
                "with hardware keys, one of them outside the Wall-E line; the robot is "
                "never the only super admin and never the recovery super admin of "
                "anyone. SUPER_ADMIN_ROSTER must already hold the exact committed roster "
                "INCLUDING %s, committed and exported BEFORE 'walle workspace' was run on "
                "gate day: the config is read once at start, so an edit made while this "
                "step blocks is not seen (platform 04 §8.1, P68)." % c("ROBOT", ""),
                "Workspace multi-party approval ON for every covered setting, console "
                "and API, before the grant (P66); the robot is never an approver.",
                "Super-admin self-recovery OFF at the top OU (M2B), no recovery channels "
                "on %s (M1), 2SV enforced (M2B), the login reporting rule live (M3)."
                % c("ROBOT", ""),
                "As one human super admin: Admin console -> Directory -> Users -> %s -> "
                "Admin roles and privileges -> assign Super Admin. A DIFFERENT human "
                "super admin approves it under multi-party approval. (Console labels "
                "may differ by edition.)" % c("ROBOT", ""),
                "Both humans and the time go into the P33 record. The robot's grant is "
                "a role change on the roster: Eve's roster check and the SIEM set page "
                "on it by design; tell the second human before you do it.",
                "The reverse is K6: a human super admin removes Super Admin from the "
                "robot. Neither direction is ever done by a machine.",
            ],
            verifier="verify_super_admin_grant",
            subcommand="workspace",
        ),
        ManualStep(
            "M3",
            "Phase 4",
            "The login reporting rule, under Rules (not Alert Center)",
            "After Phase 9 an interactive login to the robot is by definition an "
            "incident. This is the highest-value single control in the design, and "
            "nothing else detects that directly. The Alert Center API needs "
            "domain-wide delegation, which this design does not do.",
            [
                "Admin console -> Rules -> Create rule -> Reporting rule.",
                "Data source: Login audit log.",
                "Condition: Actor (user email) is %s." % c("ROBOT", ""),
                "Leave the event type unfiltered: failed logins matter as much.",
                "Actions: email you and %s. Severity: high." % c("OPERATORS", ""),
                "Name: 'Wall-E robot interactive login'.",
                "Create a second, identical rule with actor %s." % c("EVE_ROBOT", ""),
                "Then sign in once as the robot and record how long the alert took. "
                "Do not conclude it is broken until 24 hours have passed.",
                "If the edition has no reporting rules, the fallback is a log-based "
                "metric on login.googleapis.com plus principalEmail, over Phase 5 data.",
            ],
            verifier=None,
            subcommand="workspace",
        ),
        ManualStep(
            "M4",
            "Phase 5",
            "Share Workspace audit data with Google Cloud services",
            "This replaces the Alert Center API, needs no credential, and is written "
            "by Google rather than by Wall-E. That independence is what makes Eve's "
            "later verification worth anything.",
            [
                "FIRST: check whether it is already on. If it is, do not touch it. "
                "Note who enabled it and when, and skip to the check below.",
                "If it is off, confirm with whoever owns org-level Cloud Logging "
                "whether _Default excludes these logs. Turning this on adds "
                "organisation-wide admin activity to ingestion: the largest single "
                "cost line in this build.",
                "Admin console -> Account -> Account settings -> Legal and compliance "
                "-> enable 'Share data with Google Cloud services'.",
                "Record the date, and that Wall-E now depends on it.",
                "Wait up to 24 hours. Then check BOTH log types at ORGANISATION scope "
                "in Logs Explorer: admin.googleapis.com and login.googleapis.com.",
                "Residency note for the DPIA: these logs land at organisation level "
                "and their storage region is not selectable. Knowingly accepted.",
            ],
            verifier="verify_workspace_log_sharing",
            # Prompted by `walle workspace`, not `walle deploy`: SETUP.md puts
            # Phase 5 before Phase 6, the toggle takes up to 24h to produce
            # rows, and the login half must be resolved before Phase 9. Asking
            # for it at deploy time starts the clock on day three and lets a
            # not-yet-visible log abort a half-configured action service.
            subcommand="workspace",
        ),
        ManualStep(
            "M5",
            "Phase 9 steps 1 and 2",
            "The consent screen and the robot's OAuth client (client 1, narrow)",
            "External + Testing expires refresh tokens after seven days. The app name "
            "is shown to the robot on the consent screen and is awkward to change.",
            [
                "GCP console -> APIs & Services -> OAuth consent screen.",
                "User type: Internal. Publishing status: In production. Set BOTH.",
                "App name: the name decided in D1. Support and developer contact: you.",
                "Credentials -> Create credentials -> OAuth client ID -> Desktop app.",
                "Download the JSON to a path you will pass to 'walle consent "
                "--store-client PATH'. That command stores it in Secret Manager and "
                "then shreds the local copy.",
                "Eve's client is created in EVE_PROJECT (%s) by Eve's runbook, on that "
                "project's own consent screen; never reuse this one. More than 100 "
                "live tokens for one client makes Google invalidate the oldest silently."
                % c("EVE_PROJECT", "<EVE_PROJECT>"),
                "Since 2026-09-13 there is a SECOND client on the same robot account "
                "(M5S, 'walle consent --super'). Two clients, two tokens, never one "
                "client reused for both.",
            ],
            verifier=None,
            subcommand="consent",
        ),
        ManualStep(
            "M5S",
            "Phase 9, band B (added 2026-09-13)",
            "The robot's SECOND OAuth client (client 2, broad), for walle-actions-super",
            "Decision 18 forced to now: the narrow client's scopes are the only "
            "Google-enforced ceiling left on unattended work, so the broad scopes "
            "must live in a separate client read by a separate service (platform HLD "
            "§13.1 item 3). Consented in the same sitting, on the same hardware key.",
            [
                "SUPER_SCOPES_DECISION must name the signed record of the broad scope "
                "list (decision 3 re-cut); SUPER_SCOPES must be exactly that list. "
                "cloud-platform in any form is refused.",
                "Same consent screen as M5 (Internal, In production). Credentials -> "
                "Create credentials -> OAuth client ID -> Desktop app, a NEW client.",
                "Download the JSON and pass it to 'walle consent --super --store-client "
                "PATH': it goes into walle-super-oauth-client, readable by "
                "walle-actions-super@ only, and the local copy is shredded.",
                "Mark THIS client Trusted too (M6), in the same sitting.",
                "Adding a scope later is a re-consent of client 2 only.",
            ],
            verifier=None,
            subcommand="consent",
        ),
        ManualStep(
            "M6",
            "Phase 9 step 4",
            "Mark the OAuth client Trusted, in the same sitting",
            "The Gmail scopes are 'restricted'. An Internal app needs no Google "
            "verification, but your tenant's own API controls can still cut it off, and the "
            "failure arrives weeks later looking nothing like the cause.",
            [
                "Admin console -> Security -> Access and data control -> API controls",
                "-> App access control -> Manage third-party app access",
                "-> Configure new app -> OAuth App Name Or Client ID",
                "-> paste the client ID -> Trusted.",
                "Do this now, not later. It takes two minutes.",
            ],
            verifier=None,
            subcommand="consent",
        ),
        ManualStep(
            "M7",
            "Phase 9 step 5",
            "The one interactive consent, as the robot, in a clean profile",
            "The script drives this but must never open a browser. A desktop OAuth "
            "flow opens the machine's default browser, which is signed in as you, a "
            "super admin, and the grant is then stored against your account: every "
            "robot action would then be attributed to you and invisible to the "
            "robot-attributed detection Eve and the SIEM run. SETUP.md 7.1.",
            [
                "Have ready: the clean browser profile signed into nothing, the vault "
                "password for the robot, and the hardware key from the safe.",
                "This script prints a URL and waits. Copy it BY HAND into the clean "
                "profile. Do not click it, do not let a terminal open it.",
                "Complete the consent as the robot account.",
                "The script checks, through userinfo, that the account that consented "
                "really is the robot, and refuses to store the token otherwise.",
                "Write down the secret VERSION NUMBER it prints. It is 1 only on a "
                "first clean bootstrap. Export it as REFRESH_TOKEN_VERSION (client 1) "
                "or SUPER_REFRESH_TOKEN_VERSION (client 2, --super) and put it in the "
                "config before deploying.",
                "Then sign out and close the clean profile. You are done signing in as "
                "the robot forever: from now on a login alert is an incident.",
            ],
            verifier=None,
            subcommand="consent",
        ),
        ManualStep(
            "M8",
            "Phase 13",
            "Register Wall-E in Gemini Enterprise and share it",
            "Gemini Enterprise is the human front door: it authenticates the user "
            "through Workspace SSO and passes their email to the agent.",
            [
                "The app is in GEMINI_PROJECT (%s): open THAT project's Gemini "
                "Enterprise console, not Wall-E's." % c("GEMINI_PROJECT", "<GEMINI_PROJECT>"),
                "Before registering, the app's service agent service-%s@gcp-sa-"
                "discoveryengine.iam.gserviceaccount.com must already hold "
                "walleEngineQuery on the engine ('walle deploy', Phase 12 lock-down), "
                "or the documented project-level fallback if the spike failed "
                "(project-topology.md decision 42)."
                % c("GEMINI_PROJECT_NUMBER", "<GEMINI_PROJECT_NUMBER>"),
                "Gemini Enterprise console -> your app -> Agents -> Add agent",
                "-> Custom agent via Agent Runtime.",
                "Display name: Wall-E",
                "Resource path (Wall-E's project, not the app's): "
                "projects/%s/locations/%s/reasoningEngines/%s"
                % (c("PROJECT", ""), c("REGION", ""), c("ENGINE_ID", "<engine-id>")),
                "Description (this is a ROUTING PROMPT, not documentation; paste it "
                "exactly): " + GEMINI_ROUTING_DESCRIPTION,
                "Do NOT attach a data store. Wall-E's data comes from the action "
                "service, live. A data store is a second, stale, unaudited source.",
                "User permissions tab -> share with %s ONLY." % c("OPERATORS", ""),
                "Do not share with %s yet: that is a separate deliberate act."
                % c("READERS", ""),
                "Re-confirm the app's location matches what D8 recorded: an 'eu' app "
                "fronts europe-* agents, a 'global' app any region, a 'us' app "
                "cannot front a europe-west1 agent.",
            ],
            verifier="verify_gemini_registration",
            subcommand="register",
        ),
        ManualStep(
            "M9",
            "Phase 16",
            "A monitoring notification channel must exist",
            "An alert policy with no channel is a dashboard, not an alert.",
            [
                "GCP console -> Monitoring -> Alerting -> Edit notification channels.",
                "Create an email channel for you and for %s." % c("OPERATORS", ""),
                "This script reads the channel list and refuses to create the Gmail "
                "watch alert if there is none.",
            ],
            verifier="verify_notification_channel",
            subcommand="triggers",
        ),
        ManualStep(
            "M10",
            "Phase 18",
            "Write the Stage 0 decision record, then resume the schedules",
            "The ladder config is deployed at Phase 14 with decision: pending, "
            "because the decision record does not exist until Stage 0 entry.",
            [
                "Write wiki/decisions/<date>-walle-stage-0.md, referencing SETUP.md, "
                "and commit it.",
                "Set decision: in config/ladder.yaml to that real path.",
                "Bump version: to 2026.09.0-2, commit, and redeploy the ladder.",
                "Re-check GET /v1/ladder: config_version must now read 2026.09.0-2.",
                "Only then resume the playbook schedules, one at a time.",
                "`walle stage0` runs the resume half once every box in SETUP.md 6.1 "
                "is ticked.",
            ],
            verifier=None,
            # Printed by `walle verify`, which is where an operator arrives with
            # every invariant green and the schedules still deliberately paused,
            # and gated by `walle stage0`.
            subcommand="verify",
        ),
    ]


def print_manual_steps(ctx: Ctx, only: Optional[str] = None) -> None:
    steps = [s for s in manual_steps(ctx) if not only or s.subcommand == only]
    section("Manual console steps (%s)" % (only or "all phases"))
    for item in steps:
        say("")
        say("%s  %s — %s" % (item.ident, item.phase, item.title))
        say("    why: " + item.why)
        for line in item.lines:
            say("      " + line)
        if item.verifier:
            say("    afterwards: this script verifies it (%s)" % item.verifier)
        else:
            say("    afterwards: NOT verifiable through any API. Check it by eye.")


def do_manual_step(ctx: Ctx, ident: str) -> None:
    """Print the block, block, then verify. A failed verification stops the run."""
    matches = [s for s in manual_steps(ctx) if s.ident == ident]
    if not matches:
        die("unknown manual step %s" % ident)
    item = matches[0]
    section("MANUAL — %s  %s — %s" % (item.ident, item.phase, item.title))
    say("  why: " + item.why)
    say("")
    for line in item.lines:
        say("    " + line)
    say("")
    # NOT confirm(): --yes must never attest that a human opened a console.
    # M3, M5 and M6 have no verifier at all, so this block is the only thing
    # standing between "--yes" and a build log that records work nobody did.
    confirm_manual(ctx, item.ident, item.title)
    if not item.verifier:
        warn("%s cannot be verified through any API. Recorded as operator-attested." % ident)
        ctx.note("%s attested by operator, not machine-verified." % ident)
        return
    if ctx.dry_run:
        say("  [dry run] would verify with %s" % item.verifier)
        return
    verifier = globals()[item.verifier]
    status, detail = verifier(ctx)
    if status == "PASS":
        say("  verified: " + detail)
    elif status == "SKIP":
        warn("could not verify %s: %s" % (ident, detail))
        ctx.note("%s could not be verified: %s" % (ident, detail))
    else:
        die("%s says it is done, but verification failed: %s" % (ident, detail))


# --------------------------------------------------------------------------- #
# Admin SDK, as the operator. Not domain-wide delegation, and never the robot.
# --------------------------------------------------------------------------- #


def _import_google() -> Tuple[Any, Any, Any, Any]:
    try:
        from google.auth.transport.requests import Request  # noqa: WPS433
        from google.oauth2.credentials import Credentials  # noqa: WPS433
        from google_auth_oauthlib.flow import InstalledAppFlow  # noqa: WPS433
        from googleapiclient.discovery import build  # noqa: WPS433
    except ImportError as exc:
        raise WalleError(
            "missing Python dependency: %s\nInstall with:\n"
            "  python3 -m venv .venv && .venv/bin/pip install -r requirements.txt\n"
            "or just use the ./walle wrapper, which does it for you." % exc
        )
    return Request, Credentials, InstalledAppFlow, build


def operator_credentials(ctx: Ctx) -> Any:
    """The operator's own super-admin consent, cached at 0600 on his machine.

    This opens a browser on purpose: the operator IS the account we want, and his
    default browser is the right one. The robot's consent in Phase 9 is the exact
    opposite case and must never do this.
    """
    if ctx._creds is not None:
        return ctx._creds
    Request, Credentials, InstalledAppFlow, _build = _import_google()
    cache = ctx.get("OPERATOR_TOKEN_CACHE")
    creds = None
    if cache and os.path.isfile(cache):
        creds = Credentials.from_authorized_user_file(cache, list(OPERATOR_SCOPES))
    if creds and creds.expired and creds.refresh_token:
        try:
            creds.refresh(Request())
        except Exception as exc:
            raise WalleError(
                "your cached operator consent could not be refreshed: %s\n"
                "Delete %s and re-run to consent again. This is YOUR credential, "
                "not Wall-E's: re-consenting costs nothing and freezes nothing."
                % (exc, cache)
            )
    if not creds or not creds.valid:
        client_file = os.path.expanduser(ctx.need("OPERATOR_OAUTH_CLIENT_FILE"))
        if not os.path.isfile(client_file):
            die(
                "OPERATOR_OAUTH_CLIENT_FILE does not exist: %s\nSee manual step M0."
                % client_file
            )
        flow = InstalledAppFlow.from_client_secrets_file(client_file, list(OPERATOR_SCOPES))
        say("")
        say("  Consent as YOURSELF (%s), a super admin." % ctx.get("OPERATOR_EMAIL"))
        say("  This is your own session. It is NOT the robot's Phase 9 consent.")
        creds = flow.run_local_server(port=0, open_browser=True, prompt="consent")
        if cache:
            _write_private_json(cache, json.loads(creds.to_json()))
    ctx._creds = creds
    return creds


def _write_private_json(path: str, payload: Dict[str, Any]) -> None:
    """0600, and created 0600 rather than chmod-ed after the fact."""
    directory = os.path.dirname(path)
    if directory:
        os.makedirs(directory, mode=0o700, exist_ok=True)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(payload, handle)


def admin(ctx: Ctx) -> Any:
    if ctx._admin is None:
        _r, _c, _f, build = _import_google()
        ctx._admin = build(
            "admin", "directory_v1", credentials=operator_credentials(ctx),
            cache_discovery=False,
        )
    return ctx._admin


def group_settings(ctx: Ctx) -> Any:
    if ctx._settings is None:
        _r, _c, _f, build = _import_google()
        ctx._settings = build(
            "groupssettings", "v1", credentials=operator_credentials(ctx),
            cache_discovery=False,
        )
    return ctx._settings


def _http_status(exc: Exception) -> int:
    resp = getattr(exc, "resp", None)
    return int(getattr(resp, "status", 0) or 0)


def api_get(
    ctx: Ctx, description: str, request: Any, absent_on_403: bool = False
) -> Optional[Any]:
    """A read. Executes even under --dry-run. 404 means absent; 403 does NOT.

    Conflating the two is attack A7. The Directory API really does answer 403
    for an absent ORG UNIT, which is the case this ever needed, and callers
    that read an org unit pass absent_on_403=True. Everywhere else — users.get
    and groups.get inside collect_admins above all — a 403 means "this
    credential cannot resolve the principal", and swallowing it drops that
    admin from the floor list. A short floor list defeats the one assertion
    that exists to make a truncated enumeration loud.
    """
    if ctx.verbose or ctx.dry_run:
        say("  API GET: " + description)
    try:
        from googleapiclient.errors import HttpError  # noqa: WPS433
    except ImportError as exc:
        raise WalleError("google-api-python-client is not installed: %s" % exc)
    try:
        return request.execute()
    except HttpError as exc:
        status = _http_status(exc)
        if status == 404:
            return None
        if status == 403 and absent_on_403:
            if ctx.verbose:
                warn("403 on %s, treating as absent (caller opted in)" % description)
            return None
        raise WalleError("API read failed (%s): %s" % (description, exc))


def api_mutate(ctx: Ctx, summary: str, request_factory: Callable[[], Any]) -> Any:
    """Every mutating Workspace call comes through here: summary, confirm, run."""
    say("  WORKSPACE WRITE: " + summary)
    if ctx.dry_run:
        say("    [dry run] not executed")
        return {"id": "DRYRUN", "roleId": "DRYRUN", "email": "DRYRUN"}
    confirm(ctx, "Apply this Workspace change?")
    try:
        from googleapiclient.errors import HttpError  # noqa: WPS433
    except ImportError as exc:
        raise WalleError("google-api-python-client is not installed: %s" % exc)
    try:
        return request_factory().execute()
    except HttpError as exc:
        raise WalleError("Workspace write failed (%s): %s" % (summary, exc))


def paginate(ctx: Ctx, collection: Any, request: Any, key: str) -> List[Dict[str, Any]]:
    """Full pagination, always.

    SETUP.md 7.5: an earlier implementation paginated the admin enumeration with
    no continuation and silently returned a partial protected-principal set.
    Truncation here is worse than slowness.
    """
    items: List[Dict[str, Any]] = []
    guard = 0
    while request is not None:
        response = request.execute()
        items.extend(response.get(key, []) or [])
        request = collection.list_next(request, response)
        guard += 1
        if guard > 500:
            die("pagination did not terminate after 500 pages; refusing to guess")
    return items


# --------------------------------------------------------------------------- #
# Workspace get-or-create helpers
# --------------------------------------------------------------------------- #


def ensure_org_unit(ctx: Ctx, path: str) -> None:
    """Creates every missing level of the path, parents first."""
    parts = [p for p in path.strip("/").split("/") if p]
    for depth in range(1, len(parts) + 1):
        sub = "/".join(parts[:depth])
        existing = api_get(
            ctx,
            "orgunits.get %s" % sub,
            admin(ctx).orgunits().get(customerId=ctx.need("CUSTOMER_ID"), orgUnitPath=sub),
            # The Directory API answers 403, not 404, for an absent org unit.
            absent_on_403=True,
        )
        if existing:
            step("org unit exists: /%s" % sub)
            continue
        parent = "/" + "/".join(parts[: depth - 1]) if depth > 1 else "/"
        body = {"name": parts[depth - 1], "parentOrgUnitPath": parent}
        api_mutate(
            ctx,
            "create org unit /%s under %s" % (sub, parent),
            lambda b=body: admin(ctx).orgunits().insert(
                customerId=ctx.need("CUSTOMER_ID"), body=b
            ),
        )


def ensure_user(ctx: Ctx, email: str, given: str, family: str, ou_path: str) -> Dict[str, Any]:
    """Get-or-create. The password is random, never printed, never stored.

    The operator sets the real password once in the console and puts it straight
    into the vault (manual step M1). This script must never hold it.
    """
    existing = api_get(ctx, "users.get %s" % email, admin(ctx).users().get(userKey=email))
    if existing:
        step("user exists: %s (ou %s)" % (email, existing.get("orgUnitPath")))
        if existing.get("orgUnitPath") != ou_path:
            # Every Phase 3 hardening control — 2SV enforcement, session
            # length, less secure app access, login challenges — is scoped to
            # this OU. An account outside it would go on to hold Super Admin
            # (Wall-E, at the tier gate) or Eve's read role with none of that
            # hardening applied. check_robot_hardening catches it, but only
            # after the fact.
            die(
                "%s is in %s, not %s. Every Phase 3 hardening control is scoped to "
                "%s, so this account would hold its admin rights (Super Admin for "
                "the robot, since 2026-09-13) with no 2SV enforcement, no session "
                "limit and no login challenges. Move it in "
                "Admin console -> Directory -> Users and re-run; this script does "
                "not move existing accounts."
                % (email, existing.get("orgUnitPath"), ou_path, ou_path)
            )
        return existing
    import secrets as _secrets  # stdlib; local so the name cannot leak upward

    body = {
        "primaryEmail": email,
        "name": {"givenName": given, "familyName": family},
        "password": _secrets.token_urlsafe(48),
        "changePasswordAtNextLogin": False,
        "orgUnitPath": ou_path,
    }
    printable = dict(body)
    printable["password"] = "<random, not retained>"
    created = api_mutate(
        ctx,
        "create user %s in %s  body=%s" % (email, ou_path, json.dumps(printable)),
        lambda b=body: admin(ctx).users().insert(body=b),
    )
    ctx.note(
        "%s was created with a random password this script did not keep. Set it in "
        "the console and vault it (M1)." % email
    )
    return created


def ensure_group(ctx: Ctx, email: str, name: str, description: str) -> Dict[str, Any]:
    existing = api_get(ctx, "groups.get %s" % email, admin(ctx).groups().get(groupKey=email))
    if existing:
        step("group exists: %s" % email)
    else:
        body = {"email": email, "name": name, "description": description}
        existing = api_mutate(
            ctx,
            "create group %s (%s)" % (email, name),
            lambda b=body: admin(ctx).groups().insert(body=b),
        )
    ensure_group_settings(ctx, email)
    return existing


def ensure_group_settings(ctx: Ctx, email: str) -> None:
    """Admins-only join, members-only post. SETUP.md Phase 1 step 3.

    If the Groups Settings API is not reachable this raises a manual step rather
    than continuing: the access setting is the control, not a nicety.
    """
    desired = {
        "whoCanJoin": "INVITED_CAN_JOIN",
        "whoCanPostMessage": "ALL_MEMBERS_CAN_POST",
        "whoCanViewMembership": "ALL_MANAGERS_CAN_VIEW",
        "whoCanViewGroup": "ALL_MEMBERS_CAN_VIEW",
        "allowExternalMembers": "false",
        "whoCanDiscoverGroup": "ALL_IN_DOMAIN_CAN_DISCOVER",
    }
    if ctx.dry_run:
        say("  WORKSPACE WRITE: [dry run] group settings %s = %s" % (email, desired))
        return
    try:
        current = group_settings(ctx).groups().get(groupUniqueId=email).execute()
    except Exception as exc:  # the API may be disabled or the scope refused
        raise ManualStepRequired(
            "cannot read group settings for %s (%s).\n"
            "Set them by hand: Groups -> %s -> Access settings: only "
            "organisation admins can join, only members can post. Then re-run."
            % (email, exc, email)
        )
    delta = {k: v for k, v in desired.items() if str(current.get(k, "")).lower() != v.lower()}
    if not delta:
        step("group settings already correct: %s" % email)
        return
    say("  WORKSPACE WRITE: group settings %s -> %s" % (email, json.dumps(delta)))
    confirm(ctx, "Apply these group access settings?")
    group_settings(ctx).groups().patch(groupUniqueId=email, body=delta).execute()


def ensure_group_member(ctx: Ctx, group: str, member: str, role: str = "MEMBER") -> None:
    existing = api_get(
        ctx,
        "members.get %s in %s" % (member, group),
        admin(ctx).members().get(groupKey=group, memberKey=member),
    )
    if existing:
        return
    body = {"email": member, "role": role}
    api_mutate(
        ctx,
        "add %s to %s as %s" % (member, group, role),
        lambda b=body: admin(ctx).members().insert(groupKey=group, body=b),
    )


def list_privileges(ctx: Ctx) -> Dict[str, str]:
    """privilegeName -> serviceId, flattened over child privileges."""
    response = admin(ctx).privileges().list(customer=ctx.need("CUSTOMER_ID")).execute()
    flat: Dict[str, str] = {}

    def walk(items: Iterable[Dict[str, Any]]) -> None:
        for item in items or []:
            flat[item["privilegeName"]] = item["serviceId"]
            walk(item.get("childPrivileges", []))

    walk(response.get("items", []))
    return flat


def resolve_privileges(
    ctx: Ctx, catalogue: Dict[str, str],
    candidates: Sequence[Tuple[str, Sequence[str]]],
) -> List[Dict[str, str]]:
    """Names differ between editions, so resolve against the live catalogue."""
    resolved: List[Dict[str, str]] = []
    seen = set()
    for family, options in candidates:
        match = next((name for name in options if name in catalogue), None)
        if match is None:
            die(
                "no privilege in this tenant matches '%s'. Tried: %s\n"
                "Run 'walle dump-privileges' and pick the real name, then correct "
                "EVE_PRIVILEGE_CANDIDATES. SETUP.md Phase 2 step 4 warns that "
                "console labels do not match API names." % (family, ", ".join(options))
            )
        if match in seen:
            continue
        seen.add(match)
        resolved.append({"privilegeName": match, "serviceId": catalogue[match]})
    return resolved


def find_role(ctx: Ctx, title: str) -> Optional[Dict[str, Any]]:
    roles = admin(ctx).roles()
    request = roles.list(customer=ctx.need("CUSTOMER_ID"), maxResults=100)
    for role in paginate(ctx, roles, request, "items"):
        if role.get("roleName") == title:
            return role
    return None


def ensure_role(
    ctx: Ctx, title: str, description: str, privileges: List[Dict[str, str]]
) -> Dict[str, Any]:
    """Get-or-create. A role that already exists with DIFFERENT privileges is a
    refusal, not a warning.

    phase_2_roles assigns whatever comes back from here to Eve's robot,
    customer-scoped. (Until 2026-09-13 it also built the roles assigned to
    Wall-E's robot, whose privilege set was then the Workspace-side
    enforcement point; the robot holds Super Admin now and has no custom
    role.) For Eve the privilege set is still what keeps her read-only at
    Google's end, whatever Eve's own code does. A role somebody widened by hand, or an earlier
    draft created, or an attacker touched, must never be granted with a warning
    that scrolls past — and a role that is silently NARROWER than expected
    breaks the reports the runbook expects, which no write check would catch.
    """
    existing = find_role(ctx, title)
    if existing:
        have = {p["privilegeName"] for p in existing.get("rolePrivileges", [])}
        want = {p["privilegeName"] for p in privileges}
        if have != want:
            offenders = sorted(n for n in have if is_write_privilege(n))
            die(
                "role '%s' already exists with different privileges, and this "
                "script is about to assign it.\n"
                "    have:  %s\n"
                "    want:  %s\n"
                "    extra: %s\n"
                "    write-capable in the existing role: %s\n"
                "Reconcile it in Admin console -> Account -> Admin roles, or delete "
                "the role and re-run. This script will not rewrite an existing "
                "admin role."
                % (
                    title,
                    sorted(have),
                    sorted(want),
                    sorted(have - want),
                    offenders or "none",
                )
            )
        step("role exists with the expected privileges: %s" % title)
        return existing
    body = {
        "roleName": title,
        "roleDescription": description,
        "rolePrivileges": privileges,
    }
    return api_mutate(
        ctx,
        "create admin role '%s' with %d privileges: %s"
        % (title, len(privileges), ", ".join(sorted(p["privilegeName"] for p in privileges))),
        lambda b=body: admin(ctx).roles().insert(customer=ctx.need("CUSTOMER_ID"), body=b),
    )


def list_role_assignments(ctx: Ctx, role_id: Optional[str] = None) -> List[Dict[str, Any]]:
    collection = admin(ctx).roleAssignments()
    kwargs: Dict[str, Any] = {"customer": ctx.need("CUSTOMER_ID"), "maxResults": 200}
    if role_id:
        kwargs["roleId"] = role_id
    return paginate(ctx, collection, collection.list(**kwargs), "items")


def ensure_role_assignment(
    ctx: Ctx, role_id: str, user_id: str, scope: str = "CUSTOMER"
) -> None:
    """Customer-scoped, because an OU-scoped read role returns nothing.

    SETUP.md Phase 2 and adversarial finding A7: the admin enumeration under an
    OU-scoped role returns admins inside that OU only, often none, and an empty
    result reads as success. Since 2026-09-13 the only caller is Eve's role
    (Eve's assignment keeps this rule); the robot's Super Admin is never
    assigned by this script.
    """
    if role_id == "DRYRUN" or user_id == "DRYRUN":
        say("  [dry run] would assign role %s to %s, scope %s" % (role_id, user_id, scope))
        return
    for assignment in list_role_assignments(ctx, role_id):
        if assignment.get("assignedTo") == user_id:
            step("role assignment already present (scope %s)" % assignment.get("scopeType"))
            if assignment.get("scopeType") != scope:
                die(
                    "existing assignment is scoped %s, not %s. Delete it in the "
                    "console and re-run: scope is load-bearing here."
                    % (assignment.get("scopeType"), scope)
                )
            return
    body = {"roleId": role_id, "assignedTo": user_id, "scopeType": scope}
    api_mutate(
        ctx,
        "assign role %s to user id %s, scope %s" % (role_id, user_id, scope),
        lambda b=body: admin(ctx).roleAssignments().insert(
            customer=ctx.need("CUSTOMER_ID"), body=b
        ),
    )


# --------------------------------------------------------------------------- #
# Phase 1 and 2 — Workspace identity, groups, sandbox, floor list, roles
# --------------------------------------------------------------------------- #


def phase_1_org_units(ctx: Ctx) -> None:
    section("Phase 1.1 — organisational units")
    say(
        "  The robot needs its own unit so the Phase 3 hardening applies to it and "
        "to nothing else."
    )
    ensure_org_unit(ctx, ctx.need("SVC_OU"))
    ensure_org_unit(ctx, ctx.need("SANDBOX_OU"))


def phase_1_accounts(ctx: Ctx) -> None:
    section("Phase 1.2 — robot accounts")
    ensure_user(ctx, ctx.need("ROBOT"), "Wall-E", "Automation", ctx.need("SVC_OU"))
    ensure_user(ctx, ctx.need("EVE_ROBOT"), "Eve", "Automation", ctx.need("SVC_OU"))
    say("")
    say(
        "  Both accounts consume a licence, and the robot's MUST include Gmail: the "
        "frozen scope list and the Phase 16 mailbox watch depend on it. A licence "
        "without Gmail gives a clean Phase 9 and an unexplained failure at Phase 16."
    )


def phase_1_groups(ctx: Ctx) -> None:
    section("Phase 1.3 — the three groups")
    say(
        "  Three and not one: being able to REACH the agent and being able to "
        "APPROVE what it does are different authorities."
    )
    ensure_group(
        ctx, ctx.need("OPERATORS"), "Wall-E operators",
        "May halt, demote, veto, approve, and reach Wall-E in Gemini Enterprise.",
    )
    ensure_group(
        ctx, ctx.need("READERS"), "Wall-E readers",
        "May ask Wall-E read-only questions once the agent is shared with them.",
    )
    ensure_group(
        ctx, ctx.need("PROTECTED"), "Wall-E protected principals",
        "Every principal Wall-E may never write to.",
    )
    ensure_group_member(ctx, ctx.need("OPERATORS"), ctx.need("OPERATOR_EMAIL"), "OWNER")
    second = ctx.get("SECOND_OPERATOR")
    if second:
        ensure_group_member(ctx, ctx.need("OPERATORS"), second)
    else:
        warn(
            "SECOND_OPERATOR is not set. A one-member operators group is legal and it "
            "means every kill switch depends on you being awake. Record it as a gap."
        )
        ctx.note("operators group has one member: recorded as a known risk (D5).")
    ensure_group_member(ctx, ctx.need("READERS"), ctx.need("OPERATOR_EMAIL"))


def collect_admins(ctx: Ctx) -> List[str]:
    """Every super admin and every delegated admin, from two independent sources.

    Denial test 13 requires the runtime check to match isDelegatedAdmin, not only
    isAdmin, so the group and the floor list must cover both.

    Qualified 2026-09-13: once Super Admin is granted at the tier gate the
    robot itself is returned by the isAdmin query. It was already on the floor
    list and in the protected group by name (phase_1_protected_and_floor), so
    nothing changes in mechanism; it is now there by two routes.
    """
    users = admin(ctx).users()
    found: Dict[str, str] = {}
    for query in ("isAdmin=true", "isDelegatedAdmin=true"):
        request = users.list(
            customer=ctx.need("CUSTOMER_ID"), query=query, maxResults=200, projection="basic"
        )
        for user in paginate(ctx, users, request, "users"):
            found[user["primaryEmail"].lower()] = user["id"]
    # Second source: every role assignment, resolved to an address. A role
    # assigned to a group would otherwise be invisible in the user queries.
    for assignment in list_role_assignments(ctx):
        assigned = assignment.get("assignedTo")
        if not assigned:
            continue
        # absent_on_403 stays False here on purpose: a principal this credential
        # cannot resolve is a TRUNCATED enumeration, not an absent admin, and a
        # short floor list is attack A7 with the alarm disconnected.
        record = api_get(
            ctx, "users.get %s" % assigned, admin(ctx).users().get(userKey=assigned)
        )
        if record:
            found[record["primaryEmail"].lower()] = record["id"]
            continue
        group = api_get(
            ctx, "groups.get %s" % assigned, admin(ctx).groups().get(groupKey=assigned)
        )
        if group:
            found[group["email"].lower()] = assigned
            warn(
                "role assignment targets the GROUP %s. Its members inherit the role; "
                "the floor list records the group, and the runtime check must expand "
                "it transitively (A8)." % group["email"]
            )
            continue
        die(
            "role assignment %s targets principal %s, which resolves to neither a "
            "user nor a group with this credential. Refusing to write a floor list "
            "that may be truncated (A7). Resolve it by hand, or grant yourself the "
            "privilege to read it, and re-run."
            % (assignment.get("roleAssignmentId"), assigned)
        )
    return sorted(found)


def phase_1_protected_and_floor(ctx: Ctx) -> None:
    section("Phase 1.4 and 1.5 — protected group and the committed floor list")
    admins = collect_admins(ctx)
    if not admins:
        die(
            "admin enumeration returned nothing. That is exactly attack A7: an empty "
            "result reading as success. Refusing to write an empty floor list."
        )
    say("  %d admin principals found." % len(admins))
    for address in admins:
        ensure_group_member(ctx, ctx.need("PROTECTED"), address)
    ensure_group_member(ctx, ctx.need("PROTECTED"), ctx.need("ROBOT"))
    ensure_group_member(ctx, ctx.need("PROTECTED"), ctx.need("EVE_ROBOT"))
    write_floor_list(ctx, sorted(set(admins + [ctx.need("ROBOT"), ctx.need("EVE_ROBOT")])))


def write_floor_list(ctx: Ctx, addresses: Sequence[str]) -> None:
    """The floor assertion is deliberately a file, not the group.

    The group is what the service reads. The file is what the computed set is
    checked against, so a truncated computation becomes a loud refusal rather
    than a silent pass (SETUP.md Phase 1 step 5, denial test 18).
    """
    path = os.path.expanduser(ctx.need("FLOOR_LIST_PATH"))
    today = datetime.date.today().isoformat()
    header = [
        "# Wall-E protected floor assertion",
        "# The action service refuses EVERY directory write if the protected set it",
        "# computes at runtime does not cover every address below.",
        "# issued: %s by %s" % (today, ctx.get("OPERATOR_NAME")),
        "# source: super admins and delegated admins, Admin SDK, %s" % today,
        "# re-issue whenever an admin joins or leaves. Review quarterly.",
        "# This list also carries the two robot accounts, which SETUP.md Phase 1",
        "# step 5 does not ask for: denial test 17 requires a write targeting",
        "# $ROBOT or anything in $SVC_OU to be refused as protected_principal, so",
        "# the runtime protected set has to cover them too. Deliberate, and wider",
        "# than the runbook specifies.",
        "# 2026-09-13: once Super Admin is granted (tier gate, M2C) the robot is",
        "# also a super admin, so it appears here by both routes; it stays a",
        "# protected principal under its own N7 rule (platform HLD §13.1 item 2).",
        "",
    ]
    body = "\n".join(header + list(addresses)) + "\n"
    if ctx.dry_run:
        say("  WOULD WRITE %s (%d addresses)" % (path, len(addresses)))
        return
    if os.path.isfile(path):
        with open(path, "r", encoding="utf-8") as handle:
            current = [
                line.strip() for line in handle if line.strip() and not line.startswith("#")
            ]
        if current == list(addresses):
            step("floor list is already current: %s" % path)
            # Correct on disk is not the same as committed. An interrupted run
            # leaves the file written and unstaged, and the assertion only
            # exists once it is in git (SETUP.md Phase 1 step 5).
            commit_floor_list(ctx, path, today)
            return
        say("  floor list changes: %d -> %d addresses" % (len(current), len(addresses)))
    confirm(ctx, "Write the floor list to %s?" % path)
    # dirname("floor.txt") is "", and makedirs("") raises FileNotFoundError.
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(body)
    step("wrote %s" % path)
    commit_floor_list(ctx, path, today)


def commit_floor_list(ctx: Ctx, path: str, today: str) -> None:
    repo = os.path.expanduser(ctx.need("WALLE_REPO"))
    if not os.path.isdir(os.path.join(repo, ".git")):
        warn("%s is not a git repository. Commit the floor list by hand." % repo)
        ctx.note("floor list at %s is NOT committed: %s is not a git repo." % (path, repo))
        return
    run(ctx, ["git", "-C", repo, "add", path])
    staged = probe(ctx, ["git", "-C", repo, "diff", "--cached", "--quiet", "--", path])
    if staged.ok:
        step("floor list already committed, nothing to do")
        return
    run(
        ctx,
        [
            "git", "-C", repo, "commit", "-m",
            "floor assertion: super admins and delegated admins, %s" % today,
            # Pathspec, so unrelated work the operator had staged in the action
            # service repo is never swept into the commit an incident review
            # reads as the dated floor assertion.
            "--", path,
        ],
    )


def phase_1_sandbox(ctx: Ctx) -> None:
    section("Phase 1.6 — the sandbox")
    say(
        "  These are the ONLY targets any verification step in this build may name. "
        "Without them Phase 9's most informative check has no target and the Phase 14 "
        "ou_allowlist points at an empty unit."
    )
    accounts = [a.strip() for a in ctx.need("SANDBOX_ACCOUNTS").split(",") if a.strip()]
    if len(accounts) < 3:
        die("at least three synthetic sandbox accounts are required (Phase 1 step 6)")
    for index, address in enumerate(accounts, start=1):
        ensure_user(ctx, address, "Wall-E test", "%02d" % index, ctx.need("SANDBOX_OU"))
    ctx.note("sandbox accounts: %s" % ", ".join(accounts))


def super_admin_grant_on_file(ctx: Ctx) -> bool:
    """The tier gate's record (decision P33), patterned on the spike gates.

    SUPER_ADMIN_GRANT_DECISION names the signed decision record
    (decisions/2026-09-13-wall-e-holds-super-admin.md, platform HLD §13.1 item
    12). Present: the robot MUST be a super admin. Absent: it must NOT be one,
    because a grant with no signed record is a grant nobody decided.
    """
    path = os.path.expanduser(ctx.get("SUPER_ADMIN_GRANT_DECISION") or "")
    return bool(path) and os.path.isfile(path)


def phase_2_roles(ctx: Ctx) -> None:
    section("Phase 2 — Wall-E holds no custom role; Eve's read-only role")
    say(
        "  Reversed 2026-09-13 (platform HLD §13.1, §18 item 5). This phase used to "
        "create two Wall-E custom roles: a customer-scoped Stage 0 reader, assigned "
        "now, and an OU-scoped Stage 1 write role assigned to nobody. The robot holds "
        "Super Admin instead, which cannot be limited to an OU or subset by privilege, "
        "so there is no Wall-E role to build and no role that 'grows with the ladder'. "
        "Google no longer refuses anything at its end: the action services are the "
        "only gate, the consented scopes the only Google-enforced ceiling."
    )
    say(
        "  Kept as footnotes, still true for custom roles and for Eve: Groups and "
        "Reports privileges cannot be OU-scoped, and an OU-scoped read role "
        "enumerates admins inside that OU only (attack A7)."
    )
    # Leftovers from a build made before 2026-09-13. Reported, never deleted
    # here: nothing is deleted outside teardown (and `rollback --phase 2`, which
    # removes assignments on request).
    robot = api_get(
        ctx, "users.get robot", admin(ctx).users().get(userKey=ctx.need("ROBOT"))
    )
    for title in RETIRED_WALLE_ROLE_NAMES:
        role = find_role(ctx, title)
        if not role:
            continue
        assigned = [a for a in list_role_assignments(ctx, role["roleId"])]
        warn(
            "retired role '%s' still exists with %d assignment(s). The robot must hold "
            "Super Admin and nothing else; remove it with 'walle rollback --phase 2' "
            "(assignments) and then in Admin console -> Account -> Admin roles."
            % (title, len(assigned))
        )
        ctx.note("retired Wall-E role '%s' still exists (%d assignment(s)); verify "
                 "fails while it is assigned" % (title, len(assigned)))
    if robot and robot.get("isAdmin") and not super_admin_grant_on_file(ctx):
        warn(
            "%s is ALREADY a super admin and SUPER_ADMIN_GRANT_DECISION names no signed "
            "record. The grant is a tier gate (M2C), not a runbook act: record it or "
            "have a human super admin remove it (K6)." % ctx.need("ROBOT")
        )
        ctx.note("robot is a super admin with no grant record on file: verify fails")
    say("")
    say("  This script never grants Super Admin, never calls users.makeAdmin and never")
    say("  inserts a Super Admin role assignment: both are on the hard-denied list,")
    say("  and the grant is manual step M2C at the tier gate.")

    catalogue = list_privileges(ctx)
    say("  %d privilege names in this tenant's catalogue." % len(catalogue))
    eve_privs = resolve_privileges(ctx, catalogue, EVE_PRIVILEGE_CANDIDATES)
    for entry in eve_privs:
        name = entry["privilegeName"]
        if is_write_privilege(name):
            die(
                "resolved '%s' into Eve's read role, and it looks like a write "
                "privilege. Eve's role must contain no write privilege at all." % name
            )
    eve_role = ensure_role(
        ctx, ROLE_EVE_NAME,
        "Eve verifies independently. Read privileges only, at every stage, forever.",
        eve_privs,
    )
    eve = api_get(
        ctx, "users.get eve", admin(ctx).users().get(userKey=ctx.need("EVE_ROBOT"))
    )
    if eve:
        ensure_role_assignment(ctx, eve_role["roleId"], eve["id"], "CUSTOMER")
    say("")
    say(
        "  Do not trust console labels: run 'walle dump-privileges' and fix Eve's read "
        "set from the real API names (Eve's widened set, E-16, is Eve's runbook's)."
    )


def cmd_workspace(ctx: Ctx) -> int:
    section("Phases 1 and 2 — Workspace")
    do_manual_step(ctx, "M0")
    phase_1_org_units(ctx)
    phase_1_accounts(ctx)
    phase_1_groups(ctx)
    phase_1_sandbox(ctx)
    phase_1_protected_and_floor(ctx)
    phase_2_roles(ctx)
    do_manual_step(ctx, "M1")
    # M2A is verified — a key really is enrolled — before M2B is even printed.
    # Enforcing hardware-key-only on an account with no key locks it out
    # permanently, and the recovery path is a full Phase 9 re-bootstrap.
    do_manual_step(ctx, "M2A")
    do_manual_step(ctx, "M2B")
    do_manual_step(ctx, "M3")
    # Phase 5 belongs here, not in `deploy`: the toggle takes up to 24 hours to
    # produce rows and the login half must be resolved before Phase 9.
    do_manual_step(ctx, "M4")
    # The Super Admin grant (2026-09-13): last, after the hardening and the login
    # rule it depends on, and only when the tier gate's signed record is on file.
    # Re-running `walle workspace` on the gate day is how it is reached.
    if super_admin_grant_on_file(ctx):
        # Precondition, checked before the block (2026-09-13): the verifier reads
        # SUPER_ADMIN_ROSTER from the config loaded at start, so a roster that
        # does not list the robot yet would FAIL right after a correct human grant.
        roster = [a.strip().lower() for a in ctx.get("SUPER_ADMIN_ROSTER", "").split(",")
                  if a.strip()]
        if ctx.need("ROBOT").lower() not in roster:
            die("SUPER_ADMIN_ROSTER does not list %s. Commit the exact roster including the "
                "robot, export it, and re-run 'walle workspace' BEFORE the grant (M2C): the "
                "config is read once at start." % ctx.need("ROBOT"))
        do_manual_step(ctx, "M2C")
    else:
        say("")
        say("  M2C (the Super Admin grant) is NOT offered: SUPER_ADMIN_GRANT_DECISION")
        say("  names no signed record. The robot holds no admin role until the platform's")
        say("  tier gate is passed (platform HLD §0.4); verify asserts exactly that.")
        ctx.note("Super Admin not granted: tier gate not passed (no P33 record on file).")
    ctx.print_notes()
    say("")
    say("Phases 1 and 2 done. Next: 'walle gcp' (phases 6, 7, 8).")
    return 0


# --------------------------------------------------------------------------- #
# GCP get-or-create helpers
# --------------------------------------------------------------------------- #


def project_exists(ctx: Ctx) -> bool:
    """A project you may not see and a project that is not there look the same:
    describing a non-existent project answers PERMISSION_DENIED as often as
    NOT_FOUND, so both are read as absent here and create fails loudly if it is
    really a permission problem."""
    result = probe(ctx, ["gcloud", "projects", "describe", ctx.need("PROJECT"),
                         "--format=json"])
    return result.ok


def ensure_project(ctx: Ctx) -> None:
    project = ctx.need("PROJECT")
    if project_exists(ctx):
        step("project exists: %s" % project)
    else:
        # --folder, not --organization, and the TIER folder, not the platform
        # folder: WALLE_FOLDER_ID is fld-agents-p-sa-prod, a descendant of
        # FOLDER_ID, so the project inherits the platform floor AND the P-SA
        # tier's stricter policies (agentic-platform/02 section 2). Corrected
        # 2026-09-13; this used FOLDER_ID. gcloud takes one flag, never both.
        run(
            ctx,
            ["gcloud", "projects", "create", project, "--folder", ctx.need("WALLE_FOLDER_ID")],
        )
    # Wall-E's project is the gcloud default from here on. Every read of
    # another project's resource must therefore name it: gcloud_probe_json_in.
    run(ctx, ["gcloud", "config", "set", "project", project])
    billing = gcloud_probe_json(ctx, "billing", "projects", "describe", project)
    if billing and billing.get("billingEnabled"):
        step("billing already linked")
    else:
        run(
            ctx,
            [
                "gcloud", "billing", "projects", "link", project,
                "--billing-account", ctx.need("BILLING"),
            ],
        )
    number = project_number(ctx)
    if number:
        say("  PROJECT_NUMBER=%s   <- put this in the config; phases 11 and 12 need it"
            % number)
        ctx.cfg["PROJECT_NUMBER"] = number
        ctx.note("PROJECT_NUMBER=%s" % number)
    gemini_number = gemini_project_number(ctx)
    if gemini_number:
        say("  GEMINI_PROJECT_NUMBER=%s   <- put this in the config; phase 12 (engine "
            "IAM) needs it" % gemini_number)
        ctx.note("GEMINI_PROJECT_NUMBER=%s" % gemini_number)
    else:
        warn("could not read the number of GEMINI_PROJECT %s. Phase 12 names the "
             "Gemini Enterprise service agent by that number; fill in "
             "GEMINI_PROJECT_NUMBER before 'walle deploy' (project-topology.md §7.4)."
             % ctx.need("GEMINI_PROJECT"))


def project_number(ctx: Ctx) -> str:
    cached = ctx.get("PROJECT_NUMBER")
    if cached:
        return cached
    described = gcloud_probe_json(ctx, "projects", "describe", ctx.need("PROJECT"))
    if not described:
        return ""
    number = str(described.get("projectNumber", ""))
    ctx.cfg["PROJECT_NUMBER"] = number
    return number


def gemini_project_number(ctx: Ctx) -> str:
    """The Gemini Enterprise APP project's number, never Wall-E's.

    The app calls Wall-E's engine as
    service-<APP_PROJECT_NUMBER>@gcp-sa-discoveryengine.iam.gserviceaccount.com
    (project-topology.md row 1). Built from PROJECT_NUMBER this would be a
    principal that never calls anything, and the engine lock would be a lock
    with the wrong key. `projects describe` takes the id positionally and is
    issued without --project, so the gcloud default cannot redirect it.
    """
    cached = ctx.get("GEMINI_PROJECT_NUMBER")
    if cached:
        return cached
    result = probe(ctx, ["gcloud", "projects", "describe", ctx.need("GEMINI_PROJECT"),
                         "--format=json"])
    if not result.ok or not result.out.strip():
        return ""
    number = str((json.loads(result.out) or {}).get("projectNumber", ""))
    if number:
        ctx.cfg["GEMINI_PROJECT_NUMBER"] = number
    return number


def _dry_run_list(ctx: Ctx, what: str, *argv: str) -> Optional[List[Any]]:
    """A list read whose failure, under --dry-run only, is "not created yet".

    On the first `walle gcp --dry-run` the project has been created on paper
    and not in fact, so every read against it fails. Hard rule 5 says a dry run
    prints every command it would make; dying at the first read a third of the
    way through Phase 6 breaks that on exactly the run an operator does first.
    """
    result = probe(ctx, ["gcloud"] + list(argv) + [
        "--format=json", "--project", ctx.need("PROJECT")])
    if result.ok:
        text = result.out.strip()
        return json.loads(text) if text else []
    if ctx.dry_run:
        say("  [dry run] cannot read %s yet (the project is not created): %s"
            % (what, (result.err or "").strip().splitlines()[:1]))
        return None
    raise WalleError(
        "cannot list %s on %s\n%s" % (what, ctx.need("PROJECT"), result.err.strip())
    )


def ensure_apis(ctx: Ctx) -> None:
    enabled = _dry_run_list(ctx, "enabled services", "services", "list", "--enabled")
    if enabled is None:
        say("  [dry run] would enable %d APIs: %s"
            % (len(APIS_TO_ENABLE), ", ".join(APIS_TO_ENABLE)))
        return
    have = {item.get("config", {}).get("name") for item in enabled}
    missing = [api for api in APIS_TO_ENABLE if api not in have]
    if not missing:
        step("all %d APIs already enabled" % len(APIS_TO_ENABLE))
        return
    say("  enabling %d APIs: %s" % (len(missing), ", ".join(missing)))
    run(ctx, ["gcloud", "services", "enable"] + missing + ["--project", ctx.need("PROJECT")])


def ensure_service_accounts(ctx: Ctx) -> None:
    existing = _dry_run_list(ctx, "service accounts", "iam", "service-accounts", "list")
    if existing is None:
        say("  [dry run] would create %d service accounts: %s"
            % (len(SERVICE_ACCOUNT_IDS), ", ".join(SERVICE_ACCOUNT_IDS)))
        return
    have = {item["email"] for item in existing}
    for name in SERVICE_ACCOUNT_IDS:
        email = "%s@%s.iam.gserviceaccount.com" % (name, ctx.need("PROJECT"))
        if email in have:
            step("service account exists: %s" % email)
            continue
        run(
            ctx,
            [
                "gcloud", "iam", "service-accounts", "create", name,
                "--display-name", name, "--project", ctx.need("PROJECT"),
            ],
        )


def ensure_project_binding(ctx: Ctx, member: str, role: str) -> None:
    """add-iam-policy-binding is idempotent, but the read makes --dry-run useful."""
    read = probe(
        ctx,
        ["gcloud", "projects", "get-iam-policy", ctx.need("PROJECT"), "--format=json"],
    )
    if not read.ok:
        if not ctx.dry_run:
            raise WalleError(
                "cannot read the IAM policy of %s\n%s"
                % (ctx.need("PROJECT"), read.err.strip())
            )
        # The project exists only on paper during the first dry run.
        say("  WOULD RUN: gcloud projects add-iam-policy-binding %s --member %s "
            "--role %s --condition None" % (ctx.need("PROJECT"), member, role))
        return
    policy = (json.loads(read.out) if read.out.strip() else {}) or {}
    for binding in policy.get("bindings", []):
        if binding.get("role") == role and member in binding.get("members", []):
            step("binding present: %s -> %s" % (member, role))
            return
    run(
        ctx,
        [
            "gcloud", "projects", "add-iam-policy-binding", ctx.need("PROJECT"),
            "--member", member, "--role", role, "--condition", "None",
        ],
    )


def ensure_sa_binding(ctx: Ctx, sa_email: str, member: str, role: str) -> None:
    policy = gcloud_probe_json(
        ctx, "iam", "service-accounts", "get-iam-policy", sa_email
    ) or {}
    for binding in policy.get("bindings", []):
        if binding.get("role") == role and member in binding.get("members", []):
            step("binding present on %s: %s -> %s" % (sa_email, member, role))
            return
    run(
        ctx,
        [
            "gcloud", "iam", "service-accounts", "add-iam-policy-binding", sa_email,
            "--member", member, "--role", role, "--project", ctx.need("PROJECT"),
        ],
    )


def phase_6_project(ctx: Ctx) -> None:
    # Platform HLD §18 item 5 (2026-09-13): SETUP.md Phase 6 becomes a factory
    # call (Cloud Foundation Fabric project-factory, platform 02 §3, P35), with
    # WALLE_PROJECT under fld-agents-p-sa. The factory is not built yet, so this
    # hand-made path is kept unchanged until it is; it is not the target state.
    section("Phase 6 — project, APIs, service accounts, staging bucket, budget")
    ensure_project(ctx)
    ensure_apis(ctx)
    ensure_service_accounts(ctx)

    say("")
    say("  Project roles. A new service account holds nothing at all, and the failure")
    say("  is total: the action service's first policy step is a Firestore read, and")
    say("  any Firestore error is a hard invariant, so without datastore.user every")
    say("  request including reads is denied with control_plane_unavailable.")
    for role in ACTIONS_PROJECT_ROLES:
        ensure_project_binding(ctx, "serviceAccount:" + ctx.need("SA_ACTIONS"), role)
    for role in SUPER_PROJECT_ROLES:
        ensure_project_binding(ctx, "serviceAccount:" + ctx.need("SA_ACTIONS_SUPER"), role)
    for role in DISPATCH_PROJECT_ROLES:
        ensure_project_binding(ctx, "serviceAccount:" + ctx.need("SA_DISPATCH"), role)
    # EVE_PROJECT_ROLES is empty (decision 44): a project-level role in Wall-E's
    # project for an identity from EVE_PROJECT is exactly what the topology
    # forbids. The loop stays so the day decision 44 names a resource-scoped
    # form it lands here and nowhere else.
    for role in EVE_PROJECT_ROLES:
        ensure_project_binding(ctx, "serviceAccount:" + ctx.need("SA_EVE"), role)
    say("  walle-agent@ gets nothing here, and that is the point.")
    say("  Nothing of Eve's or Mo's is created or granted at project level here:")
    say("  eve-controller@ and the other Eve identities are created in EVE_PROJECT")
    say("  (%s) by eve/07-build-runbook.md, Mo's in MO_PROJECT (%s) by"
        % (ctx.need("EVE_PROJECT"), ctx.need("MO_PROJECT")))
    say("  mo/07-build-runbook.md. Their reads of Wall-E's datasets are Phase 7's")
    say("  dataset-level grants; their calls to walle-actions are Phase 10's")
    say("  run.invoker (project-topology.md §3).")

    # The Cloud Tasks worker calls the action service back with an OIDC token
    # minted for its own service account.
    ensure_sa_binding(
        ctx, ctx.need("SA_ACTIONS"), "serviceAccount:" + ctx.need("SA_ACTIONS"),
        "roles/iam.serviceAccountUser",
    )
    # The only way a human can mint an ID token with the right audience.
    ensure_sa_binding(
        ctx, ctx.need("SA_OPS_CALLER"), "group:" + ctx.need("OPERATORS"),
        "roles/iam.serviceAccountTokenCreator",
    )
    ensure_staging_bucket(ctx)
    ensure_budget(ctx)


def ensure_staging_bucket(ctx: Ctx) -> None:
    bucket = ctx.need("STAGING_BUCKET")
    described = gcloud_probe_json(ctx, "storage", "buckets", "describe", bucket)
    if described is None:
        run(
            ctx,
            [
                "gcloud", "storage", "buckets", "create", bucket,
                "--location", ctx.need("REGION"), "--uniform-bucket-level-access",
                "--project", ctx.need("PROJECT"),
            ],
        )
    else:
        location = str(described.get("location", "")).upper()
        step("staging bucket exists: %s (%s)" % (bucket, location))
        if location and location != ctx.need("REGION").upper():
            die(
                "staging bucket is in %s, not %s. A bucket's location is fixed at "
                "creation and the residency posture does not allow this."
                % (location, ctx.need("REGION"))
            )
    run(
        ctx,
        [
            "gcloud", "storage", "buckets", "add-iam-policy-binding", bucket,
            "--member", "serviceAccount:" + ctx.need("SA_AGENT"),
            "--role", "roles/storage.objectViewer",
        ],
    )


def ensure_budget(ctx: Ctx) -> None:
    """--filter-projects takes projects/{id}. The project NUMBER silently scopes
    the budget to the whole billing account and looks like it worked."""
    billing = ctx.need("BILLING")
    existing = gcloud_probe_json(ctx, "billing", "budgets", "list", "--billing-account", billing)
    for budget in existing or []:
        if budget.get("displayName") == "walle-stage-0":
            step("budget exists: walle-stage-0")
            filters = budget.get("budgetFilter", {}).get("projects", [])
            expected = "projects/%s" % ctx.need("PROJECT")
            if expected not in filters:
                die(
                    "budget walle-stage-0 is scoped to %s, not %s. As written it "
                    "alerts on your organisation's entire spend." % (filters, expected)
                )
            return
    run(
        ctx,
        [
            "gcloud", "billing", "budgets", "create",
            "--billing-account", billing,
            "--display-name", "walle-stage-0",
            "--budget-amount", ctx.get("BUDGET_AMOUNT", "200EUR"),
            "--filter-projects", "projects/%s" % ctx.need("PROJECT"),
            "--threshold-rule=percent=0.5",
            "--threshold-rule=percent=0.9",
            "--threshold-rule=percent=1.0",
        ],
    )
    say(
        "  If that failed with a permission error you hold Billing Account User but "
        "not Billing Account Costs Manager. SETUP.md 1.4: ask for both at once."
    )


def phase_7_data(ctx: Ctx) -> None:
    section("Phase 7 — Firestore, BigQuery, Pub/Sub, Cloud Tasks, cross-project readers")
    ensure_firestore(ctx)
    ensure_datasets(ctx)
    ensure_audit_tables(ctx)
    grant_cross_project_dataset_readers(ctx)
    ensure_topics(ctx)
    ensure_tasks_queue(ctx)


def grant_cross_project_dataset_readers(ctx: Ctx) -> None:
    """project-topology.md rows 4 and 6, made here because the datasets are Wall-E's.

    A dataset-level READER entry (roles/bigquery.dataViewer, stored by BigQuery
    as READER) for each Eve and Mo identity that reads Wall-E's audit tables,
    keyed on EVE_PROJECT and MO_PROJECT. Never a project-level dataViewer, and
    never roles/bigquery.jobUser: the query jobs run, and are billed, in the
    reader's own project (Eve's and Mo's runbooks grant jobUser there).

    An identity that does not exist yet (eve-controller@ and eve-verifier@ are
    S3, created by Eve's runbook Phase 8) cannot be granted: that is recorded
    as a note and re-running `walle gcp` after Eve's phase adds the entry.
    """
    say("")
    say("  Cross-project dataset readers (project-topology.md §3 rows 4 and 6).")
    say("  No authorised-view entry is ever added for a Mo view on a Wall-E dataset:")
    say("  row 9 makes that absence a control, and verify asserts it.")
    for principal_key, dataset_key, stage, row in CROSS_PROJECT_DATASET_READERS:
        principal = ctx.need(principal_key)
        add_dataset_access(
            ctx, ctx.get(dataset_key), "roles/bigquery.dataViewer", principal,
            foreign="topology row %s, %s from %s" % (row, principal_key, stage),
        )


def ensure_firestore(ctx: Ctx) -> None:
    described = gcloud_probe_json(
        ctx, "firestore", "databases", "describe", "--database", "(default)"
    )
    if described is not None:
        location = described.get("locationId", "")
        step("Firestore database exists in %s" % location)
        if location != ctx.need("REGION"):
            die(
                "Firestore is in %s, not %s. A database's location is fixed at "
                "creation: delete and recreate before anything writes to it."
                % (location, ctx.need("REGION"))
            )
        return
    run(
        ctx,
        [
            "gcloud", "firestore", "databases", "create",
            "--location", ctx.need("REGION"), "--type", "firestore-native",
            "--project", ctx.need("PROJECT"),
        ],
    )


def bq_dataset_exists(ctx: Ctx, dataset: str) -> bool:
    # bq show takes the dataset id positionally; there is no --dataset flag on
    # show, and passing one is a flag-parsing error rather than a miss.
    result = probe(
        ctx, ["bq", "--project_id", ctx.need("PROJECT"), "show", "--format=prettyjson",
              "%s:%s" % (ctx.need("PROJECT"), dataset)]
    )
    return result.ok


def ensure_datasets(ctx: Ctx) -> None:
    """Two datasets, deliberately.

    The log sink's writer identity needs dataEditor on its destination, and
    dataEditor includes tables.deleteData. Pointing the sink at walle_audit would
    create a principal able to delete Wall-E's own evidence (guardrail N8).
    """
    pairs = (
        (ctx.get("AUDIT_DATASET"), "Wall-E audit trail. Insert-only for walle-actions@."),
        (ctx.get("LOGS_DATASET"), "Workspace admin audit logs, routed by an org-level sink."),
    )
    for dataset, description in pairs:
        if bq_dataset_exists(ctx, dataset):
            step("dataset exists: %s" % dataset)
            continue
        run(
            ctx,
            [
                "bq", "--project_id", ctx.need("PROJECT"),
                "--location", ctx.need("BQ_LOCATION"), "mk", "--dataset",
                "--description", description,
                "%s:%s" % (ctx.need("PROJECT"), dataset),
            ],
        )


def schema_path(ctx: Ctx, table: str) -> str:
    path = os.path.join(os.path.expanduser(ctx.need("WALLE_REPO")), "schemas", "%s.json" % table)
    if not os.path.isfile(path):
        die(
            "missing %s.\nPhase 7 needs schemas/*.json from the Wall-E repository "
            "(SETUP.md 0.4: phase 7 waits for the repo). Columns are specified in "
            "03-lld.md." % path
        )
    return path


def schema_fields(path: str) -> List[str]:
    with open(path, "r", encoding="utf-8") as handle:
        schema = json.load(handle)
    if isinstance(schema, dict):
        schema = schema.get("fields", [])
    return [field["name"] for field in schema]


def ensure_audit_tables(ctx: Ctx) -> None:
    """bq mk rejects a clustering field absent from the schema, and a single loop
    then dies partway leaving some tables created and some not."""
    for table in AUDIT_TABLES:
        target = "%s:%s.%s" % (ctx.need("PROJECT"), ctx.get("AUDIT_DATASET"), table)
        if probe(ctx, ["bq", "show", "--format=prettyjson", target]).ok:
            step("table exists: %s" % table)
            continue
        path = schema_path(ctx, table)
        fields = schema_fields(path)
        if "ts" not in fields:
            die("%s has no ts column; every audit table is partitioned on ts" % path)
        clustering: List[str] = []
        if table == "actions" and "operation" in fields:
            clustering.append("operation")
        if table in ("runs", "plans") and "run_id" in fields:
            clustering.append("run_id")
        argv = [
            "bq", "--project_id", ctx.need("PROJECT"), "mk", "--table",
            "--time_partitioning_field=ts",
            "--time_partitioning_type=DAY",
            "--time_partitioning_expiration=%d" % PARTITION_EXPIRATION_SECONDS,
        ]
        if clustering:
            argv.append("--clustering_fields=%s" % ",".join(clustering))
        argv += [target, path]
        run(ctx, argv)


def ensure_topics(ctx: Ctx) -> None:
    existing = _dry_run_list(ctx, "pub/sub topics", "pubsub", "topics", "list")
    if existing is None:
        say("  [dry run] would create %d topics: %s"
            % (len(PUBSUB_TOPICS), ", ".join(PUBSUB_TOPICS)))
        return
    have = {item["name"].rsplit("/", 1)[-1] for item in existing}
    for topic in PUBSUB_TOPICS:
        if topic in have:
            step("topic exists: %s" % topic)
            continue
        run(ctx, ["gcloud", "pubsub", "topics", "create", topic,
                  "--project", ctx.need("PROJECT")])


def ensure_tasks_queue(ctx: Ctx) -> None:
    queue = ctx.get("TASKS_QUEUE")
    described = gcloud_probe_json(
        ctx, "tasks", "queues", "describe", queue, "--location", ctx.need("REGION")
    )
    if described is not None:
        step("queue exists: %s (%s)" % (queue, described.get("state")))
        return
    # max-concurrent-dispatches=1 serialises item execution, so a burst cannot
    # outrun the per-tier rate limit even briefly.
    run(
        ctx,
        [
            "gcloud", "tasks", "queues", "create", queue,
            "--location", ctx.need("REGION"),
            "--max-dispatches-per-second=1",
            "--max-concurrent-dispatches=1",
            "--max-attempts=3",
            "--project", ctx.need("PROJECT"),
        ],
    )


def phase_8_keys_and_secrets(ctx: Ctx) -> None:
    section("Phase 8 — regional secrets, confirmation HMAC, insert-only audit role")
    explain_eve_key_is_not_here(ctx)
    ensure_secrets(ctx)
    ensure_confirm_hmac(ctx)
    ensure_audit_writer_role(ctx)


def explain_eve_key_is_not_here(ctx: Ctx) -> None:
    """Eve's signing key is created in EVE_PROJECT by Eve's runbook, never here.

    The asymmetric requirement is unchanged and not a preference: for "Eve
    approved this" to mean anything the action service must be able to verify
    a signature and unable to produce one (attack A2). What changed is WHERE
    the key lives. With the key in Eve's project, walle-actions@ has no
    principal in the project that holds it and nothing to escalate from; the
    "key's purpose cannot be changed" and "eve-controller@ holds signer"
    assertions belong to Eve's verify (project-topology.md rows 14 and 17,
    decision 46). This script refuses to create a ring, a key or a signer
    binding in Wall-E's project.
    """
    say("")
    say("  Eve's KMS key: NOT created here. Ring %s, key %s live in EVE_PROJECT (%s),"
        % (ctx.get("KMS_KEYRING"), ctx.get("KMS_KEY"), ctx.need("EVE_PROJECT")))
    say("  created by eve/07-build-runbook.md Phase 11 with eve-controller@ as signer.")
    say("  walle-actions verifies approvals against the PEM pinned per key version in")
    say("  Wall-E's repository (%s/), so no cross-project KMS grant exists by default."
        % "/".join(EVE_PUBLIC_KEYS_SUBDIR))
    say("  The optional fallback, roles/cloudkms.publicKeyViewer for walle-actions@ on")
    say("  that ONE key (key-level, in EVE_PROJECT), is Eve's owner's act in Eve's")
    say("  runbook — never ring- or project-level, never signer (topology row 14).")
    say("  A refusal is the right outcome if anyone asks this script for a KMS key.")


def secret_exists(ctx: Ctx, name: str, project: str = "") -> bool:
    """In Wall-E's project by default; `project` names another project's secret.

    Without the explicit project a read of eve-refresh-token would land in
    Wall-E's project and answer "does not exist" for a secret that exists in
    Eve's, which is how a separation check silently narrows to nothing.
    """
    argv = ("secrets", "describe", name, "--location", ctx.need("REGION"))
    if project:
        return gcloud_probe_json_in(ctx, project, *argv) is not None
    return gcloud_probe_json(ctx, *argv) is not None


def ensure_secrets(ctx: Ctx) -> None:
    """--location makes these REGIONAL secrets.

    That is the current residency mechanism: the data stays in the location at
    rest, in use and in transit. A global secret with user-managed replication
    pins only the payload at rest. A create without --location is wrong.
    """
    for name in WALLE_SECRETS:
        if secret_exists(ctx, name):
            step("secret exists: %s" % name)
        else:
            run(ctx, ["gcloud", "secrets", "create", name,
                      "--location", ctx.need("REGION"), "--project", ctx.need("PROJECT")])
        # One reader per secret (2026-09-13): the narrow pair to walle-actions@,
        # the broad pair to walle-actions-super@, never crossed. Putting the
        # broad client where the catalogue can read it would make the narrow
        # client's Google-enforced ceiling decorative (wall-e/01-hld.md).
        reader = ctx.need(SECRET_READERS[name])
        run(
            ctx,
            [
                "gcloud", "secrets", "add-iam-policy-binding", name,
                "--location", ctx.need("REGION"),
                "--member", "serviceAccount:" + reader,
                "--role", "roles/secretmanager.secretAccessor",
                "--project", ctx.need("PROJECT"),
            ],
        )
    say(
        "  walle-agent@ appears nowhere in that loop and must never be added: the "
        "credential does not exist in the model's process or context, so no prompt "
        "and no tool can exfiltrate it. That absence is trust boundary 3."
    )
    say(
        "  Each OAuth pair has exactly one reader: walle-oauth-client and "
        "walle-refresh-token to walle-actions@, walle-super-oauth-client and "
        "walle-super-refresh-token to walle-actions-super@ (platform HLD §13.1 item 3)."
    )


def ensure_confirm_hmac(ctx: Ctx) -> None:
    """Generated here, never displayed, never written to disk."""
    versions = gcloud_probe_json(
        ctx, "secrets", "versions", "list", "walle-confirm-hmac",
        "--location", ctx.need("REGION"), "--filter", "state=ENABLED",
    )
    if versions:
        step("walle-confirm-hmac already has %d enabled version(s)" % len(versions))
        return
    import secrets as _secrets

    payload = base64.b64encode(_secrets.token_bytes(48))
    say("  WOULD ADD a random 48-byte confirmation HMAC (value never displayed)"
        if ctx.dry_run else "  adding a random 48-byte confirmation HMAC")
    run(
        ctx,
        [
            "gcloud", "secrets", "versions", "add", "walle-confirm-hmac",
            "--location", ctx.need("REGION"), "--data-file", "-",
            "--project", ctx.need("PROJECT"),
        ],
        stdin_data=payload,
        stdin_is_secret=True,
    )


def ensure_audit_writer_role(ctx: Ctx) -> None:
    """roles/bigquery.dataEditor would let the action service destroy its own
    evidence: it includes bigquery.tables.deleteData."""
    project = ctx.need("PROJECT")
    described = gcloud_probe_json(ctx, "iam", "roles", "describe", "walleAuditWriter",
                                  "--project", project)
    if described is None:
        run(
            ctx,
            [
                "gcloud", "iam", "roles", "create", "walleAuditWriter",
                "--project", project,
                "--title", "Wall-E audit writer (insert only)",
                "--description", "Insert audit rows. Cannot delete them.",
                "--permissions",
                "bigquery.tables.updateData,bigquery.tables.get,bigquery.datasets.get",
                "--stage", "GA",
            ],
        )
    elif described.get("deleted"):
        run(ctx, ["gcloud", "iam", "roles", "undelete", "walleAuditWriter",
                  "--project", project])
    else:
        step("custom role exists: walleAuditWriter")
    add_dataset_access(
        ctx, ctx.get("AUDIT_DATASET"),
        "projects/%s/roles/walleAuditWriter" % project, ctx.need("SA_ACTIONS"),
    )
    # The band-B service writes its own audit rows (the canonical request, the
    # Discovery revision, both humans), insert-only like the first.
    add_dataset_access(
        ctx, ctx.get("AUDIT_DATASET"),
        "projects/%s/roles/walleAuditWriter" % project, ctx.need("SA_ACTIONS_SUPER"),
    )


# BigQuery stores the three predefined dataset roles under their legacy names
# and returns ONLY those: set roles/bigquery.dataEditor and `bq show` reads it
# back as WRITER. Comparing the two literally meant every `walle deploy`
# re-prompted, appended a second identical entry and rewrote the dataset that
# carries Wall-E's independent evidence. The custom role walleAuditWriter has
# no legacy mapping, which is why the actions grant always looked idempotent
# and the sink grant never was.
_LEGACY_DATASET_ROLES: Dict[str, str] = {
    "roles/bigquery.dataOwner": "OWNER",
    "roles/bigquery.dataEditor": "WRITER",
    "roles/bigquery.dataViewer": "READER",
}


def _same_dataset_role(left: str, right: str) -> bool:
    return _LEGACY_DATASET_ROLES.get(left, left) == _LEGACY_DATASET_ROLES.get(right, right)


def add_dataset_access(
    ctx: Ctx, dataset: str, role: str, member_email: str, foreign: str = "",
) -> None:
    """bq add-iam-policy-binding works on tables, views and connections only.

    Dataset access lives in the dataset's own access array: read it, append, and
    write it back. Idempotent because the entry is compared first. The dataset
    is always Wall-E's (the update is issued against PROJECT:dataset, the
    source dataset owns its access array); `foreign` names the topology row
    when the principal lives in EVE_PROJECT or MO_PROJECT, and then a principal
    BigQuery reports as non-existent is a note, not a stop: it is created by
    the other runbook at a later stage, and this grant is re-run then.
    """
    target = "%s:%s" % (ctx.need("PROJECT"), dataset)
    result = probe(ctx, ["bq", "show", "--format=prettyjson", target])
    if not result.ok:
        if ctx.dry_run:
            say("  WOULD ADD dataset access %s -> %s on %s" % (member_email, role, dataset))
            return
        die("cannot read dataset %s:\n%s" % (target, result.err.strip()))
    payload = json.loads(result.out)
    entries = payload.setdefault("access", [])
    wanted = {"role": role, "userByEmail": member_email}
    if any(
        _same_dataset_role(entry.get("role", ""), role)
        and entry.get("userByEmail") == member_email
        for entry in entries
    ):
        step("dataset access already present: %s -> %s" % (member_email, role))
        return
    entries.append(wanted)
    say("  DATASET ACCESS: %s gains %s on %s%s"
        % (member_email, role, dataset, " (cross-project: %s)" % foreign if foreign else ""))
    if ctx.dry_run:
        return
    confirm(ctx, "Apply this dataset access change?")
    handle = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8")
    try:
        json.dump(payload, handle)
        handle.close()
        result = run(ctx, ["bq", "update", "--source=%s" % handle.name, target],
                     check=not foreign)
    finally:
        os.unlink(handle.name)
    if foreign and not result.ok:
        lowered = (result.err or "").lower()
        if not any(marker in lowered for marker in ABSENT_MARKERS):
            die("bq update on %s failed:\n%s" % (target, result.err.strip()))
        warn("%s does not exist yet (%s); the READER entry on %s is NOT applied. "
             "Re-run 'walle gcp' once the other runbook has created it."
             % (member_email, foreign, dataset))
        ctx.note("PENDING cross-project grant: %s READER on %s (%s)"
                 % (member_email, dataset, foreign))


def cmd_gcp(ctx: Ctx) -> int:
    phase_6_project(ctx)
    phase_7_data(ctx)
    phase_8_keys_and_secrets(ctx)
    ctx.print_notes()
    say("")
    say("Phases 6, 7 and 8 done. Next: 'walle consent' (phase 9).")
    return 0


# --------------------------------------------------------------------------- #
# Phase 9 — the one interactive consent. Phase 15 (Eve's) is Eve's runbook.
# --------------------------------------------------------------------------- #


def _shred(path: str) -> None:
    """Overwrite then unlink. Not forensically perfect on a modern filesystem,
    but it removes the obvious copy, which is what SETUP.md Phase 9 step 3 asks."""
    try:
        size = os.path.getsize(path)
        with open(path, "r+b") as handle:
            handle.write(os.urandom(max(size, 1)))
            handle.flush()
            os.fsync(handle.fileno())
    finally:
        os.unlink(path)


def store_client_json(ctx: Ctx, path: str, secret: str) -> None:
    if not os.path.isfile(path):
        die("no such file: %s" % path)
    with open(path, "rb") as handle:
        payload = handle.read()
    try:
        json.loads(payload.decode("utf-8"))
    except (ValueError, UnicodeDecodeError):
        die("%s is not the OAuth client JSON downloaded from the console" % path)
    if not secret_exists(ctx, secret):
        die("secret %s does not exist. Run 'walle gcp' first." % secret)
    version = add_secret_version(ctx, secret, payload)
    say("  stored OAuth client as %s version %s" % (secret, version))
    if ctx.dry_run:
        say("  WOULD SHRED %s" % path)
        return
    confirm(ctx, "Shred the local copy at %s?" % path)
    _shred(path)
    step("shredded %s" % path)


def add_secret_version(ctx: Ctx, secret: str, payload: bytes) -> str:
    result = run(
        ctx,
        [
            "gcloud", "secrets", "versions", "add", secret,
            "--location", ctx.need("REGION"),
            "--data-file", "-",
            "--project", ctx.need("PROJECT"),
            "--format", "value(name)",
        ],
        stdin_data=payload,
        stdin_is_secret=True,
    )
    if ctx.dry_run:
        return "<dry-run>"
    name = result.out.strip().splitlines()[-1] if result.out.strip() else ""
    if name:
        return name.rsplit("/", 1)[-1]
    match = re.search(r"version \[(\d+)\]", result.err or "")
    if match:
        return match.group(1)
    die("could not determine the new secret version number for %s" % secret)
    return ""


def read_secret(ctx: Ctx, secret: str, version: str = "latest") -> bytes:
    """Reads a secret into memory only. The value is never printed or written.

    read_only_run, not run: an ordinary run() echoes stdout under --verbose, so
    `walle verify --verbose` and `walle consent --verbose` would print the
    base64 refresh token and the OAuth client secret to the terminal and into
    any captured build log.
    """
    result = read_only_run(
        ctx,
        [
            "gcloud", "secrets", "versions", "access", version,
            "--secret", secret, "--location", ctx.need("REGION"),
            "--project", ctx.need("PROJECT"), "--format", "get(payload.data)",
        ],
    )
    encoded = result.out.strip()
    if not encoded:
        die("secret %s version %s is empty or unreadable" % (secret, version))
    try:
        normalised = encoded.replace("-", "+").replace("_", "/")
        return base64.b64decode(normalised + "=" * (-len(normalised) % 4))
    except (binascii.Error, ValueError) as exc:
        die("could not decode secret %s version %s: %s" % (secret, version, exc))
    return b""


def run_consent(
    ctx: Ctx, client_secret: str, target_secret: str,
    expect_account: str, scopes: Sequence[str], paste_mode: bool,
) -> None:
    """The one interactive step. Prints a URL and waits. Never opens a browser."""
    # Before anything, dry run included: cloud-platform in any form is never
    # requested on the robot (platform HLD §13.1 item 3). A refused list is a
    # refusal of the whole consent, not a trimmed request.
    bad = forbidden_scopes(scopes)
    if bad:
        die("REFUSING the consent: the scope list carries %s. cloud-platform is never "
            "consented on the robot account, in either client." % ", ".join(bad))
    # oauthlib treats any change in the returned scope string, reordering
    # included, as an error. The strict comparison after the exchange is this
    # script's own and is what actually enforces the frozen list.
    os.environ["OAUTHLIB_RELAX_TOKEN_SCOPE"] = "1"
    say("")
    say("  Expecting the consent to be given as: %s" % expect_account)
    say("  Use the CLEAN browser profile. Not incognito in a browser you are")
    say("  signed into: incognito can still carry a session.")
    say("")
    # Above the secret read on purpose. Rehearsing the one irreversible step in
    # the build is exactly what --dry-run is for, and it must not require the
    # artefact it is rehearsing: on a first bootstrap %s has no version yet.
    if ctx.dry_run:
        say("  [dry run] would read %s, print the authorisation URL and wait."
            % client_secret)
        say("  [dry run] nothing stored, no browser opened, no token minted.")
        return
    # Below the dry-run return (2026-09-13): rehearsing a consent needs no
    # Python OAuth library, the same way it needs no stored client.
    _Request, _Credentials, InstalledAppFlow, build = _import_google()
    client_config = json.loads(read_secret(ctx, client_secret).decode("utf-8"))
    flow = InstalledAppFlow.from_client_config(client_config, list(scopes))

    if paste_mode:
        flow.redirect_uri = "http://localhost:8765/"
        url, _state = flow.authorization_url(
            access_type="offline", prompt="consent", include_granted_scopes="false"
        )
        say("  " + "-" * 72)
        say("  COPY THIS URL BY HAND into the clean profile. Do not click it.")
        say("")
        say("  " + url)
        say("")
        say("  After you approve, the browser will show a connection error. That is")
        say("  expected: nothing is listening on localhost:8765. The address bar")
        say("  still holds the code. Copy the WHOLE address and paste it below.")
        say("  " + "-" * 72)
        redirect = input("  redirect URL: ").strip()
        if not redirect:
            die("nothing pasted; refusing to continue")
        # oauthlib refuses a non-https authorization response outright
        # (InsecureTransportError), and the pasted URL is always
        # http://localhost:8765/. google-auth-oauthlib does this exact rewrite
        # inside run_local_server for the same reason, which is why the
        # non-paste branch below is unaffected. Rewriting the scheme on this
        # one string is not the same as setting OAUTHLIB_INSECURE_TRANSPORT,
        # which would relax the check for every flow in the process.
        if redirect.startswith("http://"):
            redirect = "https://" + redirect[len("http://"):]
        elif not redirect.startswith("https://"):
            die(
                "that does not look like the redirect URL. Paste the WHOLE address "
                "bar, starting with http://localhost:8765/."
            )
        flow.fetch_token(authorization_response=redirect)
    else:
        say("  This waits on a local loopback port and prints the URL. It does NOT")
        say("  open a browser: a desktop flow opens the machine's DEFAULT browser,")
        say("  which is signed in as you, and the grant lands on a super admin.")
        say("  Copy the printed URL by hand into the clean profile.")
        flow.run_local_server(
            port=0,
            open_browser=False,
            access_type="offline",
            prompt="consent",
            include_granted_scopes="false",
            authorization_prompt_message="  COPY THIS URL BY HAND:\n\n  {url}\n",
            success_message="Consent recorded. Close this tab and return to the terminal.",
        )

    creds = flow.credentials

    # The account check comes first: consenting as yourself is the dangerous
    # failure, and it must be the message the operator sees.
    email = fetch_consented_email(ctx, creds, build)
    say("  the account that consented is: %s" % email)
    if email.lower() != expect_account.lower():
        die(
            "REFUSING TO STORE. Consent was given as %s, expected %s.\n"
            "This is SETUP.md 7.1, the most likely single mistake in the runbook.\n"
            "Revoke that grant now at https://myaccount.google.com/permissions as %s, "
            "then open a genuinely fresh profile and run this again."
            % (email, expect_account, email)
        )

    if creds.scopes is None:
        die(
            "the token response carried no scope list, so the frozen set cannot be "
            "checked. Refusing to store a grant whose breadth is unknown: scopes "
            "freeze permanently at consent."
        )
    granted = set(creds.scopes)
    missing = [s for s in scopes if s not in granted]
    if missing:
        die("the grant is missing scopes and cannot be widened later: %s" % ", ".join(missing))
    extra = [s for s in granted if s not in scopes]
    if forbidden_scopes(granted):
        die("REFUSING TO STORE: the grant carries %s, which was not requested and is "
            "never allowed on the robot. Revoke the grant as the robot at "
            "https://myaccount.google.com/permissions." % ", ".join(forbidden_scopes(granted)))
    if extra:
        die(
            "the grant carries scopes that were NOT requested: %s\n"
            "Refusing to store: the stored token would be wider than the list you "
            "reviewed. The usual cause is an earlier grant on this same client "
            "accumulating scopes. Revoke it at https://myaccount.google.com/permissions "
            "as the consenting account, create a NEW OAuth client, and run this again."
            % ", ".join(extra)
        )
    if not creds.refresh_token:
        die(
            "no refresh token returned. access_type=offline and prompt=consent were "
            "both requested, so this is a repeat authorisation on a client that "
            "already has one. Revoke the existing grant and retry."
        )
    version = add_secret_version(ctx, target_secret, creds.refresh_token.encode("utf-8"))
    say("")
    say("  " + "=" * 72)
    say("  Stored as %s version %s" % (target_secret, version))
    say("")
    pin_key, service = (("SUPER_REFRESH_TOKEN_VERSION", SUPER_SERVICE)
                        if target_secret == SUPER_CLIENT_SECRETS[1]
                        else ("REFRESH_TOKEN_VERSION", ACTIONS_SERVICE))
    say("  PUT THIS IN THE CONFIG NOW:")
    say("    %s=%s" % (pin_key, version))
    say("  and redeploy %s. It is 1 only on a first clean bootstrap;" % service)
    say("  every rollback and every K4 or K5 drill produces a higher number, and")
    say("  a stale pin points the service at a destroyed version.")
    say("  " + "=" * 72)
    ctx.note("%s is at version %s" % (target_secret, version))


def fetch_consented_email(ctx: Ctx, creds: Any, build: Any) -> str:
    """The check that stops you storing your own super-admin credentials."""
    try:
        service = build("oauth2", "v2", credentials=creds, cache_discovery=False)
        info = service.userinfo().get().execute()
        email = info.get("email", "")
    except Exception as exc:
        raise WalleError(
            "could not call userinfo to identify the consenting account (%s). "
            "Refusing to store a token whose owner is unknown." % exc
        )
    if not email:
        die("userinfo returned no email. Refusing to store.")
    return email


def cmd_consent(ctx: Ctx) -> int:
    section("Phase 9 — the one interactive consent")
    # Wall-E's robot only. Eve's consent (SETUP.md Phase 15) is not a branch of
    # this command any more: an OAuth consent screen and a desktop client are
    # per-GCP-project objects, Eve's client is created on EVE_PROJECT's consent
    # screen and its two secrets live in EVE_PROJECT, readable by
    # eve-controller@ there only. That is eve/07-build-runbook.md Phase 9, and
    # project-topology.md §7.1 (Phase 15) records the move. Refuse loudly
    # rather than store an Eve credential in Wall-E's project.
    if getattr(ctx.args, "eve", False):
        die(
            "'walle consent --eve' no longer exists. Eve's OAuth client, consent and "
            "secrets live in EVE_PROJECT (%s) and are created by Eve's runbook, "
            "eve/07-build-runbook.md Phase 9 (project-topology.md §7.1, Phase 15). "
            "Nothing of Eve's is stored in Wall-E's project."
            % ctx.get("EVE_PROJECT", "<EVE_PROJECT>")
        )
    account = ctx.need("ROBOT")
    band_b = bool(getattr(ctx.args, "super", False))
    if band_b:
        # Client 2, the broad client (2026-09-13, platform HLD §13.1 item 3).
        # Its scope list is a signed decision and *tbd*; nothing is consented
        # without the record, and nothing ever with cloud-platform.
        client_secret, target_secret = SUPER_CLIENT_SECRETS
        decision = os.path.expanduser(ctx.get("SUPER_SCOPES_DECISION") or "")
        if not decision or not os.path.isfile(decision):
            die(
                "'walle consent --super' consents the BROAD client that walle-actions-"
                "super reads. Its scope list is a super-admin-signed decision (decision 3 "
                "re-cut) and SUPER_SCOPES_DECISION (%r) names no existing record. "
                "Nothing ran." % decision
            )
        scopes = tuple(parse_scope_list(ctx.need("SUPER_SCOPES")))
        bad = forbidden_scopes(scopes)
        if bad:
            die("SUPER_SCOPES carries %s; cloud-platform is never consented. Nothing ran."
                % ", ".join(bad))
        missing = [s for s in SCOPES_REQUIRED_IN_EVERY_CLIENT if s not in scopes]
        if missing:
            die("SUPER_SCOPES lacks %s. Nothing ran." % ", ".join(missing))
        say("  Client 2 (broad), decision record: %s" % decision)
        do_manual_step(ctx, "M5S")
    else:
        client_secret, target_secret = NARROW_CLIENT_SECRETS
        scopes = ROBOT_SCOPES
        do_manual_step(ctx, "M5")
    store = getattr(ctx.args, "store_client", None)
    if store:
        store_client_json(ctx, os.path.expanduser(store), client_secret)
    do_manual_step(ctx, "M6")
    do_manual_step(ctx, "M7")
    # `consent` is the one subcommand that is not get-or-create. A second run
    # completes the flow with prompt=consent, mints a SECOND live refresh token
    # on the same client, leaves the first valid, and prints a version number
    # the deployed service is not pinned to. SETUP.md 7.4: one client, one
    # token — past 100 live tokens Google invalidates the oldest silently.
    existing_versions = gcloud_probe_json(
        ctx, "secrets", "versions", "list", target_secret,
        "--location", ctx.need("REGION"), "--filter", "state=ENABLED",
    ) or []
    if existing_versions and not getattr(ctx.args, "rotate", False):
        die(
            "%s already has %d enabled version(s), so a grant already exists.\n"
            "Consenting again mints a SECOND live refresh token on this client and "
            "leaves the first valid. One client, one token (SETUP.md 7.4).\n"
            "If you are genuinely re-bootstrapping: revoke the old grant at "
            "https://myaccount.google.com/permissions as %s, destroy the old "
            "version, then re-run with --rotate. The new number must be re-exported "
            "as %s and %s redeployed, or the service "
            "stays pinned to the version you just destroyed."
            % (target_secret, len(existing_versions), account,
               "SUPER_REFRESH_TOKEN_VERSION" if band_b else "REFRESH_TOKEN_VERSION",
               SUPER_SERVICE if band_b else ACTIONS_SERVICE)
        )
    say("")
    say("  Scopes about to be requested (frozen permanently at consent):")
    for scope in scopes:
        say("    " + scope)
    confirm(ctx, "This scope list is final and cannot be widened later. Proceed?")
    run_consent(
        ctx, client_secret, target_secret, account, scopes,
        bool(getattr(ctx.args, "paste", False)),
    )
    say("")
    say("  Now sign out of the account and close the clean profile. Put the hardware")
    say("  key back in the safe. From here a login alert is an incident.")
    if not ctx.dry_run:
        say("")
        say("  While the credential is in hand, check the stored grant:")
        say("   python bootstrap/verify_token.py --project=%s --region=%s \\"
            % (ctx.need("PROJECT"), ctx.need("REGION")))
        say("     --secret=%s --secret-version=<the number above> \\" % target_secret)
        say("     --expect-account=%s" % ctx.need("ROBOT"))
        say("  Reversed 2026-09-13: the old follow-ups here — finalise the Stage 1")
        say("  custom role from 'walle dump-privileges', and expect a licensing probe")
        say("  to answer 403 because 'License Management waits for Stage 1' — assumed")
        say("  a narrow role. With Super Admin that probe SUCCEEDS; Google refuses")
        say("  nothing but what the scopes exclude, so the account and the exact scope")
        say("  set are what this check proves, and verify's robot_credentials_scoped")
        say("  asserts both for each client.")
    ctx.print_notes()
    return 0


# ensure_eve_secrets is gone on purpose. Eve's secrets are readable by
# eve-controller@ only and walle-actions@ must never appear on them — if they
# shared a credential, "Eve approved this" and "Eve verified this" would both
# mean nothing. That invariant is now STRUCTURAL: the secrets are created in
# EVE_PROJECT by Eve's runbook, where no Wall-E principal exists, and
# check_eve_separation reads them there.


# --------------------------------------------------------------------------- #
# Phases 10, 11, 12, 14 — deploy
# --------------------------------------------------------------------------- #


def repo_path(ctx: Ctx, *parts: str) -> str:
    path = os.path.join(os.path.expanduser(ctx.need("WALLE_REPO")), *parts)
    if not os.path.exists(path):
        die(
            "missing %s.\nPhases 10 to 12 assume the container images and deploy "
            "scripts already exist (SETUP.md 0.4). Run phases 1 to 8 without them; "
            "they are independent of the code." % path
        )
    return path


def repo_sha(ctx: Ctx) -> str:
    repo = os.path.expanduser(ctx.need("WALLE_REPO"))
    result = probe(ctx, ["git", "-C", repo, "rev-parse", "--short", "HEAD"])
    if not result.ok:
        die("cannot read the git sha of %s; images must be tagged by commit" % repo)
    return result.out.strip()


def ensure_artifact_repo(ctx: Ctx) -> None:
    described = gcloud_probe_json(
        ctx, "artifacts", "repositories", "describe", "walle", "--location", ctx.need("REGION")
    )
    if described is not None:
        step("artifact repository exists: walle")
        return
    run(
        ctx,
        [
            "gcloud", "artifacts", "repositories", "create", "walle",
            "--repository-format", "docker", "--location", ctx.need("REGION"),
            "--project", ctx.need("PROJECT"),
        ],
    )


def build_image(ctx: Ctx, source_subdir: str, tag: str) -> str:
    image = "%s/%s" % (ctx.need("AR_REPO"), tag)
    if getattr(ctx.args, "skip_build", False):
        step("--skip-build: reusing %s" % image)
        return image
    source = repo_path(ctx, source_subdir)
    run(ctx, ["gcloud", "builds", "submit", source, "--tag", image,
              "--project", ctx.need("PROJECT")])
    return image


def actions_env_pairs(ctx: Ctx, audience: str) -> List[Tuple[str, str]]:
    project, region = ctx.need("PROJECT"), ctx.need("REGION")
    version = ctx.get("REFRESH_TOKEN_VERSION")
    if not version or not version.isdigit():
        die(
            "REFRESH_TOKEN_VERSION must be the NUMBER Phase 9 printed, not %r.\n"
            "Never 'latest': latest resolves to the newest ENABLED version, so "
            "disabling the newest silently falls back to the previous, still-valid "
            "token and the kill switch does nothing at all." % version
        )
    return [
        ("WORKSPACE_DOMAIN", ctx.need("DOMAIN")),
        ("ROBOT_ACCOUNT", ctx.need("ROBOT")),
        ("OPERATOR_GROUP", ctx.need("OPERATORS")),
        ("READER_GROUP", ctx.need("READERS")),
        ("PROTECTED_GROUP", ctx.need("PROTECTED")),
        ("SECRET_LOCATION", region),
        ("REFRESH_TOKEN_SECRET", "walle-refresh-token"),
        ("REFRESH_TOKEN_VERSION", version),
        ("OAUTH_CLIENT_SECRET", "walle-oauth-client"),
        ("CONFIRM_HMAC_SECRET", "walle-confirm-hmac"),
        # The PRIMARY Eve-approval verification input: the directory of PEMs
        # pinned per key version in Wall-E's repository and baked into the
        # image (SETUP.md Phase 8.1). No cross-project KMS grant is needed.
        ("EVE_PUBLIC_KEY_PEM", EVE_PUBLIC_KEY_PEM_PATH),
        (
            # Eve's key, in EVE_PROJECT (never `project`, which is Wall-E's).
            # Under the design's primary mechanism walle-actions verifies an
            # approval with the PEM pinned in Wall-E's repository; this value
            # is the OPTIONAL KMS fallback path, usable only if Eve's owner has
            # granted publicKeyViewer on this one key (topology row 14).
            "EVE_KMS_KEY",
            "projects/%s/locations/%s/keyRings/%s/cryptoKeys/%s"
            % (ctx.need("EVE_PROJECT"), region, ctx.get("KMS_KEYRING"), ctx.get("KMS_KEY")),
        ),
        ("AUDIT_DATASET", ctx.get("AUDIT_DATASET")),
        (
            "TASKS_QUEUE",
            "projects/%s/locations/%s/queues/%s" % (project, region, ctx.get("TASKS_QUEUE")),
        ),
        # The allowlists are not IAM: IAM run.invoker on walle-actions (per
        # service) is the outer gate, these lists are the per-path gate, and
        # from 2026-09-13 they carry CROSS-PROJECT service-account emails.
        # EXEC stays Wall-E-only.
        ("EXEC_CALLER_ALLOWLIST", ctx.need("SA_AGENT")),
        # eve-controller@ and eve-verifier@ from EVE_PROJECT (project-topology.md
        # §3.1), plus the operators: Eve alone would mean no human can halt or
        # demote, and every kill-switch timing in section 5 becomes unmeasurable.
        ("CONTROL_CALLER_ALLOWLIST", "%s,%s,%s" % (
            ctx.need("SA_EVE"), ctx.need("SA_EVE_VERIFIER"), ctx.need("OPERATORS"))),
        # The read endpoints (GET /v1/plans, /v1/runs, /v1/ladder, /healthz)
        # are allowlisted too, never open to any run.invoker holder:
        # eve-console@ (plans, ladder) and mo-analyst@ (plans, runs) sit here
        # and NEVER on the control list (project-topology.md §3.1, rows 3
        # and 8; SETUP.md Phase 10).
        ("READ_CALLER_ALLOWLIST", ",".join([
            ctx.need("SA_EVE"), ctx.need("SA_EVE_VERIFIER"), ctx.need("SA_EVE_CONSOLE"),
            iam_member(ctx.need("MO_PRINCIPAL")).split(":", 1)[-1],
            ctx.need("SA_OPS_CALLER"), ctx.need("OPERATORS"),
        ])),
        ("INTERNAL_CALLER_ALLOWLIST", ctx.need("SA_DISPATCH")),
        ("AUDIENCE", audience),
    ]


def super_env_pairs(ctx: Ctx, audience: str) -> List[Tuple[str, str]]:
    """walle-actions-super's env (2026-09-13). Its own pair, its own pin.

    The pin is SUPER_REFRESH_TOKEN_VERSION, a NUMBER, never 'latest', for the
    same kill-switch reason as the narrow pin. The allowlists are the HLD's
    invoker set and nothing more: EXEC the agent, CONTROL eve-controller@ and
    (since 2026-09-13, topology row 27) eve-verifier@, halt only. No read list,
    no internal list, no Mo, no dispatcher.
    """
    version = ctx.get("SUPER_REFRESH_TOKEN_VERSION")
    if not version or not version.isdigit():
        die(
            "SUPER_REFRESH_TOKEN_VERSION must be the NUMBER 'walle consent --super' "
            "printed, not %r. Never 'latest'." % version
        )
    return [
        ("WORKSPACE_DOMAIN", ctx.need("DOMAIN")),
        ("ROBOT_ACCOUNT", ctx.need("ROBOT")),
        ("OPERATOR_GROUP", ctx.need("OPERATORS")),
        ("PROTECTED_GROUP", ctx.need("PROTECTED")),
        ("SECRET_LOCATION", ctx.need("REGION")),
        ("REFRESH_TOKEN_SECRET", SUPER_CLIENT_SECRETS[1]),
        ("REFRESH_TOKEN_VERSION", version),
        ("OAUTH_CLIENT_SECRET", SUPER_CLIENT_SECRETS[0]),
        ("EVE_PUBLIC_KEY_PEM", EVE_PUBLIC_KEY_PEM_PATH),
        ("AUDIT_DATASET", ctx.get("AUDIT_DATASET")),
        ("EXEC_CALLER_ALLOWLIST", ctx.need("SA_AGENT")),
        ("CONTROL_CALLER_ALLOWLIST", "%s,%s" % (ctx.need("SA_EVE"), ctx.need("SA_EVE_VERIFIER"))),
        ("AUDIENCE", audience),
    ]


def phase_10_super(ctx: Ctx) -> None:
    """The second action service, bands B and C (platform HLD §13.1 item 3).

    Deployed only once client 2 has been consented: without
    SUPER_REFRESH_TOKEN_VERSION there is no credential for it to hold, and a
    service pinned to nothing is a failure that looks like a bug. That state is
    a note, not a stop, under --dry-run and on a real run alike.
    """
    section("Phase 10 (band B) — walle-actions-super")
    if not ctx.get("SUPER_REFRESH_TOKEN_VERSION"):
        say("  SUPER_REFRESH_TOKEN_VERSION is not set: client 2 has not been consented")
        say("  ('walle consent --super'), so walle-actions-super is NOT deployed.")
        ctx.note("walle-actions-super not deployed: band B client not consented yet")
        return
    image = ctx.get("ACTIONS_SUPER_IMAGE") or build_image(
        # Assumption: the repository carries the band-B service as
        # action-service-super/; the HLD says "two services with one policy
        # library" and names no source layout. ACTIONS_SUPER_IMAGE overrides.
        ctx, "action-service-super", "actions-super:%s" % repo_sha(ctx))
    audience = ctx.get("SUPER_ACTIONS_URL") or current_service_url(ctx, SUPER_SERVICE) or ""
    pairs = super_env_pairs(ctx, audience)
    names = [name for name, _ in pairs]
    if sorted(names) != sorted(SUPER_ENV_NAMES):
        die("the band-B service env set drifted from SUPER_ENV_NAMES: %s" % names)
    run(
        ctx,
        [
            "gcloud", "run", "deploy", SUPER_SERVICE,
            "--image", image,
            "--region", ctx.need("REGION"),
            "--service-account", ctx.need("SA_ACTIONS_SUPER"),
            "--no-allow-unauthenticated",
            # Same reasoning and same drift check as walle-actions until P3's
            # engine-reach spike passes (wall-e/01-hld.md, Cloud Run ingress row).
            "--ingress", "all",
            "--timeout", "60s",
            "--min-instances", "0", "--max-instances", "4", "--concurrency", "8",
            "--set-env-vars", env_flag_value(pairs),
            "--project", ctx.need("PROJECT"),
        ],
    )
    # The invoker set, exactly as wall-e/01-hld.md boundary 2 draws it. NOT the
    # dispatcher ("no route to walle-actions-super, by IAM"), NOT Mo, NOT
    # eve-console@, NOT walle-operators-caller@. eve-verifier@ IS on it since
    # 2026-09-13 (topology row 27), halt only. The agent principal on the
    # AGENT_IDENTITY path is bound in Phase 12b.
    ensure_run_invoker(ctx, SUPER_SERVICE, "serviceAccount:" + ctx.need("SA_AGENT"))
    ensure_run_invoker(ctx, SUPER_SERVICE, "serviceAccount:" + ctx.need("SA_EVE"),
                       foreign="eve-controller@ (EVE_PROJECT, halt path only; "
                               "platform HLD §18 item 25)")
    ensure_run_invoker(ctx, SUPER_SERVICE, "serviceAccount:" + ctx.need("SA_EVE_VERIFIER"),
                       foreign="eve-verifier@ (EVE_PROJECT, halt path only; "
                               "project-topology.md row 27, 2026-09-13)")
    url = current_service_url(ctx, SUPER_SERVICE)
    if url:
        ctx.cfg["SUPER_ACTIONS_URL"] = url
        run(ctx, ["gcloud", "run", "services", "update", SUPER_SERVICE,
                  "--region", ctx.need("REGION"), "--update-env-vars", "AUDIENCE=%s" % url,
                  "--project", ctx.need("PROJECT")])
        say("  SUPER_ACTIONS_URL=%s   <- put this in the config" % url)
        ctx.note("SUPER_ACTIONS_URL=%s" % url)
    say("")
    say("  Open question carried, not invented: the HLD's invoker set for this service")
    say("  has no human halt handle (only eve-controller@ and eve-verifier@), unlike walle-actions,")
    say("  where the operators group can pull the andon cord. Human stops on band B")
    say("  are K5/K6/K7 until that is decided.")
    ctx.note("walle-actions-super: no human halt invoker in the HLD's set (open question)")


def env_flag_value(pairs: Sequence[Tuple[str, str]]) -> str:
    """One --set-env-vars flag, not seventeen.

    gcloud treats it as a dictionary flag: repeating it does not merge, the
    last occurrence wins, and every earlier one is discarded silently. That is
    the correction that matters, and it is why this exists at all.

    The delimiter must appear in NO NAME AND NO VALUE (gcloud topic escaping).
    SETUP.md said "^@^" and the script copied it, which cannot work: eight of
    the seventeen values are email addresses, so gcloud split
    ROBOT_ACCOUNT=walle-bot@example.com into "ROBOT_ACCOUNT=walle-bot" and
    "example.com", and the second has no "=" — "Bad syntax for dict arg". Phase
    10 and Phase 11 could not deploy at all. The old guard checked names only,
    and no name has ever contained an "@".
    """
    for name, value in pairs:
        if ENV_DELIMITER in name:
            die("env var name %s contains the %r delimiter" % (name, ENV_DELIMITER))
        if ENV_DELIMITER in value:
            die(
                "env var %s has a value carrying the %r delimiter, which would "
                "split the --set-env-vars flag: %r" % (name, ENV_DELIMITER, value)
            )
        if "=" in name:
            die("env var name %s contains '=', which gcloud cannot parse" % name)
    joined = ENV_DELIMITER.join("%s=%s" % (name, value) for name, value in pairs)
    return "^%s^%s" % (ENV_DELIMITER, joined)


def dry_run_placeholder(ctx: Ctx, key: str) -> str:
    """A value an earlier phase produces, or a visible stand-in under --dry-run.

    ctx.need() calls die(), so on a project where walle-actions is not deployed
    yet the first `walle --dry-run deploy` aborted two commands into a
    four-phase subcommand — the one dry run an operator actually performs.
    Hard rule 5 says a dry run prints every command it would make.
    """
    value = ctx.get(key)
    if value:
        return value
    if ctx.dry_run:
        return "<%s, produced by an earlier phase>" % key
    return ctx.need(key)


def phase_10_actions(ctx: Ctx) -> None:
    section("Phase 10 — the action service")
    ensure_artifact_repo(ctx)
    image = ctx.get("ACTIONS_IMAGE") or build_image(ctx, "action-service", "actions:%s" % repo_sha(ctx))
    audience = ctx.get("ACTIONS_URL") or current_service_url(ctx, "walle-actions") or ""
    pairs = actions_env_pairs(ctx, audience)
    names = [name for name, _ in pairs]
    if sorted(names) != sorted(ACTIONS_ENV_NAMES):
        die("the action service env set drifted from ACTIONS_ENV_NAMES: %s" % names)
    run(
        ctx,
        [
            "gcloud", "run", "deploy", "walle-actions",
            "--image", image,
            "--region", ctx.need("REGION"),
            "--service-account", ctx.need("SA_ACTIONS"),
            "--no-allow-unauthenticated",
            # --ingress=all looks wrong and is right: Agent Runtime egresses from
            # a Google-managed tenant project, which Cloud Run treats as external,
            # so internal-only blocks the agent entirely and the failure mode is a
            # timeout with no log line at all.
            "--ingress", "all",
            # 60s makes "loop over 25 items inside the approve request"
            # structurally impossible rather than merely discouraged.
            "--timeout", "60s",
            "--min-instances", "0", "--max-instances", "4", "--concurrency", "8",
            "--set-env-vars", env_flag_value(pairs),
            "--project", ctx.need("PROJECT"),
        ],
    )
    # Wall-E's own principals: same project, crosses nothing.
    for member in (
        "serviceAccount:" + ctx.need("SA_AGENT"),
        "serviceAccount:" + ctx.need("SA_DISPATCH"),
        "serviceAccount:" + ctx.need("SA_ACTIONS"),
        "serviceAccount:" + ctx.need("SA_OPS_CALLER"),
        # Without this the andon cord has no handle a human can pull.
        "group:" + ctx.need("OPERATORS"),
    ):
        ensure_run_invoker(ctx, "walle-actions", member)
    # Cross-project principals (project-topology.md rows 3 and 8). The grant
    # is roles/run.invoker ON THE SERVICE walle-actions, in Wall-E's project,
    # to a foreign member — the resource-level form the topology wants; never
    # a project-level role. Cloud Run cannot narrow to paths, so the in-app
    # lists do: controller and verifier on the control list, console and
    # mo-analyst on the read-endpoint list (plans/ladder; plans/runs).
    for label, member in (
        ("eve-controller@ (EVE_PROJECT, control list)", "serviceAccount:" + ctx.need("SA_EVE")),
        ("eve-verifier@ (EVE_PROJECT, control list)",
         "serviceAccount:" + ctx.need("SA_EVE_VERIFIER")),
        ("eve-console@ (EVE_PROJECT, read list: plans, ladder)",
         "serviceAccount:" + ctx.need("SA_EVE_CONSOLE")),
        ("mo-analyst@ (MO_PROJECT, read list: plans, runs)", iam_member(ctx.need("MO_PRINCIPAL"))),
    ):
        ensure_run_invoker(ctx, "walle-actions", member, foreign=label)
    say("")
    say("  READ_CALLER_ALLOWLIST carries eve-console@ (plans, ladder) and mo-analyst@")
    say("  (plans, runs) at their cross-project addresses; neither is on the control")
    say("  list. verify's read_caller_allowlist check asserts both halves.")
    url = current_service_url(ctx, "walle-actions")
    if url:
        ctx.cfg["ACTIONS_URL"] = url
        run(
            ctx,
            [
                "gcloud", "run", "services", "update", "walle-actions",
                "--region", ctx.need("REGION"),
                "--update-env-vars", "AUDIENCE=%s" % url,
                "--project", ctx.need("PROJECT"),
            ],
        )
        say("  ACTIONS_URL=%s   <- put this in the config" % url)
        ctx.note("ACTIONS_URL=%s" % url)
    say("")
    say(
        "  run.invoker is granted per SERVICE, not per path: every one of those "
        "principals can now reach /v1/execute and /v1/control/demote at the HTTP "
        "level. The separation is enforced inside the service by the caller "
        "allowlists above. Denial tests 4, 5 and 51 exist to prove it."
    )
    phase_10_super(ctx)


def ensure_run_invoker(ctx: Ctx, service: str, member: str, foreign: str = "") -> None:
    """run.invoker on one of Wall-E's services. `foreign` names a principal
    from EVE_PROJECT or MO_PROJECT: the binding is still made in Wall-E's
    project (the service is Wall-E's), but a principal IAM reports as
    non-existent — Eve's S3 identities before Eve's runbook Phase 8, Mo's
    before Mo-6 — is a note to re-run `walle deploy`, not a stop."""
    policy = gcloud_probe_json(
        ctx, "run", "services", "get-iam-policy", service, "--region", ctx.need("REGION")
    ) or {}
    for binding in policy.get("bindings", []):
        if binding.get("role") == "roles/run.invoker" and member in binding.get("members", []):
            step("run.invoker present on %s: %s" % (service, member))
            return
    result = run(
        ctx,
        [
            "gcloud", "run", "services", "add-iam-policy-binding", service,
            "--region", ctx.need("REGION"),
            "--member", member, "--role", "roles/run.invoker",
            "--project", ctx.need("PROJECT"),
        ],
        check=not foreign,
    )
    if foreign and not result.ok:
        lowered = (result.err or "").lower()
        if not any(marker in lowered for marker in ABSENT_MARKERS):
            die("cannot bind %s as run.invoker on %s:\n%s" % (member, service, result.err.strip()))
        warn("%s does not exist yet (%s); run.invoker on %s is NOT bound. Re-run "
             "'walle deploy' once the other runbook has created it." % (member, foreign, service))
        ctx.note("PENDING cross-project grant: %s run.invoker on %s (%s)"
                 % (member, service, foreign))


def current_service_url(ctx: Ctx, service: str) -> str:
    described = gcloud_probe_json(
        ctx, "run", "services", "describe", service, "--region", ctx.need("REGION")
    )
    if not described:
        return ""
    return str(described.get("status", {}).get("url", ""))


def phase_11_dispatcher(ctx: Ctx) -> None:
    section("Phase 11 — dispatcher and the two organisation-level log sinks")
    # Tagged by commit sha, like the action service. A floating "latest" makes
    # the deployed artefact unidentifiable after the fact, and --skip-build
    # would reuse whatever latest happens to point at rather than the commit
    # that was reviewed. SETUP.md pins images by `git rev-parse --short HEAD`.
    image = ctx.get("DISPATCHER_IMAGE") or build_image(
        ctx, "dispatcher", "dispatcher:%s" % repo_sha(ctx)
    )
    run(
        ctx,
        [
            "gcloud", "run", "deploy", "walle-dispatcher",
            "--image", image,
            "--region", ctx.need("REGION"),
            "--service-account", ctx.need("SA_DISPATCH"),
            "--no-allow-unauthenticated",
            "--ingress", "all",
            "--timeout", "60s", "--min-instances", "0", "--max-instances", "2",
            "--set-env-vars",
            env_flag_value(
                [
                    ("ACTIONS_URL", dry_run_placeholder(ctx, "ACTIONS_URL")),
                    ("ROBOT_ACCOUNT", ctx.need("ROBOT")),
                    ("REGION", ctx.need("REGION")),
                ]
            ),
            "--project", ctx.need("PROJECT"),
        ],
    )
    url = current_service_url(ctx, "walle-dispatcher")
    if url:
        ctx.cfg["DISPATCHER_URL"] = url
        say("  DISPATCHER_URL=%s   <- put this in the config" % url)
        ctx.note("DISPATCHER_URL=%s" % url)
    # Without these bindings the push subscription, all four scheduler jobs and
    # the inbox push all get 403, and the dispatcher log stays empty, which reads
    # exactly like the internal-ingress symptom and sends you down the wrong path.
    for member in (
        "serviceAccount:" + ctx.need("SA_DISPATCH"),
        "serviceAccount:" + ctx.need("SA_OPS_CALLER"),
    ):
        ensure_run_invoker(ctx, "walle-dispatcher", member)
    number = project_number(ctx)
    if not number:
        die("PROJECT_NUMBER is unknown; phases 11 and 12 need it")
    pubsub_sa = "service-%s@gcp-sa-pubsub.iam.gserviceaccount.com" % number
    ensure_project_binding(
        ctx, "serviceAccount:" + pubsub_sa, "roles/iam.serviceAccountTokenCreator"
    )
    phase_11_sinks(ctx, pubsub_sa)


def phase_11_sinks(ctx: Ctx, pubsub_sa: str) -> None:
    # Platform HLD §18 item 5 and item 25 (2026-09-13): Wall-E's two
    # organisation sinks are to be deleted and re-homed as P104's aggregated
    # sinks into LOGGING_PROJECT plus a log view per agent (platform 08 §3,
    # §5.4); gate: before Wall-E's Stage 1. LOGGING_PROJECT and the log view
    # are not built yet, so these sinks stay until the re-home lands. Both sink
    # names are on the hard-denied list (HD-10) from today.
    project, robot = ctx.need("PROJECT"), ctx.need("ROBOT")
    trigger_filter = (
        'protoPayload.serviceName="admin.googleapis.com" AND '
        'protoPayload.authenticationInfo.principalEmail!="%s"' % robot
    )
    bq_filter = 'protoPayload.serviceName="admin.googleapis.com"'
    w1 = ensure_sink(
        ctx, "walle-workspace-audit",
        "pubsub.googleapis.com/projects/%s/topics/walle-triggers" % project,
        trigger_filter,
    )
    say(
        "  The actor exclusion is not optional: without it every write Wall-E makes "
        "matches the filter, triggers a run, and that run writes again (attack A5)."
    )
    w2 = ensure_sink(
        ctx, "walle-audit-bq",
        "bigquery.googleapis.com/projects/%s/datasets/%s" % (project, ctx.get("LOGS_DATASET")),
        bq_filter,
    )
    say(
        "  The BigQuery sink has NO actor exclusion, deliberately: reconciliation "
        "needs every admin event attributable to the robot in order to find the "
        "ones Wall-E has no audit row for."
    )
    if w1:
        ensure_topic_binding(ctx, "walle-triggers", w1, "roles/pubsub.publisher")
    if w2:
        add_dataset_access(
            ctx, ctx.get("LOGS_DATASET"), "roles/bigquery.dataEditor",
            w2.split(":", 1)[-1],
        )
    ensure_topic_binding(
        ctx, "walle-dead-letter", "serviceAccount:" + pubsub_sa, "roles/pubsub.publisher"
    )
    ensure_push_subscription(
        ctx, "walle-triggers-push", "walle-triggers",
        "%s/events" % dry_run_placeholder(ctx, "DISPATCHER_URL"),
    )
    ensure_subscription(ctx, "walle-dead-letter-hold", "walle-dead-letter")
    ensure_subscription_binding(
        ctx, "walle-triggers-push", "serviceAccount:" + pubsub_sa, "roles/pubsub.subscriber"
    )


def ensure_sink(ctx: Ctx, name: str, destination: str, log_filter: str) -> str:
    """Organisation level: Workspace audit logs land there, so a project-level
    sink cannot see them. Needs org-level roles/logging.configWriter."""
    org = ctx.need("ORG_ID")
    described = gcloud_probe_json(ctx, "logging", "sinks", "describe", name,
                                  "--organization", org)
    if described is None:
        run(
            ctx,
            [
                "gcloud", "logging", "sinks", "create", name, destination,
                "--organization", org, "--include-children",
                "--log-filter", log_filter,
            ],
        )
        described = gcloud_probe_json(ctx, "logging", "sinks", "describe", name,
                                      "--organization", org)
        return str((described or {}).get("writerIdentity", ""))
    step("sink exists: %s" % name)
    if described.get("filter", "").strip() != log_filter:
        warn("sink %s has a different filter; updating it" % name)
        say("    have: %s" % described.get("filter"))
        say("    want: %s" % log_filter)
        run(
            ctx,
            [
                "gcloud", "logging", "sinks", "update", name,
                "--organization", org, "--log-filter", log_filter,
            ],
        )
    return str(described.get("writerIdentity", ""))


def ensure_topic_binding(ctx: Ctx, topic: str, member: str, role: str) -> None:
    policy = gcloud_probe_json(ctx, "pubsub", "topics", "get-iam-policy", topic) or {}
    for binding in policy.get("bindings", []):
        if binding.get("role") == role and member in binding.get("members", []):
            step("topic binding present: %s -> %s on %s" % (member, role, topic))
            return
    run(
        ctx,
        [
            "gcloud", "pubsub", "topics", "add-iam-policy-binding", topic,
            "--member", member, "--role", role, "--project", ctx.need("PROJECT"),
        ],
    )


def ensure_subscription_binding(ctx: Ctx, sub: str, member: str, role: str) -> None:
    policy = gcloud_probe_json(ctx, "pubsub", "subscriptions", "get-iam-policy", sub) or {}
    for binding in policy.get("bindings", []):
        if binding.get("role") == role and member in binding.get("members", []):
            step("subscription binding present: %s -> %s" % (member, role))
            return
    run(
        ctx,
        [
            "gcloud", "pubsub", "subscriptions", "add-iam-policy-binding", sub,
            "--member", member, "--role", role, "--project", ctx.need("PROJECT"),
        ],
    )


def ensure_subscription(ctx: Ctx, name: str, topic: str) -> None:
    if gcloud_probe_json(ctx, "pubsub", "subscriptions", "describe", name) is not None:
        step("subscription exists: %s" % name)
        return
    run(ctx, ["gcloud", "pubsub", "subscriptions", "create", name, "--topic", topic,
              "--project", ctx.need("PROJECT")])


def ensure_push_subscription(ctx: Ctx, name: str, topic: str, endpoint: str) -> None:
    described = gcloud_probe_json(ctx, "pubsub", "subscriptions", "describe", name)
    if described is not None:
        current = (described.get("pushConfig", {}) or {}).get("pushEndpoint", "")
        if current == endpoint:
            step("subscription exists with the right endpoint: %s" % name)
            return
        # A service recreated after teardown gets a new run.app hostname, and a
        # subscription left pointing at the old one drains into the dead-letter
        # topic after five attempts. The symptom is an empty dispatcher log,
        # which SETUP.md 7.3 says reads exactly like the internal-ingress
        # failure and sends you down the wrong path.
        warn("%s pushes at %r, not %r; updating" % (name, current, endpoint))
        run(
            ctx,
            [
                "gcloud", "pubsub", "subscriptions", "update", name,
                "--push-endpoint", endpoint,
                "--push-auth-service-account", ctx.need("SA_DISPATCH"),
                "--project", ctx.need("PROJECT"),
            ],
        )
        return
    _create_push_subscription(ctx, name, topic, endpoint)


def _create_push_subscription(ctx: Ctx, name: str, topic: str, endpoint: str) -> None:
    run(
        ctx,
        [
            "gcloud", "pubsub", "subscriptions", "create", name,
            "--topic", topic,
            "--push-endpoint", endpoint,
            "--push-auth-service-account", ctx.need("SA_DISPATCH"),
            "--ack-deadline", "10",
            "--dead-letter-topic", "walle-dead-letter",
            "--max-delivery-attempts", "5",
            "--project", ctx.need("PROJECT"),
        ],
    )


# There is no `reasoning-engines` command group anywhere in gcloud — not under
# `gcloud ai`, `gcloud beta ai` or `gcloud alpha ai`. Every such call answers
# "Invalid choice: 'reasoning-engines'", which matches no ABSENT_MARKER, so
# gcloud_probe_json raised and `deploy`, `verify`, `status` and `teardown` all
# died on it. SETUP.md gives the escape hatch and the script had dropped it:
# use the regional Agent Runtime REST API directly.
AIPLATFORM_API_VERSION = "v1beta1"


def aiplatform_url(ctx: Ctx, suffix: str) -> str:
    """A regional aiplatform endpoint. The region is part of the HOST, not a query."""
    return "https://%s-aiplatform.googleapis.com/%s/%s" % (
        ctx.need("REGION"), AIPLATFORM_API_VERSION, suffix.lstrip("/")
    )


def engine_collection_path(ctx: Ctx) -> str:
    return "projects/%s/locations/%s/reasoningEngines" % (
        ctx.need("PROJECT"), ctx.need("REGION")
    )


def list_engines(ctx: Ctx) -> List[Dict[str, Any]]:
    status, payload = http_json(
        ctx, "GET", aiplatform_url(ctx, engine_collection_path(ctx)),
        access_token(ctx), mutating=False,
    )
    if status == 404:
        # No engine has ever been created in this project and region.
        return []
    if status != 200 or not isinstance(payload, dict):
        die(
            "cannot list reasoning engines (HTTP %s): %s\n"
            "There is no `gcloud ai reasoning-engines` group; this is the Agent "
            "Runtime REST API on %s-aiplatform.googleapis.com."
            % (status, str(payload)[:300], ctx.need("REGION"))
        )
    return list(payload.get("reasoningEngines", []) or [])


def describe_engine(ctx: Ctx, engine_id: str) -> Optional[Dict[str, Any]]:
    status, payload = http_json(
        ctx, "GET",
        aiplatform_url(ctx, "%s/%s" % (engine_collection_path(ctx), engine_id)),
        access_token(ctx), mutating=False,
    )
    if status != 200 or not isinstance(payload, dict):
        return None
    return payload


def resolve_engine_id(ctx: Ctx) -> str:
    """ENGINE_ID from the config, or from the region when exactly one exists."""
    if ctx.get("ENGINE_ID"):
        return ctx.get("ENGINE_ID")
    engines = list_engines(ctx)
    if len(engines) == 1:
        found = str(engines[0].get("name", "")).rsplit("/", 1)[-1]
        ctx.cfg["ENGINE_ID"] = found
        return found
    return ""


def phase_12_agent(ctx: Ctx) -> None:
    section("Phase 12 — the agent on Agent Runtime")
    # SETUP.md Phase 12b. identity_type is fixed at create and cannot be
    # patched, so the mode is resolved (and the fallback's gate checked) before
    # anything mutates, and its prerequisites are proven BEFORE the engine exists.
    mode = agent_identity_mode(ctx)
    number = project_number(ctx)
    if not number:
        die("PROJECT_NUMBER is unknown; phase 12 cannot name the service agents")
    run(
        ctx,
        [
            "gcloud", "beta", "services", "identity", "create",
            "--service", "aiplatform.googleapis.com", "--project", ctx.need("PROJECT"),
        ],
    )
    ensure_agent_identity_prereqs(ctx)
    if mode == "SERVICE_ACCOUNT":
        # Deploying under a custom service account needs the Reasoning Engine service
        # agent to hold tokenCreator ON that account. It grants nothing TO the agent,
        # so the "reads no secret" property verified in Phase 8 is untouched.
        ensure_sa_binding(
            ctx, ctx.need("SA_AGENT"),
            "serviceAccount:service-%s@gcp-sa-aiplatform-re.iam.gserviceaccount.com" % number,
            "roles/iam.serviceAccountTokenCreator",
        )
    else:
        say("  AGENT_IDENTITY: no service_account is passed and the Reasoning Engine")
        say("  service agent gets NO serviceAccountTokenCreator on walle-agent@. The")
        say("  engine's principal is read back after the deploy, never typed by hand.")

    before = list_engines(ctx)
    existing = [e for e in before if e.get("displayName") == ctx.get("ENGINE_DISPLAY_NAME")]
    if len(existing) > 1:
        die(
            "%d engines already carry the display name %s. The IAM lockdown applies "
            "to one id only, so an orphan sits there with whatever the project "
            "policy grants. Delete the orphans first: %s"
            % (len(existing), ctx.get("ENGINE_DISPLAY_NAME"),
               ", ".join(e.get("name", "?") for e in existing))
        )
    engine_name = existing[0]["name"] if existing else ""
    if engine_name:
        ctx.cfg["ENGINE_ID"] = engine_name.rsplit("/", 1)[-1]
        say("  an engine already exists: %s" % engine_name)
        say("  redeploying is UPDATE, never CREATE: create is not idempotent and")
        say("  produces a second, still-invocable engine with a new id.")
    deploy_script = repo_path(ctx, "agent", "deploy.py")
    env = {
        "PROJECT": ctx.need("PROJECT"),
        "REGION": ctx.need("REGION"),
        "ACTIONS_URL": dry_run_placeholder(ctx, "ACTIONS_URL"),
        "STAGING_BUCKET": ctx.need("STAGING_BUCKET"),
        # The contract with the repo's deploy.py: non-empty means call
        # agent_engines.update(name=...), empty means create.
        "WALLE_ENGINE_NAME": engine_name,
        # SETUP.md Phase 12 names four properties this deployment must have,
        # each with its reason. They were neither passed, printed, nor checked.
        "MIN_INSTANCES": "0",              # min_instances=1 bills around the clock
        "ENABLE_MEMORY_BANK": "false",     # no long-term memories about employees
        "ENABLE_CODE_EXECUTION": "false",  # no EU at-rest residency
    }
    env.update(agent_deploy_env(ctx, mode))
    say("  contract with deploy.py:")
    say("    - call update() when WALLE_ENGINE_NAME is set; create is not idempotent")
    if mode == "SERVICE_ACCOUNT":
        say("    - run as %s (SERVICE_ACCOUNT fallback, spike recorded at %s)"
            % (ctx.need("SA_AGENT"), ctx.get("AGENT_IDENTITY_SPIKE_RESULT")))
    else:
        say("    - identity_type AGENT_IDENTITY and NO service_account in the config")
    if env.get("AGENT_GATEWAY"):
        say("    - agent_gateway_config.client_to_agent_config.agent_gateway = %s"
            % env["AGENT_GATEWAY"])
    say("    - env_vars from AGENT_ENV_VARS (%s): telemetry on, and"
        % ", ".join(name for name, _ in AGENT_TELEMETRY_ENV))
    say("      ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS=false, or tool arguments carrying")
    say("      employee data land in Cloud Trace")
    say("    - min_instances 0: 1 bills around the clock")
    say("    - Sessions with Memory Bank OFF: an admin agent must not accumulate")
    say("      long-term memories about employees")
    say("    - Code Execution OFF: it has no EU at-rest residency")
    say("  check_engine_properties in verify asserts all four afterwards.")
    run(ctx, [sys.executable, deploy_script], env=env)

    after = list_engines(ctx)
    if not ctx.dry_run:
        names_before = {e.get("name") for e in before}
        new = [e for e in after if e.get("name") not in names_before]
        if engine_name and new:
            die(
                "an engine already existed and deploy.py created ANOTHER one: %s\n"
                "Delete it now — there is no gcloud command for this, so:\n"
                "  curl -X DELETE -H \"Authorization: Bearer $(gcloud auth "
                "print-access-token)\" \\\n"
                "    https://%s-aiplatform.googleapis.com/%s/<name>\n"
                "Then fix deploy.py to honour WALLE_ENGINE_NAME."
                % (", ".join(str(e.get("name")) for e in new), ctx.need("REGION"),
                   AIPLATFORM_API_VERSION)
            )
        if len(after) != 1:
            spikes = [e for e in after if e.get("displayName") == SPIKE_DISPLAY_NAME]
            die(
                "expected exactly one reasoning engine in the region, found %d%s"
                % (len(after),
                   ". A throwaway spike engine is still there: run "
                   "'walle rollback --phase 12b' first." if spikes else "")
            )
        engine_name = str(after[0]["name"])
        ctx.cfg["ENGINE_ID"] = engine_name.rsplit("/", 1)[-1]
        say("  ENGINE_ID=%s   <- put this in the config" % ctx.cfg["ENGINE_ID"])
        ctx.note("ENGINE_ID=%s" % ctx.cfg["ENGINE_ID"])
    phase_12b_identity(ctx, mode)
    lock_engine_iam(ctx)


def gemini_access_fallback_on_file(ctx: Ctx) -> bool:
    """Decision 42's gate, patterned on AGENT_IDENTITY_SPIKE_RESULT.

    The config key GEMINI_ACCESS_SPIKE_RESULT (walle.env.example) points at
    the recorded result — a JSON file {"verdict": "pass"|"fail"} — of
    attempting Phase 13's registration and one query with ONLY the
    engine-scoped custom role in place. Google documents only the
    project-level roles/discoveryengine.serviceAgent for the cross-project
    case; the narrower grant is the design's, and it is unverified. The
    fallback is applied only when the file on disk says the spike FAILED.
    """
    path = os.path.expanduser(ctx.get("GEMINI_ACCESS_SPIKE_RESULT") or "")
    if not path or not os.path.isfile(path):
        return False
    return spike_verdict(path) == "fail"


def lock_engine_iam(ctx: Ctx) -> None:
    """Two principals and no others, ever.

    Gemini Enterprise passes the signed-in user's email as user_id. That email is
    asserted by the calling service, not cryptographically bound to the user, and
    is trustworthy exactly to the extent that only trusted callers can invoke.

    The two: the Gemini Enterprise APP project's Discovery Engine service
    agent, named by GEMINI_PROJECT_NUMBER and never by Wall-E's PROJECT_NUMBER
    (project-topology.md row 1), and walle-dispatcher@ (same project).
    eve-controller@ is NOT a member any more: a query principal asserts
    user_id, and Eve verifying through the agent would be Eve verifying
    through the thing it verifies (C10, topology row 13).
    """
    project = ctx.need("PROJECT")
    number = gemini_project_number(ctx)
    if not number:
        if not ctx.dry_run:
            die("GEMINI_PROJECT_NUMBER is unknown and could not be read from "
                "GEMINI_PROJECT %s. The engine policy names the app's service agent by "
                "that number; fill it in (project-topology.md §7.4 step 1)."
                % ctx.need("GEMINI_PROJECT"))
        number = "<gemini-project-number>"
    # There is no predefined roles/aiplatform.reasoningEngineUser. set-iam-policy
    # with a non-existent role fails INVALID_ARGUMENT and the engine silently
    # keeps whatever it inherits from the project.
    described = gcloud_probe_json(ctx, "iam", "roles", "describe", "walleEngineQuery",
                                  "--project", project)
    if described is None:
        run(
            ctx,
            [
                "gcloud", "iam", "roles", "create", "walleEngineQuery", "--project", project,
                "--title", "Wall-E engine query",
                "--description", "Query the wall-e reasoning engine. Nothing else.",
                "--permissions", "aiplatform.reasoningEngines.query",
                "--stage", "GA",
            ],
        )
    elif described.get("deleted"):
        run(ctx, ["gcloud", "iam", "roles", "undelete", "walleEngineQuery",
                  "--project", project])
    else:
        step("custom role exists: walleEngineQuery")
    engine_id = resolve_engine_id(ctx)
    if not engine_id:
        if not ctx.dry_run:
            die("ENGINE_ID is unknown; cannot lock the engine's IAM policy")
        engine_id = "<engine-id>"
    gemini_agent = (
        "serviceAccount:service-%s@gcp-sa-discoveryengine.iam.gserviceaccount.com" % number
    )
    policy = {
        "bindings": [
            {
                "role": "projects/%s/roles/walleEngineQuery" % project,
                "members": [
                    gemini_agent,
                    "serviceAccount:" + ctx.need("SA_DISPATCH"),
                ],
            }
        ]
    }
    say("  engine IAM policy -> exactly two members:")
    for member in policy["bindings"][0]["members"]:
        say("    " + member)
    say("  (the service agent is GEMINI_PROJECT %s's, number %s — not Wall-E's; "
        "eve-controller@ is deliberately absent, C10)" % (ctx.need("GEMINI_PROJECT"), number))
    url = aiplatform_url(
        ctx, "%s/%s:setIamPolicy" % (engine_collection_path(ctx), engine_id)
    )
    if ctx.dry_run:
        say("  WOULD POST %s" % url)
        say("    body: %s" % json.dumps({"policy": policy}))
    else:
        confirm(ctx, "Apply this engine IAM policy?")
        status, body = http_json(ctx, "POST", url, access_token(ctx), {"policy": policy})
        if status != 200:
            die(
                "setIamPolicy on engine %s returned HTTP %s: %s\n"
                "Without this the engine keeps whatever the project policy grants, and "
                "the asserted end-user email from Gemini Enterprise means nothing."
                % (engine_id, status, str(body)[:300])
            )
    # Decision 42: the engine-scoped custom role is the grant (row 1). Google's
    # documented project-level role (row 2) is applied ONLY when the recorded
    # spike says row 1 was not enough, and then it is the topology's single
    # named project-level exception, written down with the failing error.
    if gemini_access_fallback_on_file(ctx):
        warn("GEMINI_ACCESS_SPIKE_RESULT says the engine-scoped role was NOT enough "
             "cross-project: applying Google's documented fallback %s at PROJECT level "
             "in %s to %s. This is decision 42's one named project-level exception; "
             "record it, and re-test at each engine redeploy so it can be removed."
             % (GEMINI_FALLBACK_ROLE, project, gemini_agent))
        ensure_project_binding(ctx, gemini_agent, GEMINI_FALLBACK_ROLE)
        ctx.note("decision 42 fallback applied: %s project-level to %s"
                 % (GEMINI_FALLBACK_ROLE, gemini_agent))
    else:
        say("  No project-level role for the service agent: the engine-scoped grant is")
        say("  the spike of decision 42. If Phase 13's registration or the first query")
        say("  fails, record the result in GEMINI_ACCESS_SPIKE_RESULT and re-run deploy.")
    say(
        "  Confirm the Discovery Engine service agent's exact address on the IAM "
        "page of GEMINI_PROJECT %s with 'Include Google-provided role grants' on: it "
        "is created lazily, in the APP's project, when the Gemini Enterprise app "
        "first runs." % ctx.need("GEMINI_PROJECT")
    )


# --------------------------------------------------------------------------- #
# Phase 12b — the agent's identity: Agent Identity, with a gated fallback
# (SETUP.md Phase 12b, 12-agent-identity.md section 8.1)
# --------------------------------------------------------------------------- #


def ensure_apis_listed(ctx: Ctx, apis: Sequence[str], label: str) -> None:
    """ensure_apis for a phase-specific list. Same get-or-enable shape."""
    enabled = _dry_run_list(ctx, "enabled services", "services", "list", "--enabled")
    if enabled is None:
        say("  [dry run] would enable %d %s APIs: %s" % (len(apis), label, ", ".join(apis)))
        return
    have = {item.get("config", {}).get("name") for item in enabled}
    missing = [api for api in apis if api not in have]
    if not missing:
        step("%s APIs already enabled: %s" % (label, ", ".join(apis)))
        return
    say("  enabling %s APIs: %s" % (label, ", ".join(missing)))
    run(ctx, ["gcloud", "services", "enable"] + missing + ["--project", ctx.need("PROJECT")])


def api_is_enabled(ctx: Ctx, api: str) -> Optional[bool]:
    """None only under --dry-run on a project that does not exist yet."""
    enabled = _dry_run_list(ctx, "enabled services", "services", "list", "--enabled")
    if enabled is None:
        return None
    return api in {item.get("config", {}).get("name") for item in enabled}


def ensure_org_policy_enforced(ctx: Ctx, constraint: str) -> None:
    """Set explicitly on the project rather than inherited (Phase 12b step 1)."""
    project = ctx.need("PROJECT")
    described = gcloud_probe_json(ctx, "org-policies", "describe", constraint,
                                  "--project", project)
    rules = ((described or {}).get("spec", {}) or {}).get("rules", []) or []
    if any(rule.get("enforce") is True for rule in rules):
        step("org policy enforced on the project: %s" % constraint)
        return
    policy_text = (
        "name: projects/%s/policies/%s\nspec:\n  rules:\n  - enforce: true\n"
        % (project, constraint)
    )
    path = ctx.scratch_file("policy-%s.yaml" % constraint, policy_text)
    run(ctx, ["gcloud", "org-policies", "set-policy", path, "--project", project])


def agent_identity_mode(ctx: Ctx) -> str:
    """AGENT_IDENTITY by default. SERVICE_ACCOUNT only with the spike on file.

    The fallback is gated on purpose: identity_type is fixed for the life of
    the engine, so "just use the service account for now" is a decision that
    must carry the evidence that forced it (decision 19).
    """
    mode = ctx.get("AGENT_IDENTITY_MODE") or "AGENT_IDENTITY"
    if mode not in AGENT_IDENTITY_MODES:
        die("AGENT_IDENTITY_MODE must be one of %s" % "/".join(AGENT_IDENTITY_MODES))
    spike_file = os.path.expanduser(ctx.get("AGENT_IDENTITY_SPIKE_RESULT") or "")
    if mode == "SERVICE_ACCOUNT":
        if not spike_file or not os.path.isfile(spike_file):
            die(
                "AGENT_IDENTITY_MODE=SERVICE_ACCOUNT is the gated fallback, and "
                "AGENT_IDENTITY_SPIKE_RESULT (%r) does not name an existing file.\n"
                "Run 'walle spike' first: the fallback is only allowed with the "
                "spike's recorded output attached to the decision record "
                "(SETUP.md Phase 12b step 4)." % spike_file
            )
        say("  identity mode: SERVICE_ACCOUNT (fallback; spike recorded at %s)" % spike_file)
        return mode
    if spike_file and os.path.isfile(spike_file):
        verdict = spike_verdict(spike_file)
        if verdict == "fail":
            die(
                "the recorded spike at %s says FAIL, and AGENT_IDENTITY_MODE is still "
                "AGENT_IDENTITY. An engine deployed now could never reach the action "
                "service and could never change identity in place. Either re-run "
                "'walle spike' or set AGENT_IDENTITY_MODE=SERVICE_ACCOUNT." % spike_file
            )
        say("  identity mode: AGENT_IDENTITY (spike at %s: %s)" % (spike_file, verdict))
    else:
        say("  identity mode: AGENT_IDENTITY (no spike result on file; the deploy "
            "reads the identity back and fails if it is not one)")
    return mode


def spike_verdict(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8") as handle:
            payload = json.load(handle)
    except (OSError, ValueError):
        return "unreadable"
    return str((payload or {}).get("verdict", "unknown"))


def check_agent_package_hygiene(ctx: Ctx, mode: str) -> None:
    """Phase 12b step 2, the CI checks, run here too because CI may not exist yet."""
    repo = os.path.expanduser(ctx.need("WALLE_REPO"))
    agent_dir = os.path.join(repo, "agent")
    if grep_tree(agent_dir, (TOKEN_SHARING_OPTOUT,)):
        die(
            "%s appears in the agent package (%s). It unbinds tokens from the "
            "runtime certificate and is refused anywhere in the deploy config."
            % (TOKEN_SHARING_OPTOUT, agent_dir)
        )
    config_path = os.path.join(agent_dir, ".agent_engine_config.json")
    if os.path.isfile(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as handle:
                committed = json.load(handle)
        except ValueError as exc:
            die("%s is not valid JSON: %s" % (config_path, exc))
        committed_type = str((committed or {}).get("identity_type", ""))
        if committed_type and committed_type != mode:
            die(
                "%s says identity_type %r but AGENT_IDENTITY_MODE is %r. The SDK "
                "may read that file; the two must agree." % (config_path, committed_type, mode)
            )
    requirements = os.path.join(agent_dir, "requirements.txt")
    if mode == "AGENT_IDENTITY":
        if not os.path.isfile(requirements):
            warn("no %s: cannot prove google-auth>=2.45.0 is pinned (the version that "
                 "binds tokens to the certificate)" % requirements)
        else:
            with open(requirements, "r", encoding="utf-8") as handle:
                pinned = any(re.match(r"^google-auth>=2\.(4[5-9]|[5-9]\d|\d{3,})", line.strip())
                             for line in handle)
            if not pinned:
                die(
                    "%s does not pin google-auth>=2.45.0, the version that binds "
                    "tokens to the agent's certificate (Phase 12b step 2)." % requirements
                )


def grep_tree(root: str, needles: Sequence[str], suffixes: Tuple[str, ...] = (".py", ".json", ".txt", ".toml", ".cfg", ".yaml", ".yml")) -> List[str]:
    """Which files under root contain any needle. Textual, like lint_ladder_config."""
    hits: List[str] = []
    if not os.path.isdir(root):
        return hits
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if not d.startswith(".") and d != "__pycache__"]
        for filename in filenames:
            if not filename.endswith(suffixes) and not filename.startswith("."):
                continue
            path = os.path.join(dirpath, filename)
            try:
                with open(path, "r", encoding="utf-8", errors="replace") as handle:
                    text = handle.read()
            except OSError:
                continue
            if any(needle in text for needle in needles):
                hits.append(path)
    return hits


def ensure_agent_identity_prereqs(ctx: Ctx) -> None:
    """Phase 12b step 1: the API on, the credentials API OFF, key constraints set."""
    say("")
    say("  Phase 12b step 1: %s on, %s OFF, and the two service-account-key"
        % (AGENT_IDENTITY_API, AGENT_IDENTITY_CREDENTIALS_API))
    say("  constraints set explicitly on the project rather than inherited.")
    ensure_apis_listed(ctx, (AGENT_IDENTITY_API,), "agent identity")
    credentials = api_is_enabled(ctx, AGENT_IDENTITY_CREDENTIALS_API)
    if credentials is True:
        die(
            "%s is ENABLED on %s. It must stay disabled so no auth provider can "
            "ever be exercised in this project. This script disables nothing; "
            "disable it yourself and re-run:\n  gcloud services disable %s --project=%s"
            % (AGENT_IDENTITY_CREDENTIALS_API, ctx.need("PROJECT"),
               AGENT_IDENTITY_CREDENTIALS_API, ctx.need("PROJECT"))
        )
    if credentials is False:
        step("%s is disabled, as required" % AGENT_IDENTITY_CREDENTIALS_API)
    for constraint in AGENT_KEY_CONSTRAINTS:
        ensure_org_policy_enforced(ctx, constraint)


def gateway_resource_name(ctx: Ctx, name: str) -> str:
    if name.startswith("projects/"):
        return name
    return "projects/%s/locations/%s/agentGateways/%s" % (
        ctx.need("PROJECT"), ctx.need("REGION"), name)


def agent_deploy_env(ctx: Ctx, mode: str) -> Dict[str, str]:
    """The Phase 12b/12c half of the deploy.py contract.

    IDENTITY_TYPE always; SERVICE_ACCOUNT only on the fallback, because passing
    it alongside AGENT_IDENTITY is exactly the mistake that pins walle-agent@
    for the life of the engine. AGENT_GATEWAY when the ingress gateway exists.
    AGENT_ENV_VARS in the same escaped-list form as Cloud Run, validated
    against the delimiter, with the four telemetry variables.
    """
    check_agent_package_hygiene(ctx, mode)
    env = {"IDENTITY_TYPE": mode}
    if mode == "SERVICE_ACCOUNT":
        env["SERVICE_ACCOUNT"] = ctx.need("SA_AGENT")
    gateway = ctx.get("INGRESS_GATEWAY")
    if gateway:
        env["AGENT_GATEWAY"] = gateway_resource_name(ctx, gateway)
    else:
        say("  INGRESS_GATEWAY is not set: the engine is NOT bound to a Model Armor")
        say("  ingress gateway. Run 'walle armor' first and set INGRESS_GATEWAY=%s;"
            % INGRESS_GATEWAY_NAME)
        say("  the binding is create-time on some pages, so do it before the first deploy.")
    pairs = list(AGENT_TELEMETRY_ENV)
    if any(name == TOKEN_SHARING_OPTOUT for name, _ in pairs):
        die("%s must never be set" % TOKEN_SHARING_OPTOUT)
    env["AGENT_ENV_VARS"] = env_flag_value(pairs)
    return env


def read_effective_identity(ctx: Ctx, engine_id: str) -> str:
    described = describe_engine(ctx, engine_id)
    if described is None:
        return ""
    return str((described.get("spec", {}) or {}).get("effectiveIdentity", "") or "")


def principal_for(effective: str, number: str, region: str, engine_id: str) -> str:
    """principal://<trust domain>/resources/aiplatform/projects/<n>/locations/<r>/reasoningEngines/<id>.

    Built from the value READ BACK, whichever of the two shapes the API uses:
    the bare trust domain, or the domain with the resource path already on it.
    """
    if "/resources/" in effective:
        return "principal://" + effective
    return "principal://%s/resources/aiplatform/projects/%s/locations/%s/reasoningEngines/%s" % (
        effective, number, region, engine_id)


def agent_principal(ctx: Ctx) -> str:
    """The production engine's principal, from spec.effectiveIdentity. Never typed."""
    engine_id = resolve_engine_id(ctx)
    number = project_number(ctx)
    region = ctx.need("REGION")
    expected_domain = "%s%s.system.id.goog" % (AGENT_TRUST_DOMAIN_PREFIX, ctx.need("ORG_ID"))
    if not engine_id or not number:
        if ctx.dry_run:
            return principal_for(expected_domain, number or "<project-number>", region,
                                 engine_id or "<engine-id>")
        die("no reasoning engine to read the identity from; run 'walle deploy' first")
    effective = read_effective_identity(ctx, engine_id)
    if not effective.startswith(AGENT_TRUST_DOMAIN_PREFIX):
        if ctx.dry_run:
            say("  [dry run] engine %s reports effectiveIdentity %r; using the expected shape"
                % (engine_id, effective))
            return principal_for(expected_domain, number, region, engine_id)
        die(
            "engine %s runs as %r, which is not an agent identity (expected a value "
            "starting with %s). identity_type cannot be patched: the engine must be "
            "recreated." % (engine_id, effective, AGENT_TRUST_DOMAIN_PREFIX)
        )
    if not effective.startswith(expected_domain):
        warn("effectiveIdentity %r is not under the expected trust domain %r; the "
             "project may not sit under ORG_ID" % (effective, expected_domain))
    return principal_for(effective, number, region, engine_id)


def check_automatic_roles_or_die(ctx: Ctx) -> None:
    """Phase 12b step 6: the two roles every agent identity gets are undocumented."""
    for role in AGENT_AUTOMATIC_ROLES:
        # No --project: these are predefined roles, not the project's custom ones.
        result = probe(ctx, ["gcloud", "iam", "roles", "describe", role, "--format=json"])
        if not result.ok:
            if ctx.dry_run:
                say("  [dry run] cannot read %s here: %s"
                    % (role, (result.err or "").strip().splitlines()[:1]))
                continue
            die("cannot describe %s, whose contents must be checked before the agent "
                "holds it:\n%s" % (role, result.err.strip()))
        payload = json.loads(result.out) if result.out.strip() else {}
        permissions = list((payload or {}).get("includedPermissions", []) or [])
        forbidden = [p for p in permissions
                     if any(marker in p for marker in FORBIDDEN_ROLE_PERMISSION_MARKERS)]
        if forbidden:
            die(
                "%s carries a forbidden permission: %s. The agent must hold no Secret "
                "Manager access and no setIamPolicy anywhere; stop and record it."
                % (role, ", ".join(forbidden))
            )
        step("%s: %d permissions, none forbidden" % (role, len(permissions)))


def ensure_deny_policy(ctx: Ctx) -> None:
    """Phase 12b step 7: the standing invariants, so a mistaken grant cannot undo them.

    Platform HLD §4.5 and §18 item 5 (2026-09-13): lifted to the folder as
    deny-agents-platform, one copy for the fleet, attached by the platform
    under PAM. This project-level copy stays until that folder policy exists.

    NOTE: every name in DENY_POLICY_PERMISSIONS must be verified against the
    list of permissions supported in deny policies before a real run. The
    research did not check it; an unsupported name fails the create, loudly.
    """
    project = ctx.need("PROJECT")
    attachment = "cloudresourcemanager.googleapis.com/projects/%s" % project
    existing = probe(ctx, ["gcloud", "iam", "policies", "get", DENY_POLICY_ID,
                           "--attachment-point", attachment, "--kind", "denypolicies",
                           "--format=json"])
    if existing.ok:
        step("deny policy exists: %s" % DENY_POLICY_ID)
        return
    lowered = (existing.err or "").lower()
    if not any(marker in lowered for marker in ABSENT_MARKERS) and not ctx.dry_run:
        die("cannot read deny policy %s\n%s" % (DENY_POLICY_ID, existing.err.strip()))
    policy = {
        "rules": [{
            "denyRule": {
                "deniedPrincipals": [
                    "principalSet://%s%s.system.id.goog/*"
                    % (AGENT_TRUST_DOMAIN_PREFIX, ctx.need("ORG_ID"))
                ],
                "deniedPermissions": list(DENY_POLICY_PERMISSIONS),
            }
        }]
    }
    path = ctx.scratch_file("deny-agents.json", json.dumps(policy, indent=2))
    say("  deny policy %s on %s:" % (DENY_POLICY_ID, attachment))
    say("    denied principals: every agent identity in the organisation")
    for permission in DENY_POLICY_PERMISSIONS:
        say("    denies %s" % permission)
    say("  Permission names must be on the deny-policy supported list; verify them")
    say("  first, the research did not.")
    confirm(ctx, "Create the deny policy?")
    run(ctx, ["gcloud", "iam", "policies", "create", DENY_POLICY_ID, "--kind=denypolicies",
              "--attachment-point=" + attachment, "--policy-file=" + path])


def phase_12b_identity(ctx: Ctx, mode: str) -> None:
    """Steps 5, 6 and 7, after the engine exists. Step 3 is `walle spike`."""
    section("Phase 12b — the agent's identity")
    spike_file = ctx.get("AGENT_IDENTITY_SPIKE_RESULT") or "<AGENT_IDENTITY_SPIKE_RESULT>"
    if mode == "SERVICE_ACCOUNT":
        say("  SERVICE_ACCOUNT fallback: Phase 12 as written, run.invoker on walle-agent@")
        say("  from Phase 10. Agent Identity is deferred hardening; the spike output at")
        say("  %s goes on the decision record (decision 19)." % spike_file)
        engine_id = resolve_engine_id(ctx)
        if engine_id and not ctx.dry_run:
            say("  effectiveIdentity=%s" % (read_effective_identity(ctx, engine_id) or "<none>"))
        ctx.note("Agent Identity deferred (AGENT_IDENTITY_MODE=SERVICE_ACCOUNT); spike at %s"
                 % spike_file)
        return
    engine_id = resolve_engine_id(ctx)
    if engine_id and not ctx.dry_run:
        effective = read_effective_identity(ctx, engine_id)
        if not effective.startswith(AGENT_TRUST_DOMAIN_PREFIX):
            die(
                "NOT an agent identity: engine %s reports spec.effectiveIdentity=%r.\n"
                "identity_type cannot be patched. Fix deploy.py to pass identity_type "
                "AGENT_IDENTITY and NO service_account, run 'walle rollback --phase 12' "
                "to delete this engine, and deploy again. Do not proceed."
                % (engine_id, effective)
            )
        say("  agent identity: %s" % effective)
        ctx.note("effectiveIdentity=%s" % effective)
    elif ctx.dry_run:
        say("  [dry run] the principal below is the expected shape, not a value read back")
    principal = agent_principal(ctx)
    say("  AGENT_PRINCIPAL=%s" % principal)
    ctx.note("AGENT_PRINCIPAL=%s" % principal)
    say("")
    say("  Phase 12b step 6: the baseline grants, and nothing else.")
    for role in AGENT_BASELINE_ROLES:
        say("    %s" % role)
    say("    roles/run.invoker on walle-actions (the binding form the spike proved)")
    confirm(ctx, "Apply the baseline grants to the agent principal?")
    for role in AGENT_BASELINE_ROLES:
        ensure_project_binding(ctx, principal, role)
    check_automatic_roles_or_die(ctx)
    ensure_run_invoker(ctx, "walle-actions", principal)
    # The agent is the one caller of the band-B service too (2026-09-13), once
    # that service exists; the dispatcher never is.
    if current_service_url(ctx, SUPER_SERVICE):
        ensure_run_invoker(ctx, SUPER_SERVICE, principal)
    say("  The in-app EXEC_CALLER_ALLOWLIST row for the agent is keyed on the claim the")
    say("  spike showed (sub, email if any, aud), not on an address: an agent identity")
    say("  has none. Read it from %s and update the action service's allowlist." % spike_file)
    ctx.note("EXEC_CALLER_ALLOWLIST: key the agent's row on the spike's recorded claim")
    say("")
    if getattr(ctx.args, "skip_deny_policy", False):
        warn("--skip-deny-policy: the standing invariants are NOT enforced by a deny "
             "policy; a mistaken grant can undo them. Record why.")
        ctx.note("deny policy %s skipped on request" % DENY_POLICY_ID)
    else:
        ensure_deny_policy(ctx)


def engine_stream_query(ctx: Ctx, engine_id: str, payload: Dict[str, Any]) -> List[Any]:
    """POST :streamQuery and return the events. Every caller uses streamQuery."""
    url = aiplatform_url(ctx, "%s/%s:streamQuery" % (engine_collection_path(ctx), engine_id))
    say("  HTTP POST %s" % url)
    if ctx.dry_run:
        say("    [dry run] not sent")
        return []
    request = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"),
                                     method="POST")
    request.add_header("Authorization", "Bearer " + access_token(ctx))
    request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            text = response.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as exc:
        die("streamQuery on %s returned HTTP %s: %s"
            % (engine_id, exc.code, exc.read().decode("utf-8", "replace")[:500]))
    except urllib.error.URLError as exc:
        die("network error calling %s: %s" % (url, exc))
    try:
        whole = json.loads(text)
        return list(whole) if isinstance(whole, list) else [whole]
    except ValueError:
        pass
    events: List[Any] = []
    for line in text.splitlines():
        if not line.strip():
            continue
        try:
            events.append(json.loads(line))
        except ValueError:
            events.append({"raw": line[:500]})
    return events


def _find_dict_with_key(node: Any, key: str) -> Optional[Dict[str, Any]]:
    if isinstance(node, dict):
        if key in node:
            return node
        for value in node.values():
            found = _find_dict_with_key(value, key)
            if found is not None:
                return found
    elif isinstance(node, list):
        for item in node:
            found = _find_dict_with_key(item, key)
            if found is not None:
                return found
    return None


_JWT_RE = re.compile(r"^[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}$")


def strip_secrets(node: Any) -> Any:
    """Drop anything that could be a credential before a result is written.

    The spike records WHETHER a token came back and what its claims were, never
    the token: a key containing "token" (other than the boolean token_returned)
    is dropped, and so is any string shaped like a JWT.
    """
    if isinstance(node, dict):
        cleaned = {}
        for key, value in node.items():
            if "token" in key.lower() and key != "token_returned":
                cleaned[key] = "<redacted>"
            else:
                cleaned[key] = strip_secrets(value)
        return cleaned
    if isinstance(node, list):
        return [strip_secrets(item) for item in node]
    if isinstance(node, str) and _JWT_RE.match(node.strip()):
        return "<redacted jwt>"
    return node


def cmd_spike(ctx: Ctx) -> int:
    """Phase 12b step 3: three results on a throwaway engine, written to a file.

    12b-a  does Cloud Run IAM accept the principal as an invoker
    12b-b  from inside the agent, is an ID token for ACTIONS_URL returned at all
    12b-c  does GET ACTIONS_URL/v1/operations accept it, and what claims does
           it carry (sub, email if present, aud)
    """
    section("Phase 12b step 3 — the Agent Identity spike, on a throwaway engine")
    result_path = os.path.expanduser(ctx.need("AGENT_IDENTITY_SPIKE_RESULT"))
    number = project_number(ctx)
    if not number and not ctx.dry_run:
        die("PROJECT_NUMBER is unknown; the spike cannot name the principal")
    ensure_agent_identity_prereqs(ctx)
    actions_url = ctx.get("ACTIONS_URL") or current_service_url(ctx, "walle-actions")
    if not actions_url:
        if not ctx.dry_run:
            die("walle-actions is not deployed (Phase 10); the spike calls it")
        actions_url = dry_run_placeholder(ctx, "ACTIONS_URL")
    engines = list_engines(ctx)
    if any(e.get("displayName") == ctx.get("ENGINE_DISPLAY_NAME") for e in engines):
        warn("the production engine already exists. The spike is meant to run BEFORE "
             "Phase 12's deploy: identity_type cannot be changed afterwards. While the "
             "spike engine exists, verify's exactly_one_engine fails.")
    spikes = [e for e in engines if e.get("displayName") == SPIKE_DISPLAY_NAME]
    say("")
    say("  This creates a throwaway engine named %s with identity_type AGENT_IDENTITY,"
        % SPIKE_DISPLAY_NAME)
    say("  binds its principal as run.invoker on walle-actions, asks it to fetch an ID")
    say("  token for %s and call /v1/operations, and writes the" % actions_url)
    say("  three results (never a token) to %s." % result_path)
    say("  Afterwards: 'walle rollback --phase 12b' deletes the engine and its binding.")
    confirm(ctx, "Create the spike engine and run the three checks?")
    deploy_script = repo_path(ctx, "agent", "deploy.py")
    env = {
        "PROJECT": ctx.need("PROJECT"),
        "REGION": ctx.need("REGION"),
        "ACTIONS_URL": actions_url,
        "STAGING_BUCKET": ctx.need("STAGING_BUCKET"),
        "WALLE_ENGINE_NAME": str(spikes[0].get("name", "")) if spikes else "",
        "ENGINE_DISPLAY_NAME": SPIKE_DISPLAY_NAME,
        # The contract: WALLE_SPIKE=1 deploys the spike agent instead of Wall-E.
        # Its one tool, probe_identity(audience), requests an ID token through
        # google.auth.compute_engine.IDTokenCredentials(request,
        # target_audience=audience), calls GET <audience>/v1/operations with it,
        # and returns {"token_returned": bool, "status": int,
        # "claims": {"sub": ..., "email": ..., "aud": ...}} — never the token.
        "WALLE_SPIKE": "1",
        "MIN_INSTANCES": "0",
        "ENABLE_MEMORY_BANK": "false",
        "ENABLE_CODE_EXECUTION": "false",
    }
    env.update(agent_deploy_env(ctx, "AGENT_IDENTITY"))
    say("  contract with deploy.py: WALLE_SPIKE=1 deploys the spike agent whose only")
    say("  tool is probe_identity(audience) and returns token_returned, status and the")
    say("  decoded claims (sub, email, aud), never the token itself.")
    run(ctx, [sys.executable, deploy_script], env=env)
    if ctx.dry_run:
        say("  [dry run] would then bind the spike principal as run.invoker on")
        say("  walle-actions, streamQuery the engine, and write %s" % result_path)
        return 0
    after = [e for e in list_engines(ctx) if e.get("displayName") == SPIKE_DISPLAY_NAME]
    if len(after) != 1:
        die("expected exactly one %s engine after the deploy, found %d"
            % (SPIKE_DISPLAY_NAME, len(after)))
    spike_name = str(after[0].get("name", ""))
    spike_id = spike_name.rsplit("/", 1)[-1]
    effective = read_effective_identity(ctx, spike_id)
    if not effective.startswith(AGENT_TRUST_DOMAIN_PREFIX):
        die("the spike engine reports effectiveIdentity %r: deploy.py did not honour "
            "IDENTITY_TYPE=AGENT_IDENTITY. Fix that before anything else." % effective)
    principal = principal_for(effective, number, ctx.need("REGION"), spike_id)
    say("  spike principal: %s" % principal)
    results: Dict[str, Any] = {}
    # 12b-a
    bind = run(ctx, [
        "gcloud", "run", "services", "add-iam-policy-binding", "walle-actions",
        "--region", ctx.need("REGION"), "--member", principal, "--role", "roles/run.invoker",
        "--project", ctx.need("PROJECT"),
    ], check=False)
    results["12b-a"] = {
        "question": "does Cloud Run IAM accept the principal as an invoker",
        "pass": bind.ok,
        "output": (bind.out + "\n" + bind.err).strip()[:2000],
    }
    say("  12b-a %s" % ("PASS" if bind.ok else "FAIL"))
    # 12b-b and 12b-c, from inside the agent
    events = engine_stream_query(ctx, spike_id, {
        "class_method": "stream_query",
        "input": {"user_id": "walle-spike",
                  "message": "probe_identity audience=%s" % actions_url},
    })
    probe_result = _find_dict_with_key(events, "token_returned")
    raw = strip_secrets(events)
    if probe_result is None:
        results["12b-b"] = {"question": "is an ID token for ACTIONS_URL returned at all",
                            "pass": False, "output": "no probe_identity result in the stream",
                            "raw_events": raw}
        results["12b-c"] = {"question": "does /v1/operations accept it; sub, email, aud",
                            "pass": False, "output": "no probe_identity result in the stream"}
        say("  12b-b FAIL (no tool result in the stream)")
        say("  12b-c FAIL")
    else:
        cleaned = strip_secrets(probe_result)
        token_returned = bool(cleaned.get("token_returned"))
        status = int(cleaned.get("status", 0) or 0)
        claims = cleaned.get("claims", {}) or {}
        results["12b-b"] = {"question": "is an ID token for ACTIONS_URL returned at all",
                            "pass": token_returned, "output": cleaned}
        results["12b-c"] = {"question": "does /v1/operations accept it; sub, email, aud",
                            "pass": token_returned and status == 200 and bool(claims),
                            "status": status, "claims": claims}
        say("  12b-b %s (token_returned=%s)" % ("PASS" if token_returned else "FAIL", token_returned))
        say("  12b-c %s (HTTP %s, claims %s)"
            % ("PASS" if results["12b-c"]["pass"] else "FAIL", status,
               ", ".join(sorted(claims.keys())) or "none"))
    verdict = "pass" if all(r.get("pass") for r in results.values()) else "fail"
    record = {
        "date": datetime.date.today().isoformat(),
        "spike_engine": spike_name,
        "effective_identity": effective,
        "principal": principal,
        "actions_url": actions_url,
        "results": results,
        "verdict": verdict,
    }
    os.makedirs(os.path.dirname(result_path) or ".", exist_ok=True)
    with open(result_path, "w", encoding="utf-8") as handle:
        json.dump(strip_secrets(record), handle, indent=2)
    os.chmod(result_path, 0o600)
    say("")
    say("  verdict: %s -> %s" % (verdict.upper(), result_path))
    if verdict == "pass":
        say("  Keep AGENT_IDENTITY_MODE=AGENT_IDENTITY. The allowlist row for the agent is")
        say("  keyed on the claim 12b-c recorded, not on an email.")
    else:
        say("  Set AGENT_IDENTITY_MODE=SERVICE_ACCOUNT for 'walle deploy' and attach this")
        say("  file to the decision record: Agent Identity becomes deferred hardening.")
    say("  Then: walle rollback --phase 12b   (deletes the spike engine and its binding)")
    ctx.note("spike %s recorded at %s" % (verdict, result_path))
    ctx.print_notes()
    return 0 if verdict == "pass" else 1


def rollback_spike(ctx: Ctx) -> None:
    """SETUP.md Phase 12b rollback: delete the throwaway engine, and its binding."""
    number = project_number(ctx)
    for engine in list_engines(ctx):
        if engine.get("displayName") != SPIKE_DISPLAY_NAME:
            continue
        name = str(engine.get("name", ""))
        engine_id = name.rsplit("/", 1)[-1]
        effective = read_effective_identity(ctx, engine_id)
        if effective.startswith(AGENT_TRUST_DOMAIN_PREFIX) and number:
            principal = principal_for(effective, number, ctx.need("REGION"), engine_id)
            policy = gcloud_probe_json(ctx, "run", "services", "get-iam-policy",
                                       "walle-actions", "--region", ctx.need("REGION")) or {}
            if principal in _members_with_role(policy, "roles/run.invoker"):
                run(ctx, ["gcloud", "run", "services", "remove-iam-policy-binding",
                          "walle-actions", "--region", ctx.need("REGION"),
                          "--member", principal, "--role", "roles/run.invoker",
                          "--project", ctx.need("PROJECT")])
        say("  DELETE spike engine %s" % name)
        confirm(ctx, "Delete spike engine %s?" % name)
        status, body = http_json(ctx, "DELETE", aiplatform_url(ctx, name), access_token(ctx))
        if status not in (200, 202) and not ctx.dry_run:
            die("deleting %s returned HTTP %s: %s" % (name, status, str(body)[:200]))


def phase_14_ladder_and_schedulers(ctx: Ctx) -> None:
    section("Phase 14 — ladder config v1 and paused schedulers")
    lint_ladder_config(ctx)
    script = repo_path(ctx, "config", "deploy_ladder.py")
    run(
        ctx,
        [
            sys.executable, script,
            "--project", ctx.need("PROJECT"), "--region", ctx.need("REGION"),
        ],
    )
    ensure_scheduler_jobs(ctx)
    phase_14_forced_shadow_run(ctx)


def phase_14_forced_shadow_run(ctx: Ctx) -> None:
    """SETUP.md Phase 14's verify does not stop at "every job reads PAUSED".

    It requires forcing one run — the jobs are on a weekly cron, so otherwise
    you wait a week — watching a shadow run complete, and confirming three
    things: per-item would-be verdicts in the report, that the OPERATOR
    NOTIFICATION ACTUALLY ARRIVES, and no Workspace write in the admin audit
    log for that window. Of the notification the runbook says: it is the one
    that proves notify.operators really is outside the ladder; if the report
    never arrives, F2-notify has been put back on the ladder at L1 somewhere
    and Stage 0 will collect evidence nobody ever sees.
    """
    jobs = [j.strip() for j in ctx.get("PLAYBOOK_JOBS").split(",") if j.strip()]
    if not jobs:
        return
    probe_job = "walle-%s" % jobs[0]
    say("")
    say("  Forcing one shadow run on %s. Do not wait for the schedule: the jobs are"
        % probe_job)
    say("  on '%s', so you would wait up to a week for the run that gates this phase."
        % ctx.get("PLAYBOOK_SCHEDULE"))
    confirm(ctx, "Resume %s, force one run, then pause it again?" % probe_job)
    location = ["--location", ctx.need("REGION"), "--project", ctx.need("PROJECT")]
    run(ctx, ["gcloud", "scheduler", "jobs", "resume", probe_job] + location)
    try:
        # A forced run carries a manual trigger id, not job-name-plus-scheduled
        # -time, so it does not suppress Monday's run through the dispatcher's
        # deduplication.
        run(ctx, ["gcloud", "scheduler", "jobs", "run", probe_job] + location)
        say("  Watch the dispatcher log, then read the report.")
        confirm(ctx, "Does the report show per-item would-be verdicts?")
        confirm(
            ctx,
            "Did the operator notification ACTUALLY ARRIVE — not just a terminal "
            "state in the log? A missing report means F2-notify is back on the "
            "ladder at L1 and Stage 0 collects evidence nobody sees.",
        )
    finally:
        run(ctx, ["gcloud", "scheduler", "jobs", "pause", probe_job] + location)
    status, detail = _assert_no_robot_admin_events(ctx, "2h")
    if status == FAIL:
        die("the forced shadow run produced a Workspace WRITE: %s" % detail)
    say("  admin audit log for the run window: %s (%s)" % (detail, status))


def lint_ladder_config(ctx: Ctx) -> None:
    """A narrow textual lint, not a parse: no YAML library is in the dependency
    set. The authoritative check is the deployed GET /v1/ladder, in verify."""
    path = os.path.join(os.path.expanduser(ctx.need("WALLE_REPO")), "config", "ladder.yaml")
    if not os.path.isfile(path):
        die("missing %s (SETUP.md Phase 14.2)" % path)
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    problems = []
    if not re.search(r"^defaults:\s*$", text, re.M):
        problems.append("no defaults: block")
    defaults_block = text.split("defaults:", 1)[-1].split("\nexempt_operations", 1)[0]
    if "ou_allowlist" not in defaults_block:
        problems.append(
            "ou_allowlist is not in defaults. Put it on F3-membership alone and six "
            "of the seven write families deny every shadow item on scope, which guts "
            "the evidence Stage 0 exists to collect"
        )
    if re.search(r"^\s{2}F2-notify:\s*$", text, re.M) and "outside_ladder" not in text:
        problems.append("F2-notify appears as a ladder family with levels")
    if "notify.operators" not in text:
        problems.append("notify.operators is not listed under exempt_operations")
    if not re.search(r"daily_write_budget:\s*0\b", text):
        problems.append("daily_write_budget is not 0")
    if problems:
        die("ladder.yaml lint failed:\n  - " + "\n  - ".join(problems))
    step("ladder.yaml lint passed (%s)" % path)


def ensure_scheduler_jobs(ctx: Ctx) -> None:
    """gcloud scheduler jobs create http has no --paused flag in GA, beta or
    alpha. The pause is a second command, inside the same loop iteration, so no
    job is left enabled across a failure partway through."""
    jobs = [j.strip() for j in ctx.get("PLAYBOOK_JOBS").split(",") if j.strip()]
    for job in jobs:
        name = "walle-%s" % job
        described = gcloud_probe_json(
            ctx, "scheduler", "jobs", "describe", name, "--location", ctx.need("REGION")
        )
        if described is None:
            run(
                ctx,
                [
                    "gcloud", "scheduler", "jobs", "create", "http", name,
                    "--location", ctx.need("REGION"),
                    "--schedule", ctx.get("PLAYBOOK_SCHEDULE"),
                    "--time-zone", ctx.get("TIMEZONE"),
                    "--uri", "%s/run/%s" % (dry_run_placeholder(ctx, "DISPATCHER_URL"), job),
                    "--http-method", "POST",
                    "--oidc-service-account-email", ctx.need("SA_DISPATCH"),
                    "--oidc-token-audience", dry_run_placeholder(ctx, "DISPATCHER_URL"),
                    # The deadline covers acknowledgement, never the run.
                    "--attempt-deadline", "30s",
                    "--max-retry-attempts", "0",
                    "--project", ctx.need("PROJECT"),
                ],
            )
            run(ctx, ["gcloud", "scheduler", "jobs", "pause", name,
                      "--location", ctx.need("REGION"), "--project", ctx.need("PROJECT")])
            continue
        state = described.get("state")
        step("scheduler job exists: %s (%s)" % (name, state))
        if state != "PAUSED":
            warn("%s is %s. Every playbook job must be paused until Phase 18." % (name, state))
            confirm(ctx, "Pause %s?" % name)
            run(ctx, ["gcloud", "scheduler", "jobs", "pause", name,
                      "--location", ctx.need("REGION"), "--project", ctx.need("PROJECT")])
    say(
        "  Resuming one is the deliberate act that starts Stage 0 evidence "
        "collection, and it happens in Phase 18, not here."
    )


def cmd_deploy(ctx: Ctx) -> int:
    # M4 (Phase 5) moved to `walle workspace`: it belongs on day one, before
    # Phase 6, and its 24-hour clock must not be able to abort a half-configured
    # action service. `walle verify` still asserts it.
    phase_10_actions(ctx)
    phase_11_dispatcher(ctx)
    phase_12_agent(ctx)
    phase_14_ladder_and_schedulers(ctx)
    ctx.print_notes()
    say("")
    say("Phases 10, 11, 12, 12b and 14 done. Next: 'walle register' (phase 13), then")
    say("'walle registry' (phase 13b). 'walle armor' (phase 12c) should have run BEFORE")
    say("this deploy so the engine was bound to the ingress gateway at creation.")
    return 0


# --------------------------------------------------------------------------- #
# Phase 13 — Gemini Enterprise registration
# --------------------------------------------------------------------------- #


def access_token(ctx: Ctx) -> str:
    """A live bearer token. read_only_run, so --verbose cannot echo it."""
    return read_only_run(ctx, ["gcloud", "auth", "print-access-token"]).out.strip()


def id_token(ctx: Ctx, audience: str) -> str:
    """gcloud refuses --audiences for user credentials, so mint by impersonation."""
    result = read_only_run(
        ctx,
        [
            "gcloud", "auth", "print-identity-token",
            "--impersonate-service-account", ctx.need("SA_OPS_CALLER"),
            "--audiences", audience, "--include-email",
        ],
        check=False,
    )
    if not result.ok:
        die(
            "could not mint an ID token by impersonating %s.\n"
            "You need roles/iam.serviceAccountTokenCreator on it (SETUP.md 1.4); "
            "without it the andon cord has no handle you can pull from a terminal.\n%s"
            % (ctx.need("SA_OPS_CALLER"), result.err.strip())
        )
    return result.out.strip()


def http_json(
    ctx: Ctx, method: str, url: str, token: str,
    payload: Optional[Dict[str, Any]] = None,
    mutating: bool = True,
) -> Tuple[int, Any]:
    body = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = urllib.request.Request(url, data=body, method=method)
    if token:
        request.add_header("Authorization", "Bearer " + token)
    request.add_header("Content-Type", "application/json")
    say("  HTTP %s %s" % (method, url))
    if payload is not None and (ctx.verbose or ctx.dry_run):
        say("    body: " + json.dumps(payload)[:400])
    if ctx.dry_run and mutating and method != "GET":
        say("    [dry run] not sent")
        return 0, None
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            text = response.read().decode("utf-8")
            return response.status, (json.loads(text) if text.strip() else None)
    except urllib.error.HTTPError as exc:
        text = exc.read().decode("utf-8", "replace")
        try:
            return exc.code, json.loads(text)
        except ValueError:
            return exc.code, {"raw": text[:500]}
    except urllib.error.URLError as exc:
        die("network error calling %s: %s" % (url, exc))
    return 0, None


def cmd_register(ctx: Ctx) -> int:
    section("Phase 13 — register and share in Gemini Enterprise")
    app_id = ctx.get("GEMINI_APP_ID")
    location = ctx.get("GEMINI_APP_LOCATION", "eu")
    if not app_id:
        die(
            "GEMINI_APP_ID is not set. D8 closes this before Phase 6, in GEMINI_PROJECT: "
            "Gemini Enterprise console -> app -> settings. A 'us' app cannot front a "
            "europe-west1 agent."
        )
    host = "discoveryengine.googleapis.com"
    if location != "global":
        host = "%s-discoveryengine.googleapis.com" % location
    # The app is read from GEMINI_PROJECT, its own project; the engine it
    # fronts stays in PROJECT. Reading needs roles/discoveryengine.viewer on
    # GEMINI_PROJECT for the operator (project-topology.md §7.4 step 3).
    engine_url = (
        "https://%s/v1/projects/%s/locations/%s/collections/default_collection/engines/%s"
        % (host, ctx.need("GEMINI_PROJECT"), location, app_id)
    )
    status, payload = http_json(ctx, "GET", engine_url, access_token(ctx))
    if status == 200 and isinstance(payload, dict):
        say("  Gemini Enterprise app found: %s (in GEMINI_PROJECT %s)"
            % (payload.get("displayName", app_id), ctx.need("GEMINI_PROJECT")))
        say("  app location: %s" % location)
        if location not in ("eu", "global"):
            die(
                "the app is in '%s'. Phase 13 assumes eu or global. A us app cannot "
                "front a europe-west1 agent: the fix is a new eu app, not a change "
                "in this phase." % location
            )
    else:
        warn("could not read the app (HTTP %s): %s" % (status, payload))
        ctx.note("Gemini Enterprise app %s could not be read over the API." % app_id)

    if not resolve_engine_id(ctx):
        die("no reasoning engine to register. Run 'walle deploy' (phase 12) first.")
    say("")
    say(
        "  The agent-registration surface is v1alpha and its shape is not stable. "
        "SETUP.md Phase 13 specifies console steps, so that is what this does. "
        "Registration is therefore a MANUAL step with an API verification after it."
    )
    do_manual_step(ctx, "M8")

    # SETUP.md Phase 13's verification ends with an explicit gate, and the
    # script used to stop at M8. This is the one check that proves the asserted
    # end-user email actually reaches the policy engine: without it the
    # operator check in the action service has nothing to verify.
    say("")
    say("  Now ask Wall-E a directory question in Gemini Enterprise AS YOURSELF,")
    say("  then confirm the identity reached the policy engine.")
    confirm(ctx, "Have you asked one directory question in Gemini Enterprise?")
    if not ctx.dry_run:
        query = (
            "SELECT ts, principal_type, principal_id, operation, decision, "
            "denial_reason, level FROM `%s.%s.actions` ORDER BY ts DESC LIMIT 20"
            % (ctx.need("PROJECT"), ctx.get("AUDIT_DATASET"))
        )
        result = run(
            ctx,
            ["bq", "--project_id", ctx.need("PROJECT"), "query",
             "--use_legacy_sql=false", "--location", ctx.need("BQ_LOCATION"),
             "--format=json", query],
            mutating=False, check=False,
        )
        rows = json.loads(result.out) if result.ok and result.out.strip() else []
        me = ctx.get("OPERATOR_EMAIL", "").lower()
        mine = [r for r in rows if str(r.get("principal_id", "")).lower() == me]
        if not mine:
            die(
                "no audit row carries your email as principal_id. If principal_id is "
                "empty or is a service account rather than your email, the asserted "
                "end-user identity is not reaching the policy engine and the "
                "operator check in the action service has nothing to verify. Stop "
                "and fix that before Phase 14 (SETUP.md Phase 13 verify, 7.8)."
            )
        step("principal_id reaches the policy engine: %d row(s) attributed to you"
             % len(mine))
    ctx.print_notes()
    return 0


def verify_gemini_registration(ctx: Ctx) -> Tuple[str, str]:
    """Best effort: the alpha listing may not exist. A definite 'not registered'
    is a failure; an unreachable endpoint is a skip that says so."""
    app_id = ctx.get("GEMINI_APP_ID")
    location = ctx.get("GEMINI_APP_LOCATION", "eu")
    engine_id = resolve_engine_id(ctx)
    if not app_id or not engine_id:
        return "SKIP", "GEMINI_APP_ID or ENGINE_ID not set"
    host = "discoveryengine.googleapis.com"
    if location != "global":
        host = "%s-discoveryengine.googleapis.com" % location
    # The v1alpha agents listing lives under the APP's project. The match on
    # engine_id still works: the registered resource path names Wall-E's.
    url = (
        "https://%s/v1alpha/projects/%s/locations/%s/collections/default_collection/"
        "engines/%s/assistants/default_assistant/agents"
        % (host, ctx.need("GEMINI_PROJECT"), location, app_id)
    )
    status, payload = http_json(ctx, "GET", url, access_token(ctx))
    if status != 200 or not isinstance(payload, dict):
        return "SKIP", "v1alpha agents listing not available (HTTP %s); confirm by eye" % status
    blob = json.dumps(payload)
    if engine_id in blob:
        return "PASS", "engine %s is registered on app %s in %s" % (
            engine_id, app_id, ctx.need("GEMINI_PROJECT"))
    return "FAIL", "app %s lists no agent pointing at engine %s" % (app_id, engine_id)


# --------------------------------------------------------------------------- #
# Phase 16 — Gmail watch and its daily renewal
# --------------------------------------------------------------------------- #


# --------------------------------------------------------------------------- #
# Phase 12c — Model Armor: templates, the ingress gateway, and the floor
# (SETUP.md Phase 12c, 11-prompt-security.md section 5)
# --------------------------------------------------------------------------- #


def sanitize_log_filter(ctx: Ctx) -> str:
    return 'logName="projects/%s/logs/modelarmor.googleapis.com%%2Fsanitize_operations"' % (
        ctx.need("PROJECT"))


def ensure_content_log_bucket(ctx: Ctx) -> None:
    region, project = ctx.need("REGION"), ctx.need("PROJECT")
    retention = ctx.get("CONTENT_LOG_RETENTION_DAYS") or "30"
    described = gcloud_probe_json(ctx, "logging", "buckets", "describe", CONTENT_LOG_BUCKET,
                                  "--location", region)
    if described is None:
        run(ctx, ["gcloud", "logging", "buckets", "create", CONTENT_LOG_BUCKET,
                  "--location=" + region, "--retention-days=" + retention,
                  "--project=" + project])
        return
    step("log bucket exists: %s" % CONTENT_LOG_BUCKET)
    have = str(described.get("retentionDays", "") or "")
    if have and have != retention:
        warn("bucket retention is %s days, CONTENT_LOG_RETENTION_DAYS says %s; updating"
             % (have, retention))
        run(ctx, ["gcloud", "logging", "buckets", "update", CONTENT_LOG_BUCKET,
                  "--location=" + region, "--retention-days=" + retention,
                  "--project=" + project])


def ensure_project_sink(ctx: Ctx, name: str, destination: str, log_filter: str) -> None:
    """Project level, unlike ensure_sink: these logs are produced in the project."""
    project = ctx.need("PROJECT")
    described = gcloud_probe_json(ctx, "logging", "sinks", "describe", name)
    if described is None:
        run(ctx, ["gcloud", "logging", "sinks", "create", name, destination,
                  "--log-filter=" + log_filter, "--project=" + project])
        return
    step("sink exists: %s" % name)
    if str(described.get("filter", "")).strip() != log_filter:
        warn("sink %s has a different filter; updating it" % name)
        say("    have: %s" % described.get("filter"))
        say("    want: %s" % log_filter)
        run(ctx, ["gcloud", "logging", "sinks", "update", name,
                  "--log-filter=" + log_filter, "--project=" + project])


def ensure_default_exclusion(ctx: Ctx, name: str, log_filter: str) -> None:
    """The raw prompts must NOT also land in _Default, where every viewer reads."""
    project = ctx.need("PROJECT")
    argv = ["gcloud", "logging", "sinks", "update", "_Default",
            "--add-exclusion=name=%s,filter=%s" % (name, log_filter),
            "--project=" + project]
    described = gcloud_probe_json(ctx, "logging", "sinks", "describe", "_Default")
    if described is None:
        if not ctx.dry_run:
            die("cannot describe the _Default sink of %s; it always exists, so this is "
                "a permission problem" % project)
        run(ctx, argv)
        return
    for exclusion in described.get("exclusions", []) or []:
        if exclusion.get("name") != name:
            continue
        if str(exclusion.get("filter", "")).strip() == log_filter and not exclusion.get("disabled"):
            step("_Default exclusion present: %s" % name)
            return
        die(
            "the _Default exclusion %s exists with a different filter or is disabled, "
            "so raw prompts may be landing in _Default:\n  have: %s\n  want: %s\n"
            "Remove it and re-run:\n  gcloud logging sinks update _Default "
            "--remove-exclusions=%s --project=%s"
            % (name, exclusion.get("filter"), log_filter, name, project)
        )
    run(ctx, argv)


def armor_template_create_argv(ctx: Ctx, name: str) -> List[str]:
    """SETUP.md Phase 12c step 2, verbatim. inspect-only: the flip is --enforce."""
    return [
        "gcloud", "beta", "model-armor", "templates", "create", name,
        "--location=" + ctx.need("REGION"), "--project=" + ctx.need("PROJECT"),
        "--pi-and-jailbreak-filter-settings-enforcement=enabled",
        "--pi-and-jailbreak-filter-settings-confidence-level=medium-and-above",
        "--malicious-uri-filter-settings-enforcement=enabled",
        "--basic-config-filter-enforcement=enabled",
        "--rai-settings-filters=" + ARMOR_RAI_FILTERS,
        "--template-metadata-enforcement-type=inspect-only",
        "--template-metadata-log-sanitize-operations",
    ]


def ensure_armor_template(ctx: Ctx, name: str) -> None:
    described = gcloud_probe_json(ctx, "beta", "model-armor", "templates", "describe", name,
                                  "--location", ctx.need("REGION"))
    if described is None:
        run(ctx, armor_template_create_argv(ctx, name))
        return
    step("template exists: %s" % name)
    enforcement = str((described.get("templateMetadata") or {}).get("enforcementType", "") or "")
    if enforcement and enforcement.upper().replace("-", "_") != "INSPECT_ONLY":
        warn("template %s is %s, not INSPECT_ONLY. This run changes nothing about it; "
             "blocking is a Stage 1 decision (decision 24) and its flip is "
             "'walle armor --enforce'." % (name, enforcement))
        ctx.note("template %s already at %s" % (name, enforcement))


def ensure_agent_gateway(ctx: Ctx, name: str, yaml_text: str) -> None:
    region, project = ctx.need("REGION"), ctx.need("PROJECT")
    described = gcloud_probe_json(ctx, "network-services", "agent-gateways", "describe", name,
                                  "--location", region)
    if described is not None:
        step("agent gateway exists: %s" % name)
        return
    path = ctx.scratch_file(name + ".yaml", yaml_text)
    say("  %s:" % path)
    for line in yaml_text.rstrip("\n").splitlines():
        say("    | " + line)
    run(ctx, ["gcloud", "network-services", "agent-gateways", "import", name,
              "--source=" + path, "--location=" + region, "--project=" + project])


def grant_armor_service_agents(ctx: Ctx) -> None:
    """Phase 12c step 4. None of these grants touches walle-agent@ or walle-actions@."""
    number = project_number(ctx)
    if not number:
        if not ctx.dry_run:
            die("PROJECT_NUMBER is unknown; cannot name the service agents")
        number = "<project-number>"
    re_agent = "serviceAccount:service-%s@gcp-sa-aiplatform-re.iam.gserviceaccount.com" % number
    dep_agent = "serviceAccount:service-%s@gcp-sa-dep.iam.gserviceaccount.com" % number
    for role in ("roles/modelarmor.calloutUser", "roles/modelarmor.user"):
        ensure_project_binding(ctx, re_agent, role)
        ensure_project_binding(ctx, dep_agent, role)
    ensure_project_binding(ctx, dep_agent, "roles/serviceusage.serviceUsageConsumer")
    say("  The pages disagree on whether the Service Extensions agent is needed for")
    say("  ingress in addition to the Reasoning Engine agent: both are granted. Prove a")
    say("  block in the verify step, then remove whichever grant proves unnecessary and")
    say("  record it.")
    ctx.note("Model Armor: both service agents granted; remove the unnecessary one after "
             "the block is proved")


def armor_extension_yaml(ctx: Ctx) -> str:
    """failOpen: false is the correction that makes this path enforcement-grade."""
    project, region = ctx.need("PROJECT"), ctx.need("REGION")
    settings = json.dumps([{
        "request_template_id": "projects/%s/locations/%s/templates/walle-ingress-prompt"
        % (project, region),
        "response_template_id": "projects/%s/locations/%s/templates/walle-ingress-response"
        % (project, region),
    }], separators=(",", ":"))
    return (
        "name: %s\n"
        "service: modelarmor.%s.rep.googleapis.com\n"
        "metadata:\n"
        "  model_armor_settings: '%s'\n"
        "failOpen: false\n"
        "timeout: 1s\n" % (ARMOR_EXTENSION_NAME, region, settings)
    )


def armor_policy_yaml(ctx: Ctx) -> str:
    project, region = ctx.need("PROJECT"), ctx.need("REGION")
    return (
        "name: %s\n"
        "target:\n"
        '  resources: ["projects/%s/locations/%s/agentGateways/%s"]\n'
        "policyProfile: CONTENT_AUTHZ\n"
        "action: CUSTOM\n"
        "customProvider:\n"
        "  authzExtension:\n"
        '    resources: ["projects/%s/locations/%s/authzExtensions/%s"]\n'
        % (ARMOR_POLICY_NAME, project, region, INGRESS_GATEWAY_NAME,
           project, region, ARMOR_EXTENSION_NAME)
    )


def write_committed_yaml(ctx: Ctx, subdir: Sequence[str], filename: str, text: str) -> str:
    """Into WALLE_REPO/<subdir>/, which verify reads back. Under --dry-run: scratch."""
    repo = os.path.expanduser(ctx.need("WALLE_REPO"))
    directory = os.path.join(repo, *subdir)
    path = os.path.join(directory, filename)
    if ctx.dry_run:
        say("  WOULD WRITE %s" % path)
        return ctx.scratch_file(filename, text)
    os.makedirs(directory, exist_ok=True)
    if os.path.isfile(path):
        with open(path, "r", encoding="utf-8") as handle:
            if handle.read() == text:
                step("already current: %s" % path)
                return path
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
    step("wrote %s (commit it: verify reads it back)" % path)
    return path


def ensure_authz_extension(ctx: Ctx, name: str, path: str, beta: bool = False) -> None:
    region, project = ctx.need("REGION"), ctx.need("PROJECT")
    track = ["beta"] if beta else []
    described = gcloud_probe_json(ctx, *(track + ["service-extensions", "authz-extensions",
                                                  "describe", name, "--location", region]))
    argv = ["gcloud"] + track + ["service-extensions", "authz-extensions", "import", name,
                                 "--source=" + path, "--location=" + region,
                                 "--project=" + project]
    if described is None:
        run(ctx, argv)
        return
    step("authz extension exists: %s" % name)
    if described.get("failOpen") is True:
        warn("the live extension %s is failOpen TRUE, which is fail-OPEN; re-importing "
             "the fail-closed YAML" % name)
        run(ctx, argv)


def ensure_authz_policy(ctx: Ctx, name: str, path: str) -> None:
    region, project = ctx.need("REGION"), ctx.need("PROJECT")
    described = gcloud_probe_json(ctx, "network-security", "authz-policies", "describe", name,
                                  "--location", region)
    if described is not None:
        step("authz policy exists: %s" % name)
        return
    run(ctx, ["gcloud", "network-security", "authz-policies", "import", name,
              "--source=" + path, "--location=" + region, "--project=" + project])


def floor_update_argv(ctx: Ctx, full_uri: str, *flags: str) -> List[str]:
    return ["gcloud", "model-armor", "floorsettings", "update", "--full-uri=" + full_uri] + list(flags)


def apply_floor_settings(ctx: Ctx) -> None:
    """Phase 12c step 7: conformance at the folder, inline on the project, logging on.

    The folder floor pins only "prompt-injection enabled at HIGH or stricter,
    malicious URL enabled", so it cannot prejudge the confidence level Stage 0
    measures. The update commands are declarative, so re-running is safe.
    """
    project = ctx.need("PROJECT")
    folder_uri = "folders/%s/locations/global/floorSetting" % ctx.need("FOLDER_ID")
    project_uri = "projects/%s/locations/global/floorSetting" % project
    env = dict(MODEL_ARMOR_GLOBAL_ENDPOINT_ENV)
    say("  Floor commands run with CLOUDSDK_API_ENDPOINT_OVERRIDES_MODELARMOR set, the")
    say("  environment form of `gcloud config set api_endpoint_overrides/modelarmor`,")
    say("  scoped to these commands so a re-run's regional `templates create` is not")
    say("  redirected to the global endpoint.")
    for uri in (folder_uri, project_uri):
        current = probe(ctx, ["gcloud", "model-armor", "floorsettings", "describe",
                              "--full-uri=" + uri, "--format=json"])
        if not current.ok:
            say("  (no readable floor setting at %s yet)" % uri)
    run(ctx, floor_update_argv(
        ctx, folder_uri,
        "--pi-and-jailbreak-filter-settings-enforcement=ENABLED",
        "--pi-and-jailbreak-filter-settings-confidence-level=HIGH",
        "--malicious-uri-filter-settings-enforcement=ENABLED",
        "--enable-floor-setting-enforcement=true",
    ), env=env)
    run(ctx, floor_update_argv(ctx, project_uri, "--add-integrated-services=VERTEX_AI"), env=env)
    number = project_number(ctx) or ("<project-number>" if ctx.dry_run else "")
    if not number:
        die("PROJECT_NUMBER is unknown; cannot name the Vertex AI service agent")
    ensure_project_binding(
        ctx, "serviceAccount:service-%s@gcp-sa-aiplatform.iam.gserviceaccount.com" % number,
        "roles/modelarmor.user",
    )
    run(ctx, floor_update_argv(ctx, project_uri, "--enable-vertex-ai-cloud-logging"), env=env)


def armor_enforce(ctx: Ctx) -> int:
    """The blocking flips. Later, not at setup, and only with a decision on file."""
    decision = os.path.expanduser(ctx.get("MODEL_ARMOR_ENFORCE_DECISION") or "")
    if not decision or not os.path.isfile(decision):
        die(
            "--enforce flips both templates to inspect-and-block and the project floor "
            "to INSPECT_AND_BLOCK. It is refused unless MODEL_ARMOR_ENFORCE_DECISION "
            "names an existing decision record (the Stage 1 decision, decision 24), and "
            "%r does not. The flips go through the same reviewed pipeline as ladder.yaml, "
            "after the Stage 0 numbers." % decision
        )
    say("  decision record: %s" % decision)
    say("  This makes Model Armor BLOCK on the ingress gateway and on the agent's")
    say("  generateContent calls. A Model Armor outage then stops Wall-E: that is the")
    say("  price of fail-closed, and it is deliberate.")
    for name in ARMOR_TEMPLATES:
        say("    %s -> inspect-and-block" % name)
    say("    project floor -> --vertex-ai-enforcement-type=INSPECT_AND_BLOCK")
    confirm(ctx, "Flip Model Armor to blocking?")
    for name in ARMOR_TEMPLATES:
        run(ctx, ["gcloud", "beta", "model-armor", "templates", "update", name,
                  "--location=" + ctx.need("REGION"), "--project=" + ctx.need("PROJECT"),
                  "--template-metadata-enforcement-type=inspect-and-block"])
    run(ctx, floor_update_argv(
        ctx, "projects/%s/locations/global/floorSetting" % ctx.need("PROJECT"),
        "--vertex-ai-enforcement-type=INSPECT_AND_BLOCK",
    ), env=dict(MODEL_ARMOR_GLOBAL_ENDPOINT_ENV))
    ctx.note("Model Armor flipped to blocking per %s" % decision)
    ctx.print_notes()
    return 0


def cmd_armor(ctx: Ctx) -> int:
    section("Phase 12c — Model Armor: templates, the ingress gateway, and the floor")
    if getattr(ctx.args, "enforce", False):
        return armor_enforce(ctx)
    project, region = ctx.need("PROJECT"), ctx.need("REGION")
    say("  The Gemini Enterprise console's Model Armor setting does not screen custom")
    say("  ADK agents. This puts Model Armor on an ingress gateway (fail-closed) and on")
    say("  the project floor (fail-open), all INSPECT-ONLY. The sanitize logs are routed")
    say("  BEFORE any template exists: they carry raw prompts and personal data.")
    say("  The blocking flips are 'walle armor --enforce', gated on a decision record.")
    confirm(ctx, "Proceed with the Model Armor setup, inspect-only?")
    ensure_apis_listed(ctx, MODEL_ARMOR_APIS, "Model Armor")

    say("")
    say("  step 1: route the sanitize logs")
    log_filter = sanitize_log_filter(ctx)
    ensure_content_log_bucket(ctx)
    ensure_project_sink(
        ctx, CONTENT_LOG_SINK,
        "logging.googleapis.com/projects/%s/locations/%s/buckets/%s"
        % (project, region, CONTENT_LOG_BUCKET),
        log_filter,
    )
    ensure_default_exclusion(ctx, CONTENT_LOG_EXCLUSION, log_filter)
    say("  readers of %s: %s and IT security, nobody else. This" % (CONTENT_LOG_BUCKET, ctx.need("OPERATORS")))
    say("  script grants no reader; a bucket-scoped view grant is a console decision.")
    ctx.note("grant read on %s to %s and IT security only" % (CONTENT_LOG_BUCKET, ctx.need("OPERATORS")))

    say("")
    say("  step 2: two templates, inspect-only. gcloud beta, because the enforcement-type")
    say("  flag is on the beta track; the GA track creates blocking templates only.")
    for name in ARMOR_TEMPLATES:
        ensure_armor_template(ctx, name)
    say("  step 3 is manual: run the injection regression suite against")
    say("  %s:sanitizeUserPrompt directly and record filterVersionConfig from" % ARMOR_TEMPLATES[0])
    say("  each response. The prompt-injection filter moves to v3 on or before")
    say("  2026-09-25 and retires v1 and v2 on 2026-11-29: detection changes under you")
    say("  with no config change.")
    ctx.note("run the injection regression suite against %s and record filterVersionConfig"
             % ARMOR_TEMPLATES[0])

    say("")
    say("  step 4: the ingress gateway, the fail-closed extension, and the policy")
    ensure_agent_gateway(
        ctx, INGRESS_GATEWAY_NAME,
        "name: %s\nprotocols: [MCP]\ngoogleManaged:\n  governedAccessPath: CLIENT_TO_AGENT\n"
        % INGRESS_GATEWAY_NAME,
    )
    grant_armor_service_agents(ctx)
    extension_path = write_committed_yaml(ctx, ARMOR_CONFIG_SUBDIR, "walle-ma-ext.yaml",
                                          armor_extension_yaml(ctx))
    say("  failOpen: false and timeout: 1s. A Model Armor outage then stops Wall-E,")
    say("  which is the price of an enforcement-grade path.")
    ensure_authz_extension(ctx, ARMOR_EXTENSION_NAME, extension_path)
    policy_path = write_committed_yaml(ctx, ARMOR_CONFIG_SUBDIR, "walle-ma-policy.yaml",
                                       armor_policy_yaml(ctx))
    ensure_authz_policy(ctx, ARMOR_POLICY_NAME, policy_path)

    say("")
    say("  step 7: floor settings, conformance at the folder %s, inline on the project."
        % ctx.need("FOLDER_ID"))
    say("  FOLDER_ID holds all four projects (project-topology.md §5), so the folder")
    say("  floor also binds the templates of EVE_PROJECT, MO_PROJECT and GEMINI_PROJECT;")
    say("  the project floor below is Wall-E's own and stricter.")
    apply_floor_settings(ctx)

    say("")
    say("  INGRESS_GATEWAY=%s   <- put this in the config BEFORE 'walle deploy':"
        % INGRESS_GATEWAY_NAME)
    say("  the engine is bound to the gateway at creation (Phase 12c step 5).")
    ctx.note("INGRESS_GATEWAY=%s" % INGRESS_GATEWAY_NAME)
    say("  Verify by hand, SETUP.md Phase 12c: a known injection through streamQuery with")
    say("  a traceparent gives a normal stream while inspect-only and a")
    say("  SanitizeOperationLogEntry with filterMatchState=MATCH_FOUND and")
    say("  client_name=AGENT_GATEWAY in %s; point the extension at a wrong" % CONTENT_LOG_BUCKET)
    say("  template name and confirm the caller gets an error, then restore: that is")
    say("  fail-closed observed rather than believed.")
    ctx.print_notes()
    return 0


# --------------------------------------------------------------------------- #
# Phase 13b — Agent Registry, and the egress gateway in dry-run
# (SETUP.md Phase 13b, 13-agent-interconnection.md section 10)
# --------------------------------------------------------------------------- #


def assert_egress_host_allowed(url: str) -> None:
    """The one rule the egress allowlist exists for. A refusal, never a warning."""
    host = (urllib.parse.urlsplit(url).netloc or url).lower()
    hits = [marker for marker in FORBIDDEN_EGRESS_HOST_MARKERS if marker in host]
    if hits:
        die(
            "REFUSING to register %s: host %r matches %s. The reasoning layer must "
            "never reach Secret Manager, Firestore, admin.googleapis.com, any Workspace "
            "host or BigQuery except through the action service (13-agent-"
            "interconnection.md section 7)." % (url, host, ", ".join(hits))
        )


def iam_member(value: str, default_kind: str = "serviceAccount") -> str:
    """'x@y' -> 'serviceAccount:x@y'; an already-prefixed member is left alone."""
    value = value.strip()
    if ":" in value.split("@", 1)[0]:
        return value
    return "%s:%s" % (default_kind, value)


def egress_endpoints(ctx: Ctx) -> List[Tuple[str, str]]:
    """walle-actions plus the essential platform endpoints, exact hostnames.

    Deliberately absent: secretmanager, firestore, admin.googleapis.com, every
    Workspace host, bigquery. assert_egress_host_allowed refuses them anyway.
    """
    region = ctx.need("REGION")
    actions_url = ctx.get("ACTIONS_URL") or current_service_url(ctx, "walle-actions")
    if not actions_url:
        if not ctx.dry_run:
            die("walle-actions is not deployed (Phase 10); nothing to register")
        actions_url = dry_run_placeholder(ctx, "ACTIONS_URL")
    engine_id = resolve_engine_id(ctx) or "<engine-id>"
    sessions = "https://%s-aiplatform.googleapis.com/%s/%s/%s/sessions" % (
        region, AIPLATFORM_API_VERSION, engine_collection_path(ctx), engine_id)
    return [
        ("walle-actions", actions_url),
        ("aiplatform", "https://aiplatform.googleapis.com"),
        ("aiplatform-regional", "https://%s-aiplatform.googleapis.com" % region),
        ("aiplatform-mtls", "https://%s-aiplatform.mtls.googleapis.com" % region),
        ("aiplatform-rep", "https://aiplatform.%s.rep.googleapis.com" % region),
        ("agentregistry", "https://agentregistry.googleapis.com"),
        ("logging", "https://logging.googleapis.com"),
        ("telemetry", "https://telemetry.googleapis.com"),
        ("cloudtrace", "https://cloudtrace.googleapis.com"),
        ("monitoring", "https://monitoring.googleapis.com"),
        ("cloudresourcemanager", "https://cloudresourcemanager.googleapis.com"),
        ("iamcredentials", "https://iamcredentials.googleapis.com"),
        ("walle-sessions", sessions),
    ]


def registry_local_fallback(ctx: Ctx) -> bool:
    """True only when the dated record overturning P71's exclusion is on file."""
    path = os.path.expanduser(ctx.get("REGISTRY_LOCAL_FALLBACK_DECISION") or "")
    return bool(path) and os.path.isfile(path)


def registry_project(ctx: Ctx) -> str:
    """Where Wall-E's registry entries live: CORE_PROJECT (P71), or Wall-E's own
    project on the recorded fallback."""
    if registry_local_fallback(ctx):
        return ctx.need("PROJECT")
    core = ctx.get("CORE_PROJECT")
    if not core:
        die("CORE_PROJECT is empty. Since 2026-09-13 the Agent Registry is the shared one "
            "in CORE_PROJECT (P71); set it, or name the dated record overturning P71's "
            "exclusion in REGISTRY_LOCAL_FALLBACK_DECISION to use a per-project registry.")
    if core == ctx.get("PROJECT"):
        die("CORE_PROJECT equals Wall-E's PROJECT; the shared registry is a core project")
    return core


def check_shared_egress_endpoint(ctx: Ctx, endpoint_id: str, url: str) -> bool:
    """Shared registry (P71): the entry is factory-apply@'s write. Read, never create."""
    assert_egress_host_allowed(url)
    described = gcloud_probe_json_in(ctx, registry_project(ctx), "agent-registry", "services",
                                     "describe", endpoint_id, "--location", ctx.need("REGION"))
    if described is not None:
        step("registered in the shared registry: %s -> %s" % (endpoint_id, url))
        return True
    ctx.note("shared registry lacks %s -> %s: the factory (factory-apply@) writes it" %
             (endpoint_id, url))
    return False


def register_egress_endpoint(ctx: Ctx, endpoint_id: str, url: str) -> None:
    assert_egress_host_allowed(url)
    region, project = ctx.need("REGION"), ctx.need("PROJECT")
    described = gcloud_probe_json(ctx, "agent-registry", "services", "describe", endpoint_id,
                                  "--location", region)
    if described is not None:
        step("registered: %s -> %s" % (endpoint_id, url))
        return
    run(ctx, [
        "gcloud", "agent-registry", "services", "create", endpoint_id,
        "--project=" + project, "--location=" + region,
        "--display-name=" + endpoint_id, "--endpoint-spec-type=no-spec",
        "--interfaces=url=%s,protocolBinding=http-json" % url,
    ])


def check_access_policy_bindings_allowed(ctx: Ctx) -> None:
    """iam.managed.disableAccessPolicyBindings must not be enforced on the project."""
    constraint = "iam.managed.disableAccessPolicyBindings"
    described = gcloud_probe_json(ctx, "org-policies", "describe", constraint,
                                  "--project", ctx.need("PROJECT"), "--effective")
    rules = ((described or {}).get("spec", {}) or {}).get("rules", []) or []
    if any(rule.get("enforce") is True for rule in rules):
        message = (
            "%s is enforced on %s. The egressor binding cannot be created while it is; "
            "lift it (an org-policy change, by the organisation admin) and wait up to "
            "15 minutes for propagation." % (constraint, ctx.need("PROJECT"))
        )
        if ctx.dry_run:
            warn(message)
            return
        die(message)
    step("%s is not enforced (or is unreadable here)" % constraint)


def ensure_egressor_policy(ctx: Ctx, endpoint_id: str, policy_path: str,
                           policy: Dict[str, Any]) -> None:
    region, project = ctx.need("REGION"), ctx.need("PROJECT")
    current = gcloud_probe_json(
        ctx, "iap", "web", "get-iam-policy", "--resource-type=agent-registry",
        "--region=" + region, "--endpoint=" + endpoint_id,
    ) or {}
    have = sorted(
        (b.get("role"), tuple(sorted(b.get("members", []))))
        for b in current.get("bindings", []) or []
    )
    want = sorted((b["role"], tuple(sorted(b["members"]))) for b in policy["bindings"])
    if have == want:
        step("egressor policy current on %s" % endpoint_id)
        return
    run(ctx, ["gcloud", "iap", "web", "set-iam-policy", policy_path, "--project=" + project,
              "--resource-type=agent-registry", "--region=" + region,
              "--endpoint=" + endpoint_id])


def iap_extension_yaml(ctx: Ctx) -> str:
    """13-agent-interconnection.md (c)-3: IAP request authorization, DRY_RUN.

    The field names under metadata are the ones the chapter records
    (iapPolicyVersion V2, iamEnforcementMode DRY_RUN); a live import is the
    first thing that proves their exact spelling.
    """
    region = ctx.need("REGION")
    return (
        "name: %s\n"
        "service: iap.googleapis.com\n"
        "failOpen: false\n"
        "timeout: 1s\n"
        "metadata:\n"
        "  iapPolicyVersion: V2\n"
        "  iamEnforcementMode: DRY_RUN\n" % IAP_EXTENSION_NAME
    ) if region else ""


def iap_policy_yaml(ctx: Ctx, gateway: str) -> str:
    project, region = ctx.need("PROJECT"), ctx.need("REGION")
    return (
        "name: %s\n"
        "target:\n"
        '  resources: ["projects/%s/locations/%s/agentGateways/%s"]\n'
        "policyProfile: REQUEST_AUTHZ\n"
        "action: CUSTOM\n"
        "customProvider:\n"
        "  authzExtension:\n"
        '    resources: ["projects/%s/locations/%s/authzExtensions/%s"]\n'
        % (IAP_POLICY_NAME, project, region, gateway, project, region, IAP_EXTENSION_NAME)
    )


def register_card(ctx: Ctx, card_path: str) -> int:
    """`registry --card PATH`: the hand-written card, only once A2A exists."""
    section("Phase 13b step 4 — register the hand-written agent card")
    path = os.path.expanduser(card_path)
    if not os.path.isfile(path):
        die("no such card: %s" % path)
    try:
        with open(path, "r", encoding="utf-8") as handle:
            card = json.load(handle)
    except ValueError as exc:
        die("%s is not valid JSON: %s" % (path, exc))
    interfaces = list((card or {}).get("supportedInterfaces", []) or [])
    if not interfaces:
        die("%s has no supportedInterfaces; a card without an interface points nowhere"
            % path)
    for interface in interfaces:
        url = str((interface or {}).get("url", "") or "")
        if "tbd" in url.lower() or not url:
            die(
                "REFUSING to register %s: supportedInterfaces url %r is still a "
                "placeholder. The card is registered only in the same change that "
                "stands up the A2A interface it points at, not before Stage 3 "
                "(decision 23)." % (path, url)
            )
        assert_egress_host_allowed(url)
    if not registry_local_fallback(ctx):
        die("REFUSING to register the card from here: since 2026-09-13 the registry is the "
            "shared one in CORE_PROJECT and only factory-apply@ writes it (P71). Commit the "
            "card to the manifest and let the factory register it.")
    bad_skills = [
        str(skill.get("id", ""))
        for skill in (card.get("skills", []) or [])
        if any(marker in str(skill.get("id", "")).lower()
               for marker in FORBIDDEN_CARD_SKILL_MARKERS)
    ]
    if bad_skills:
        die("REFUSING: the card advertises a write, approval or control skill: %s. "
            "Reads and plans only (13-agent-interconnection.md section 3.5)."
            % ", ".join(bad_skills))
    region, project = ctx.need("REGION"), ctx.need("PROJECT")
    entry_id = ctx.get("ENGINE_DISPLAY_NAME") or "wall-e"
    say("  card: %s, %d interface(s), %d skill(s)" % (path, len(interfaces),
                                                     len(card.get("skills", []) or [])))
    say("  Never add a 'Custom agent via A2A' registration in Gemini Enterprise: it is")
    say("  0.3-only and bypasses the gateway.")
    described = gcloud_probe_json(ctx, "agent-registry", "services", "describe", entry_id,
                                  "--location", region)
    if described is not None:
        step("registry service exists: %s (update it through the reviewed pipeline)" % entry_id)
    else:
        confirm(ctx, "Register the card as %s?" % entry_id)
        run(ctx, [
            "gcloud", "agent-registry", "services", "create", entry_id,
            "--project=" + project, "--location=" + region,
            "--display-name=Wall-E", "--agent-spec-type=a2a-agent-card",
            "--agent-spec-content=" + path,
        ])
    for argv in (
        ("agent-registry", "agents", "describe", entry_id, "--location", region),
        ("agent-registry", "agents", "search", "--location", region,
         "--search-string=" + entry_id),
    ):
        result = probe(ctx, ["gcloud"] + list(argv) + ["--project", project])
        say("  %s -> %s" % (" ".join(argv[:3]), "ok" if result.ok else "not readable"))
    ctx.print_notes()
    return 0


def cmd_registry(ctx: Ctx) -> int:
    card = getattr(ctx.args, "card", None)
    if card:
        return register_card(ctx, card)
    section("Phase 13b — Agent Registry, and the egress gateway in dry-run")
    project, region = ctx.need("PROJECT"), ctx.need("REGION")
    local = registry_local_fallback(ctx)
    reg_project = registry_project(ctx)
    gateway = ctx.get("EGRESS_GATEWAY") or EGRESS_GATEWAY_NAME
    if local:
        return cmd_registry_local_fallback(ctx)
    say("  Changed 2026-09-13 (P71): the registry is the SHARED one in %s, written by" % reg_project)
    say("  factory-apply@ only. This project never enables agentregistry.googleapis.com")
    say("  (the tier folder's allow-list refuses it) and no project-level registry role")
    say("  is granted here. This command reads the shared entries and builds the egress")
    say("  gateway in Wall-E's project, in DRY_RUN.")
    say("    registry %s (%s)" % (reg_project, region))
    say("    gateway  %s" % gateway)
    confirm(ctx, "Proceed with the egress gateway setup against the shared registry?")
    ensure_apis_listed(ctx, REGISTRY_APIS, "egress gateway")

    say("")
    say("  step 1: roles. None in this project: roles/agentregistry.admin on %s is" % reg_project)
    say("  factory-apply@'s, humans reach it only through PAM (ent-folder-admin), and no")
    say("  agent principal holds a registry role (decision 43, P71).")

    say("")
    say("  step 2: the entry. Automatic same-project registration has nowhere to land;")
    say("  the factory writes Wall-E's registry card in the shared registry.")
    entry_id = ctx.get("ENGINE_DISPLAY_NAME") or "wall-e"
    entry = gcloud_probe_json_in(ctx, reg_project, "agent-registry", "agents", "describe",
                                 entry_id, "--location", region)
    if entry is None:
        ctx.note("no registry entry %s in %s yet: the factory writes it (P71)"
                 % (entry_id, reg_project))
        say("  no entry named %s in %s yet (the factory's write)" % (entry_id, reg_project))
    else:
        step("entry %s present in the shared registry" % entry_id)

    say("")
    say("  step 3: the registry write alert lives with the platform, in %s:" % reg_project)
    say("    %s" % REGISTRY_AUDIT_FILTER)
    ctx.note("the registry write alert is the platform's, on %s (P71, P80)" % reg_project)

    say("")
    say("  step 4: the hand-written card is the factory's to register (P71), and only in")
    say("  the change that stands up the A2A interface (decision 23).")

    say("")
    say("  step 5: the egress gateway, in dry-run, bound to the shared registry.")
    say("  Assumption: a gateway in Wall-E's project resolves a registry in %s; the" % reg_project)
    say("  P71 nonprod spike confirms it before the first factory run.")
    check_access_policy_bindings_allowed(ctx)
    ensure_agent_gateway(
        ctx, gateway,
        "name: %s\ngoogleManaged:\n  governedAccessPath: AGENT_TO_ANYWHERE\nregistries:\n"
        "  - //agentregistry.googleapis.com/projects/%s/locations/%s\n"
        % (gateway, reg_project, region),
    )
    endpoints = egress_endpoints(ctx)
    present = sum(1 for endpoint_id, url in endpoints
                  if check_shared_egress_endpoint(ctx, endpoint_id, url))
    say("  %d of %d endpoints present in the shared registry; the rest, and the per-endpoint"
        % (present, len(endpoints)))
    say("  roles/iap.egressor bindings for Wall-E's principal, are the factory's writes.")
    say("  the IAP request-authorization extension and policy, iamEnforcementMode DRY_RUN")
    extension_path = write_committed_yaml(ctx, ("config", "gateway"), "walle-iap-ext.yaml",
                                          iap_extension_yaml(ctx))
    ensure_authz_extension(ctx, IAP_EXTENSION_NAME, extension_path, beta=True)
    policy_yaml_path = write_committed_yaml(ctx, ("config", "gateway"), "walle-iap-policy.yaml",
                                            iap_policy_yaml(ctx, gateway))
    ensure_authz_policy(ctx, IAP_POLICY_NAME, policy_yaml_path)
    say("")
    say("  Verify as below (SETUP.md Phase 13b); flip to enforced only after it.")
    ctx.note("egress gateway %s in DRY_RUN against the shared registry in %s"
             % (gateway, reg_project))
    ctx.print_notes()
    return 0


def cmd_registry_local_fallback(ctx: Ctx) -> int:
    """The per-project registry, kept as the recorded fallback of P71 (dated
    2026-09-13): used only when REGISTRY_LOCAL_FALLBACK_DECISION names the dated
    record overturning the exclusion. The steps are the pre-2026-09-13 ones."""
    project, region = ctx.need("PROJECT"), ctx.need("REGION")
    ci_member = iam_member(ctx.need("CI_DEPLOYER"))
    gateway = ctx.get("EGRESS_GATEWAY") or EGRESS_GATEWAY_NAME
    say("  Registry admin to the CI deployer only, and NO viewer to Eve or Mo. The")
    say("  egress gateway is a default-deny hostname allowlist for the reasoning layer,")
    say("  and it starts in DRY_RUN: two undocumented questions gate it to enforced.")
    say("    admin   %s" % ci_member)
    say("    gateway %s" % gateway)
    confirm(ctx, "Proceed with the registry and egress gateway setup?")
    warn("REGISTRY_LOCAL_FALLBACK_DECISION is on file: per-project registry (P71's recorded "
         "fallback). The tier folder's allow-list must carry the dated exception.")
    ensure_apis_listed(ctx, REGISTRY_APIS_LOCAL_FALLBACK, "Agent Registry")

    say("")
    say("  step 1: roles. Nobody else: an editor can redirect every consumer that")
    say("  resolves Wall-E through the registry and flip the tool annotations gateway")
    say("  rules read.")
    ensure_project_binding(ctx, ci_member, "roles/agentregistry.admin")
    # roles/agentregistry.viewer for eve-controller@ and MO_PRINCIPAL is gone:
    # Agent Registry roles are grantable at project level only (no per-agent
    # IAM), so the grant was a project-level role in Wall-E's project for
    # identities from EVE_PROJECT and MO_PROJECT — the one grant with no
    # resource-level form — and no duty of Eve's or Mo's needs it. Dropped per
    # project-topology.md decision 43; Eve asserts the card against the
    # endpoint URL committed in eve/config, Mo never converses with Wall-E.
    say("  No agentregistry.viewer to Eve or Mo: a project-level role in Wall-E's")
    say("  project for a foreign identity is refused (decision 43).")

    say("")
    say("  step 2: the automatic entry. Deploying to Agent Runtime registered Wall-E.")
    entry_id = ctx.get("ENGINE_DISPLAY_NAME") or "wall-e"
    listing = gcloud_probe_json(ctx, "agent-registry", "agents", "list", "--location", region)
    for item in listing or []:
        say("    %s" % (item.get("name") or item))
    entry = gcloud_probe_json(ctx, "agent-registry", "agents", "describe", entry_id,
                              "--location", region)
    if entry is None:
        if not ctx.dry_run:
            die("no registry entry named %s. Agent Runtime registers the engine on its "
                "own at deploy; run 'walle deploy' first." % entry_id)
        say("  [dry run] no entry named %s readable yet" % entry_id)
    else:
        text = json.dumps(entry).lower()
        missing = [a for a in ("runtimeidentity", "runtimereference") if a not in text]
        if missing:
            die("registry entry %s lacks the %s attribute(s); expected RuntimeIdentity "
                "(principal://agents.global.org-...) and RuntimeReference:\n%s"
                % (entry_id, ", ".join(missing), json.dumps(entry)[:600]))
        step("entry %s carries RuntimeIdentity and RuntimeReference" % entry_id)

    say("")
    say("  step 3: alert on registry writes. Commit this query in the repository and")
    say("  wire it to the operator channel:")
    say("    %s" % REGISTRY_AUDIT_FILTER)
    recent = probe(ctx, ["gcloud", "logging", "read", REGISTRY_AUDIT_FILTER,
                         "--project", project, "--limit=5", "--format=json"])
    if recent.ok:
        try:
            rows = json.loads(recent.out) if recent.out.strip() else []
        except ValueError:
            rows = []
        say("  %d registry write(s) in the recent log" % len(rows))
    ctx.note("commit the registry write alert query and wire it to the operator channel")

    say("")
    say("  step 4: the hand-written card is NOT registered here. 'walle registry --card")
    say("  PATH' does it, only in the change that stands up the A2A interface (not")
    say("  before Stage 3, decision 23).")

    say("")
    say("  step 5: the egress gateway, in dry-run. Everything unregistered is denied.")
    check_access_policy_bindings_allowed(ctx)
    ensure_agent_gateway(
        ctx, gateway,
        "name: %s\ngoogleManaged:\n  governedAccessPath: AGENT_TO_ANYWHERE\nregistries:\n"
        "  - //agentregistry.googleapis.com/projects/%s/locations/%s\n"
        % (gateway, project, region),
    )
    endpoints = egress_endpoints(ctx)
    say("  registering %d endpoints; secretmanager, firestore, admin.googleapis.com, every"
        % len(endpoints))
    say("  Workspace host and bigquery are deliberately absent, and refused if named.")
    for endpoint_id, url in endpoints:
        register_egress_endpoint(ctx, endpoint_id, url)
    principal = agent_principal(ctx)
    policy = {"bindings": [{"role": "roles/iap.egressor", "members": [principal]}]}
    policy_path = ctx.scratch_file("walle-egress-policy.json", json.dumps(policy, indent=2))
    say("  access policy, per endpoint, for Wall-E's principal only:")
    say("    roles/iap.egressor -> %s" % principal)
    confirm(ctx, "Apply the egressor policy on all %d endpoints?" % len(endpoints))
    for endpoint_id, _url in endpoints:
        ensure_egressor_policy(ctx, endpoint_id, policy_path, policy)
    say("  the IAP request-authorization extension and policy, iamEnforcementMode DRY_RUN")
    extension_path = write_committed_yaml(ctx, ("config", "gateway"), "walle-iap-ext.yaml",
                                          iap_extension_yaml(ctx))
    ensure_authz_extension(ctx, IAP_EXTENSION_NAME, extension_path, beta=True)
    policy_yaml_path = write_committed_yaml(ctx, ("config", "gateway"), "walle-iap-policy.yaml",
                                            iap_policy_yaml(ctx, gateway))
    ensure_authz_policy(ctx, IAP_POLICY_NAME, policy_yaml_path)

    say("")
    say("  Verify: run a shadow playbook; in the IAP logs expect 200 on walle-actions and")
    say("  a logged deny on an unregistered host; confirm Sessions and tracing still")
    say("  work. Only then flip iamEnforcementMode to enforced and re-run the K0 drill")
    say("  through the gateway path, recording the time in drills/{date}.")
    say("  Two undocumented questions gate dry-run to enforced: whether the gateway")
    say("  forwards the agent's own bearer token untouched to walle-actions, and whether")
    say("  an Agent Identity principal can mint an ID token for a Cloud Run audience")
    say("  (the spike). If either fails the gateway stays in dry-run for the pilot.")
    ctx.note("egress gateway %s in DRY_RUN; flip to enforced only after the verify above"
             % gateway)
    ctx.print_notes()
    return 0


def cmd_triggers(ctx: Ctx) -> int:
    section("Phase 16 — the Gmail watch and its renewal")
    say(
        "  A Gmail watch expires after seven days, silently. No error, no event, no "
        "delivery. A dead trigger looks exactly like a quiet week."
    )
    ensure_topic_binding(
        ctx, "walle-inbox",
        "serviceAccount:gmail-api-push@system.gserviceaccount.com",
        "roles/pubsub.publisher",
    )
    ensure_push_subscription(
        ctx, "walle-inbox-push", "walle-inbox",
        "%s/inbox" % dry_run_placeholder(ctx, "DISPATCHER_URL"),
    )
    ensure_watch_renew_job(ctx)
    do_manual_step(ctx, "M9")
    ensure_watch_alert(ctx)
    phase_16_verification(ctx)
    ctx.print_notes()
    return 0


def phase_16_verification(ctx: Ctx) -> None:
    """SETUP.md Phase 16's verification has three steps, and the third is the
    point of the phase.

    "Break it on purpose, the way it actually breaks. Pause
    walle-gmail-watch-renew, and do not write the metric by any other means.
    Confirm the ABSENCE condition fires within 90 minutes. Do not test this by
    forcing the value below the threshold: that only proves the comparison
    works, and the comparison is the branch that already works." Skipping it
    means you have a renewal job and no evidence that its failure is visible.
    """
    section("Phase 16 verification — the part that is the point of the phase")
    say("  1. Send a plain mail to %s from your own account. Within a minute a T3"
        % ctx.need("ROBOT"))
    say("     run appears in the dispatcher log with a read-only operation set, and")
    say("     the audit rows show principal_type=inbox.")
    say("  2. Confirm nothing was proposed and nothing executed: at Stage 0 the")
    say("     inbox trigger is L0, so the correct outcome is a denial with level_off.")
    say("  3. Break the renewal ON PURPOSE and prove the ABSENCE condition fires.")
    say("     Do NOT force the value below the threshold: that only proves the")
    say("     comparison, which is the branch that already works.")
    location = ["--location", ctx.need("REGION"), "--project", ctx.need("PROJECT")]
    if not getattr(ctx.args, "drill_watch_alert", False):
        ctx.note(
            "Phase 16 verify step 3 (break the renewal deliberately) was NOT run. "
            "Re-run with 'walle triggers --drill-watch-alert'. Stage 0 entry needs it."
        )
        warn("step 3 not run. Re-run with --drill-watch-alert before Stage 0 entry.")
        return
    confirm(
        ctx,
        "Pause %s for up to 90 minutes to prove the absence condition fires? It "
        "will be resumed in the same sitting." % WATCH_RENEW_JOB,
    )
    run(ctx, ["gcloud", "scheduler", "jobs", "pause", WATCH_RENEW_JOB] + location)
    try:
        confirm(ctx, "Did the ABSENCE condition fire within 90 minutes?")
    finally:
        # This is the one job that must never be left paused: a Gmail watch dies
        # after seven days of silence, with no error and no event (SETUP.md 7.6).
        run(ctx, ["gcloud", "scheduler", "jobs", "resume", WATCH_RENEW_JOB] + location)
        run(ctx, ["gcloud", "scheduler", "jobs", "run", WATCH_RENEW_JOB] + location)
    step("%s is running again and has been forced once" % WATCH_RENEW_JOB)


def ensure_watch_renew_job(ctx: Ctx) -> None:
    """Daily, not weekly: a weekly renewal against a seven day expiry has no
    margin. This is the one job in the whole build that is left RUNNING."""
    described = gcloud_probe_json(
        ctx, "scheduler", "jobs", "describe", WATCH_RENEW_JOB,
        "--location", ctx.need("REGION"),
    )
    if described is None:
        run(
            ctx,
            [
                "gcloud", "scheduler", "jobs", "create", "http", WATCH_RENEW_JOB,
                "--location", ctx.need("REGION"),
                "--schedule", "0 6 * * *",
                "--time-zone", ctx.get("TIMEZONE"),
                "--uri", "%s/v1/internal/gmail-watch-renew"
                % dry_run_placeholder(ctx, "ACTIONS_URL"),
                "--http-method", "POST",
                "--oidc-service-account-email", ctx.need("SA_DISPATCH"),
                "--oidc-token-audience", dry_run_placeholder(ctx, "ACTIONS_URL"),
                "--attempt-deadline", "60s",
                "--max-retry-attempts", "2",
                "--project", ctx.need("PROJECT"),
            ],
        )
        return
    step("scheduler job exists: %s (%s)" % (WATCH_RENEW_JOB, described.get("state")))
    if described.get("state") == "PAUSED":
        warn(
            "%s is PAUSED. Pausing it as collateral damage produces SETUP.md 7.6 "
            "exactly: no T3 runs, no errors, everything looks healthy." % WATCH_RENEW_JOB
        )
        confirm(ctx, "Resume %s?" % WATCH_RENEW_JOB)
        run(ctx, ["gcloud", "scheduler", "jobs", "resume", WATCH_RENEW_JOB,
                  "--location", ctx.need("REGION"), "--project", ctx.need("PROJECT")])


def notification_channels(ctx: Ctx) -> List[Dict[str, Any]]:
    # `gcloud monitoring channels` does not exist. The GA surface has exactly
    # four groups — dashboards, policies, snoozes, uptime — and notification
    # channels live under beta only. GA answers "Invalid choice: 'channels'",
    # which matches no ABSENT_MARKER, so gcloud_probe_json raised and both
    # M9's verifier and the Phase 16 alert policy died. `monitoring policies`
    # below is GA and correct.
    return list(gcloud_probe_json(ctx, "beta", "monitoring", "channels", "list") or [])


def verify_notification_channel(ctx: Ctx) -> Tuple[str, str]:
    channels = notification_channels(ctx)
    if not channels:
        return "FAIL", "no notification channel exists; an alert policy without one is a dashboard"
    return "PASS", "%d notification channel(s)" % len(channels)


def ensure_watch_alert(ctx: Ctx) -> None:
    """The ABSENCE condition is the one that matters.

    The metric is written by the renewal endpoint itself, so the failure this
    phase exists to catch — renewal paused, failing, or refused by the caller
    allowlist — produces no data points at all and a threshold condition never
    fires.
    """
    existing = gcloud_probe_json(ctx, "monitoring", "policies", "list") or []
    for policy in existing:
        if policy.get("displayName") == "Wall-E Gmail watch stale":
            step("alert policy exists: Wall-E Gmail watch stale")
            return
    channels = notification_channels(ctx)
    if not channels:
        die("no notification channel; refusing to create an alert nobody receives")
    channel_lines = "\n".join("  - %s" % c["name"] for c in channels)
    metric = 'metric.type="custom.googleapis.com/walle/gmail_watch_hours_remaining"'
    policy_yaml = (
        'displayName: "Wall-E Gmail watch stale"\n'
        "combiner: OR\n"
        "conditions:\n"
        '  - displayName: "gmail watch expiry within 48h"\n'
        "    conditionThreshold:\n"
        "      filter: '%s'\n"
        "      comparison: COMPARISON_LT\n"
        "      thresholdValue: 48\n"
        "      duration: 600s\n"
        "      evaluationMissingData: EVALUATION_MISSING_DATA_ACTIVE\n"
        "      aggregations:\n"
        "        - alignmentPeriod: 600s\n"
        "          perSeriesAligner: ALIGN_MIN\n"
        '  - displayName: "gmail watch metric absent: renewal has stopped running"\n'
        "    conditionAbsent:\n"
        "      filter: '%s'\n"
        "      duration: 5400s\n"
        "notificationChannels:\n%s\n" % (metric, metric, channel_lines)
    )
    say("  creating the Gmail watch alert with a threshold AND an absence condition")
    if ctx.dry_run:
        say("  WOULD RUN: gcloud monitoring policies create --policy-from-file=<generated>")
        return
    confirm(ctx, "Create the 'Wall-E Gmail watch stale' alert policy?")
    handle = tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False, encoding="utf-8")
    try:
        handle.write(policy_yaml)
        handle.close()
        run(ctx, ["gcloud", "monitoring", "policies", "create",
                  "--policy-from-file=%s" % handle.name, "--project", ctx.need("PROJECT")])
    finally:
        os.unlink(handle.name)


# --------------------------------------------------------------------------- #
# verify — every check is named, asserted, and fails loudly on its own
# --------------------------------------------------------------------------- #

PASS, FAIL, SKIP = "PASS", "FAIL", "SKIP"
CheckResult = Tuple[str, str]


def impersonation_works(ctx: Ctx, sa_email: str) -> Tuple[bool, str]:
    """Can the OPERATOR actually impersonate this service account?

    A check that cannot fail is worse than no check. Both "the service account
    is refused" proofs below run a command under
    CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT and read ANY failure as the
    invariant holding. Nothing in this script ever grants the operator
    roles/iam.serviceAccountTokenCreator on walle-actions@ or walle-agent@
    (Phase 6 grants it on walle-operators-caller@ only), so on a normal run the
    IMPERSONATION fails, with a message that contains both "permission" and
    "denied" and reads exactly like the resource refusing. Two of the most
    important invariants in the design would then pass on a completely broken
    system, without either probe ever reaching Google's authorisation decision.
    """
    result = read_only_run(
        ctx,
        ["gcloud", "auth", "print-access-token",
         "--impersonate-service-account", sa_email],
        check=False,
    )
    if result.ok:
        return True, ""
    return False, (
        "INCONCLUSIVE: cannot impersonate %s, so a refusal here would prove "
        "nothing at all — it would be your own lack of tokenCreator, not the "
        "resource. Grant yourself roles/iam.serviceAccountTokenCreator on it for "
        "the duration of this check and re-run. gcloud said: %s"
        % (sa_email, (result.err or "").strip().replace("\n", " ")[:160])
    )


def _members_with_role(policy: Dict[str, Any], role_substr: str) -> List[str]:
    found = []
    for binding in (policy or {}).get("bindings", []):
        if role_substr in binding.get("role", ""):
            found.extend(binding.get("members", []))
    return found


def _roles_of_member(policy: Dict[str, Any], member: str) -> List[str]:
    return [
        binding["role"]
        for binding in (policy or {}).get("bindings", [])
        if member in binding.get("members", [])
    ]


def check_agent_reads_no_secret(ctx: Ctx) -> CheckResult:
    """Trust boundary 3, in one check. Re-run it after EVERY IAM change."""
    agent = "serviceAccount:" + ctx.need("SA_AGENT")
    offenders = []
    # Wall-E's three secrets, in Wall-E's project. Eve's two are in EVE_PROJECT
    # and are read there below; iterating them here would hit nothing and the
    # check would silently narrow.
    for secret in WALLE_SECRETS:
        if not secret_exists(ctx, secret):
            continue
        policy = gcloud_probe_json(
            ctx, "secrets", "get-iam-policy", secret, "--location", ctx.need("REGION")
        ) or {}
        if _roles_of_member(policy, agent):
            offenders.append(secret)
    project_policy = gcloud_probe_json(ctx, "projects", "get-iam-policy", ctx.need("PROJECT")) or {}
    broad = [
        role for role in _roles_of_member(project_policy, agent)
        if "secretmanager" in role or "cloudkms" in role or role in ("roles/owner", "roles/editor")
    ]
    if broad:
        offenders.append("project roles %s" % broad)
    # The cross-project half: Eve's key and secrets live in EVE_PROJECT. Read
    # them THERE, explicitly; if the operator cannot, say so rather than pass.
    eve_side, eve_detail = _eve_side_policies(ctx)
    for label, policy in eve_side.items():
        if _roles_of_member(policy, agent):
            offenders.append("%s in EVE_PROJECT" % label)
    if offenders:
        return FAIL, "walle-agent@ can reach: %s" % ", ".join(offenders)
    return PASS, "walle-agent@ holds nothing on any Wall-E secret or project-wide; %s" % eve_detail


def _eve_side_policies(ctx: Ctx) -> Tuple[Dict[str, Dict[str, Any]], str]:
    """IAM policies of Eve's key, ring and secrets, read in EVE_PROJECT.

    Returns what could be read, and a sentence saying what could not. A
    permission refusal is not a failure of the invariant: the assertion then
    belongs to Eve's own verify (project-topology.md row 17, decision 46), and
    the sentence names it so a green row never hides an unread policy.
    """
    eve_project = ctx.need("EVE_PROJECT")
    region = ctx.need("REGION")
    policies: Dict[str, Dict[str, Any]] = {}
    absent: List[str] = []
    try:
        reads: List[Tuple[str, Tuple[str, ...]]] = [
            ("kms key %s" % ctx.get("KMS_KEY"),
             ("kms", "keys", "get-iam-policy", ctx.get("KMS_KEY"),
              "--keyring", ctx.get("KMS_KEYRING"), "--location", region)),
            ("kms keyring %s" % ctx.get("KMS_KEYRING"),
             ("kms", "keyrings", "get-iam-policy", ctx.get("KMS_KEYRING"),
              "--location", region)),
        ]
        for secret in EVE_SECRETS:
            reads.append(("secret %s" % secret,
                          ("secrets", "get-iam-policy", secret, "--location", region)))
        for label, argv in reads:
            policy = gcloud_probe_json_in(ctx, eve_project, *argv)
            if policy is None:
                absent.append(label)
            else:
                policies[label] = policy
    except WalleError as exc:
        return policies, (
            "Eve's key and secrets in EVE_PROJECT %s could not be read (%s); their "
            "policies are asserted by Eve's verify, not here" % (
                eve_project, str(exc).splitlines()[0][:60]))
    if absent:
        return policies, "in EVE_PROJECT %s, not created yet: %s" % (eve_project, ", ".join(absent))
    return policies, "and nothing on Eve's key, ring or secrets in EVE_PROJECT %s" % eve_project


def check_eve_role_is_read_only(ctx: Ctx) -> CheckResult:
    """Allowlist first. A denylist over names Google does not publish in full
    cannot prove "no write privilege at all" (SETUP.md Phase 2 step 4).

    Rewritten 2026-09-13: this was stage0_role_has_no_write and asserted
    Wall-E's Stage 0 reader role. That role is retired (the robot holds Super
    Admin); the same allowlist discipline now bounds Eve's role, the one custom
    role this script still builds.
    """
    role = find_role(ctx, ROLE_EVE_NAME)
    if not role:
        return FAIL, "role '%s' does not exist" % ROLE_EVE_NAME
    names = {p["privilegeName"] for p in role.get("rolePrivileges", [])}
    expected = {
        p["privilegeName"]
        for p in resolve_privileges(ctx, list_privileges(ctx), EVE_PRIVILEGE_CANDIDATES)
    }
    unexpected = sorted(names - expected)
    if unexpected:
        return FAIL, (
            "privileges beyond the resolved Eve read set: %s. Whatever they are "
            "called, this role is assigned to Eve's robot customer-scoped." % unexpected
        )
    offenders = sorted(n for n in names if is_write_privilege(n))
    if offenders:
        return FAIL, "write privileges in Eve's role: %s" % ", ".join(offenders)
    licence = sorted(n for n in names if "LICEN" in n.upper())
    if licence:
        return FAIL, "License Management is a write privilege and never Eve's: %s" % licence
    return PASS, "%d privileges, exactly the resolved read set" % len(names)


def _super_admin_role_ids(ctx: Ctx) -> List[str]:
    """roleIds whose Role resource says isSuperAdminRole (Directory API roles
    resource, read 2026-09-13)."""
    roles = admin(ctx).roles()
    request = roles.list(customer=ctx.need("CUSTOMER_ID"), maxResults=100)
    return [str(r.get("roleId")) for r in paginate(ctx, roles, request, "items")
            if r.get("isSuperAdminRole")]


def check_role_assignments(ctx: Ctx) -> CheckResult:
    """Rewritten 2026-09-13 for a super-admin robot (platform HLD §13.1).

    Robot: after the tier gate (SUPER_ADMIN_GRANT_DECISION on file) it holds
    exactly one role assignment, and that role is the Super Admin role; before
    the gate it holds none. Either way it holds no retired Wall-E role and no
    other custom or delegated role: a second role on a super admin grants
    nothing more, so its only effect would be to hide a change on the roster.
    Eve: exactly one customer-scoped assignment of Eve's read-only role.
    """
    robot = api_get(ctx, "users.get robot", admin(ctx).users().get(userKey=ctx.need("ROBOT")))
    if not robot:
        return FAIL, "robot account does not exist"
    problems: List[str] = []
    assignments = list_role_assignments(ctx)
    on_robot = [a for a in assignments if a.get("assignedTo") == robot["id"]]
    super_ids = set(_super_admin_role_ids(ctx))
    granted = super_admin_grant_on_file(ctx)
    for title in RETIRED_WALLE_ROLE_NAMES:
        role = find_role(ctx, title)
        if role and any(a.get("roleId") == role["roleId"] for a in assignments):
            problems.append("retired role '%s' is still ASSIGNED (reversed 2026-09-13; "
                            "rollback --phase 2 removes it)" % title)
    non_super = [a.get("roleId") for a in on_robot if str(a.get("roleId")) not in super_ids]
    if non_super:
        problems.append("the robot holds role assignment(s) other than Super Admin: roleIds %s"
                        % non_super)
    super_on_robot = [a for a in on_robot if str(a.get("roleId")) in super_ids]
    if granted and len(super_on_robot) != 1:
        problems.append("the grant record is on file but the robot holds %d Super Admin "
                        "assignment(s), expected exactly one (role_assignment_missing)"
                        % len(super_on_robot))
    if not granted and super_on_robot:
        problems.append("the robot holds Super Admin and SUPER_ADMIN_GRANT_DECISION names no "
                        "signed record: the tier gate was skipped")
    eve_role = find_role(ctx, ROLE_EVE_NAME)
    eve = api_get(ctx, "users.get eve", admin(ctx).users().get(userKey=ctx.need("EVE_ROBOT")))
    eve_detail = "Eve holds exactly her customer-scoped read role"
    if not (eve_role and eve):
        # Corrected 2026-09-13: this half used to be skipped silently while the
        # PASS text still asserted it. Eve's observe-and-report layer is a
        # precondition of the grant (G1), so after the grant her absence FAILs;
        # before it, the detail says what was not checked.
        absent = [n for n, v in (("role '%s'" % ROLE_EVE_NAME, eve_role),
                                 ("account %s" % ctx.need("EVE_ROBOT"), eve)) if not v]
        if granted:
            problems.append("Eve's %s not present although the grant record is on file "
                            "(Eve's observe-and-report layer precedes the grant)"
                            % " and ".join(absent))
        eve_detail = "Eve's %s not present yet, so her role was NOT checked" % " and ".join(absent)
    if eve_role and eve:
        eve_assignments = [a for a in assignments if a.get("assignedTo") == eve["id"]]
        if [a.get("roleId") for a in eve_assignments] != [eve_role["roleId"]]:
            problems.append("Eve's robot holds %s, expected exactly '%s'"
                            % ([a.get("roleId") for a in eve_assignments], ROLE_EVE_NAME))
        elif eve_assignments[0].get("scopeType") != "CUSTOMER":
            problems.append(
                "Eve's role is scoped %s, not CUSTOMER. Under an OU-scoped role the admin "
                "enumeration returns nothing and an empty result reads as success "
                "(attack A7)." % eve_assignments[0].get("scopeType"))
        eve_writes = sorted(
            p["privilegeName"] for p in eve_role.get("rolePrivileges", [])
            if is_write_privilege(p["privilegeName"])
        )
        if eve_writes:
            problems.append("'%s' carries write privileges: %s. Eve never acts on "
                            "Workspace, at any stage, ever" % (ROLE_EVE_NAME, eve_writes))
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, (
        "robot holds %s; no retired Wall-E role assigned; %s" % (
            "exactly Super Admin (grant on file)" if granted
            else "no admin role (tier gate not passed)", eve_detail)
    )


def check_secrets_regional_and_pinned(ctx: Ctx) -> CheckResult:
    missing = [s for s in WALLE_SECRETS if not secret_exists(ctx, s)]
    if missing:
        return FAIL, "not regional in %s (or absent): %s" % (ctx.need("REGION"), missing)
    env = deployed_actions_env(ctx)
    if env is None:
        return SKIP, "walle-actions is not deployed yet"
    version = env.get("REFRESH_TOKEN_VERSION", "")
    if not version.isdigit():
        return FAIL, "REFRESH_TOKEN_VERSION is %r, not a version NUMBER" % version
    # The mirror-image trap: every Phase 9 rollback, re-bootstrap, K4 and K5
    # drill destroys the old version and prints a higher number. A service
    # pinned to a destroyed version fails with an invalid_grant that matches no
    # cause in SETUP.md 7.4.
    described = gcloud_probe_json(
        ctx, "secrets", "versions", "describe", version,
        "--secret", "walle-refresh-token", "--location", ctx.need("REGION"),
    )
    if described is None:
        return FAIL, (
            "the deployed revision pins walle-refresh-token version %s and no such "
            "version exists. Re-export REFRESH_TOKEN_VERSION and redeploy "
            "walle-actions (SETUP.md 7.4)." % version
        )
    state = described.get("state")
    if state != "ENABLED":
        return FAIL, (
            "walle-refresh-token version %s is %s, not ENABLED. The service is "
            "pinned to a dead credential and every Workspace call will fail with "
            "invalid_grant." % (version, state)
        )
    latest = [k for k, v in env.items() if "latest" in str(v).lower()]
    if latest:
        return FAIL, "these env values contain 'latest': %s" % latest
    super_env = deployed_service_env(ctx, SUPER_SERVICE)
    super_detail = "walle-actions-super not deployed"
    if super_env is not None:
        super_version = super_env.get("REFRESH_TOKEN_VERSION", "")
        described = gcloud_probe_json(
            ctx, "secrets", "versions", "describe", super_version or "0",
            "--secret", SUPER_CLIENT_SECRETS[1], "--location", ctx.need("REGION"),
        ) if super_version.isdigit() else None
        if not described or described.get("state") != "ENABLED":
            return FAIL, ("walle-actions-super pins %s version %r, which is absent or not "
                          "ENABLED" % (SUPER_CLIENT_SECRETS[1], super_version))
        if any("latest" in str(v).lower() for v in super_env.values()):
            return FAIL, "walle-actions-super env contains 'latest'"
        super_detail = "walle-actions-super pins version %s" % super_version
    return PASS, "%d regional secrets; walle-actions pins version %s; %s; no 'latest'" % (
        len(WALLE_SECRETS), version, super_detail)


def check_kms_separation(ctx: Ctx) -> CheckResult:
    """Attack A2, with the key in EVE_PROJECT (project-topology.md row 14).

    What this script can assert at HOME, and does on every run: no Wall-E
    principal holds any Cloud KMS role in Wall-E's own project policy, and the
    pinned PEM set exists in the repository when Eve's key does. What it can
    assert only by reading EVE_PROJECT: walle-actions@ holds either nothing on
    Eve's key (the PEM pin is primary) or exactly roles/cloudkms.publicKeyViewer
    on that one key, never signer, never anything on the ring or the project.
    The "purpose is ASYMMETRIC_SIGN" and "eve-controller@ holds signer"
    assertions are Eve's verify (decision 46); they are read here only when
    the operator can, and reported as such.
    """
    problems: List[str] = []
    project_policy = gcloud_probe_json(ctx, "projects", "get-iam-policy", ctx.need("PROJECT")) or {}
    for key in ("SA_ACTIONS", "SA_ACTIONS_SUPER", "SA_AGENT", "SA_DISPATCH", "SA_OPS_CALLER"):
        member = "serviceAccount:" + ctx.need(key)
        held = [
            r for r in _roles_of_member(project_policy, member)
            if "cloudkms" in r or r in ("roles/owner", "roles/editor")
        ]
        if held:
            problems.append("%s holds %s in Wall-E's project" % (ctx.need(key), held))
    pem_dir = os.path.join(os.path.expanduser(ctx.need("WALLE_REPO")), *EVE_PUBLIC_KEYS_SUBDIR)
    pems = sorted(f for f in os.listdir(pem_dir)) if os.path.isdir(pem_dir) else []
    for name in pems:
        path = os.path.join(pem_dir, name)
        if not os.path.isfile(path):
            continue
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            head = handle.read(64)
        if "BEGIN PUBLIC KEY" not in head:
            problems.append("%s is not a PEM public key" % os.path.relpath(path, pem_dir))
    eve_side, eve_detail = _eve_side_policies(ctx)
    key_label = "kms key %s" % ctx.get("KMS_KEY")
    ring_label = "kms keyring %s" % ctx.get("KMS_KEYRING")
    actions_member = "serviceAccount:" + ctx.need("SA_ACTIONS")
    if key_label in eve_side:
        actions_roles = _roles_of_member(eve_side[key_label], actions_member)
        if actions_roles not in ([], ["roles/cloudkms.publicKeyViewer"]):
            problems.append(
                "walle-actions@ holds %s on Eve's key in EVE_PROJECT. It may hold "
                "publicKeyViewer and nothing else, or it can mint an Eve approval "
                "(attack A2)." % actions_roles
            )
        # Whether eve-controller@ holds signer is Eve's verify's assertion
        # (decision 46), not a failure of Wall-E's invariant; it is reported.
        eve_roles = _roles_of_member(eve_side[key_label], "serviceAccount:" + ctx.need("SA_EVE"))
        signer_note = ("eve-controller@ holds signer" if "roles/cloudkms.signer" in eve_roles
                       else "eve-controller@ does NOT hold signer yet (Eve's verify asserts it)")
        eve_detail = "%s; %s" % (eve_detail, signer_note)
        described = gcloud_probe_json_in(
            ctx, ctx.need("EVE_PROJECT"), "kms", "keys", "describe", ctx.get("KMS_KEY"),
            "--keyring", ctx.get("KMS_KEYRING"), "--location", ctx.need("REGION"),
        ) or {}
        if described:
            purpose = described.get("purpose")
            algorithm = (described.get("versionTemplate", {}) or {}).get("algorithm")
            if purpose != "ASYMMETRIC_SIGN" or algorithm != "EC_SIGN_P256_SHA256":
                problems.append("Eve's key is %s / %s, not ASYMMETRIC_SIGN / "
                                "EC_SIGN_P256_SHA256; a purpose cannot be changed"
                                % (purpose, algorithm))
            if not pems:
                problems.append(
                    "Eve's key exists but %s/ holds no pinned PEM; the pin is the primary "
                    "verification path and past approvals stay verifiable only against it"
                    % "/".join(EVE_PUBLIC_KEYS_SUBDIR)
                )
    # A key-level policy does not subtract an inherited one: a Wall-E
    # principal on Eve's RING would put walle-actions@ back in a position to
    # mint an approval with the key-level read green.
    if ring_label in eve_side and _roles_of_member(eve_side[ring_label], actions_member):
        problems.append("walle-actions@ holds a role on Eve's key RING, which the key inherits")
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, (
        "no Wall-E principal holds a KMS role in Wall-E's project; %d pinned PEM(s); %s"
        % (len(pems), eve_detail)
    )


def check_actions_cannot_delete_bigquery(ctx: Ctx) -> CheckResult:
    """Reads the dataset access array, then PROVES it by impersonation.

    SETUP.md Phase 8's own version of this runs bq as the operator, who is
    usually a project owner: the DELETE then succeeds and the check reads as a
    control failure that is not one. Impersonating walle-actions@ is the only way
    this proves anything.
    """
    target = "%s:%s" % (ctx.need("PROJECT"), ctx.get("AUDIT_DATASET"))
    shown = probe(ctx, ["bq", "show", "--format=prettyjson", target])
    if not shown.ok:
        return SKIP, "cannot read dataset %s" % target
    access = json.loads(shown.out).get("access", [])
    entries = [a for a in access if a.get("userByEmail") == ctx.need("SA_ACTIONS")]
    expected = "projects/%s/roles/walleAuditWriter" % ctx.need("PROJECT")
    if [a.get("role") for a in entries] != [expected]:
        return FAIL, "walle-actions@ dataset access is %s, expected only %s" % (entries, expected)
    project_policy = gcloud_probe_json(ctx, "projects", "get-iam-policy", ctx.need("PROJECT")) or {}
    bq_roles = [
        r for r in _roles_of_member(project_policy, "serviceAccount:" + ctx.need("SA_ACTIONS"))
        if "bigquery" in r
    ]
    if bq_roles:
        return FAIL, "project-level BigQuery roles undo the insert-only control: %s" % bq_roles
    if ctx.dry_run:
        # WHERE FALSE deletes no rows, but it is still DML against the audit
        # table and it still runs a BigQuery job. mutating=False below is about
        # get-or-create ordering, not about this being harmless.
        return SKIP, "--dry-run: the DELETE probe is real DML, even with WHERE FALSE"
    can, why = impersonation_works(ctx, ctx.need("SA_ACTIONS"))
    if not can:
        return SKIP, why
    project, dataset = ctx.need("PROJECT"), ctx.get("AUDIT_DATASET")
    # The only place in this file where a config value becomes SQL rather than
    # an argv element. A backtick or a semicolon would close the quoted
    # identifier and append statements that run as an impersonated service
    # account.
    if not re.match(r"^[a-z][a-z0-9-]{4,28}[a-z0-9]$", project) or not re.match(
        r"^\w+$", dataset
    ):
        return SKIP, "PROJECT or AUDIT_DATASET is not a plain identifier; refusing to build SQL"
    proof = run(
        ctx,
        [
            "bq", "--project_id", project, "query", "--use_legacy_sql=false",
            "DELETE FROM `%s.%s.actions` WHERE FALSE" % (project, dataset),
        ],
        mutating=False,
        check=False,
        env={"CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT": ctx.need("SA_ACTIONS")},
    )
    if proof.ok:
        return FAIL, "a DELETE as walle-actions@ SUCCEEDED; the insert-only control does not exist"
    reason = (proof.err or "").lower()
    if "bigquery.jobs.create" in reason:
        # A PROJECT-level refusal. walle-actions@ holds no bigquery role at all,
        # so bq is turned away before BigQuery ever evaluates the dataset ACL:
        # the insert-only role was not exercised. If someone later grants
        # roles/bigquery.jobUser for legitimate reasons this check would have
        # silently changed meaning.
        return SKIP, (
            "the DELETE was refused for lack of bigquery.jobs.create, which is a "
            "project-level denial. It does not exercise the dataset-level "
            "insert-only role at all"
        )
    if "denied" not in reason and "permission" not in reason:
        return SKIP, "DELETE failed for a reason other than access: %s" % proof.err.strip()[:200]
    if "bigquery" not in reason and dataset.lower() not in reason:
        return SKIP, (
            "the DELETE was refused, but the message names neither BigQuery nor %s, "
            "so it may not be the dataset refusing: %s" % (dataset, proof.err.strip()[:160])
        )
    return PASS, "insert-only role only, and a DELETE as walle-actions@ is refused by BigQuery"


def check_sink_filters(ctx: Ctx) -> CheckResult:
    """Inspect the filter, do not count rows.

    At this phase the robot has made no writes, so a row count returns zero
    whether or not the exclusion is present and passes identically on a broken
    sink. That is the defect this check exists to catch.
    """
    org = ctx.need("ORG_ID")
    trigger = gcloud_probe_json(ctx, "logging", "sinks", "describe", "walle-workspace-audit",
                                "--organization", org)
    bq_sink = gcloud_probe_json(ctx, "logging", "sinks", "describe", "walle-audit-bq",
                                "--organization", org)
    if trigger is None or bq_sink is None:
        return SKIP, "one or both organisation-level sinks do not exist yet"
    exclusion = 'principalEmail!="%s"' % ctx.need("ROBOT")
    if exclusion not in trigger.get("filter", ""):
        return FAIL, "MISSING ACTOR EXCLUSION on walle-workspace-audit (attack A5)"
    if exclusion in bq_sink.get("filter", ""):
        return FAIL, (
            "walle-audit-bq excludes the robot. Reconciliation needs every "
            "robot-attributed event, or audit completeness has no data source"
        )
    destination = bq_sink.get("destination", "")
    if ctx.get("LOGS_DATASET") not in destination:
        return FAIL, "the BigQuery sink points at %s, not %s" % (destination, ctx.get("LOGS_DATASET"))
    return PASS, "trigger sink excludes the robot; BigQuery sink does not; separate dataset"


def check_engine_principals(ctx: Ctx) -> CheckResult:
    """Exactly the two of project-topology.md rows 1 and 13, by exact set.

    Counting was the old check, and a policy that still carries Wall-E's OWN
    service-<PROJECT_NUMBER>@gcp-sa-discoveryengine (the pre-2026-09-13 state)
    or eve-controller@ (C10) would pass a count. The set is asserted.
    """
    engine_id = resolve_engine_id(ctx)
    if not engine_id:
        return SKIP, "no single reasoning engine to check"
    number = gemini_project_number(ctx)
    if not number:
        return SKIP, "GEMINI_PROJECT_NUMBER is unknown; cannot name the app's service agent"
    # :getIamPolicy on the Agent Runtime REST API is a POST with an empty body.
    status, policy = http_json(
        ctx, "POST",
        aiplatform_url(
            ctx, "%s/%s:getIamPolicy" % (engine_collection_path(ctx), engine_id)
        ),
        access_token(ctx), {}, mutating=False,
    )
    if status != 200 or not isinstance(policy, dict):
        return FAIL, "engine %s has no readable IAM policy (HTTP %s)" % (engine_id, status)
    members = sorted({m for b in policy.get("bindings", []) for m in b.get("members", [])})
    roles = {b.get("role") for b in policy.get("bindings", [])}
    expected_role = "projects/%s/roles/walleEngineQuery" % ctx.need("PROJECT")
    if roles != {expected_role}:
        return FAIL, "engine policy carries roles %s, expected only %s" % (roles, expected_role)
    gemini_agent = (
        "serviceAccount:service-%s@gcp-sa-discoveryengine.iam.gserviceaccount.com" % number
    )
    expected_members = sorted({gemini_agent, "serviceAccount:" + ctx.need("SA_DISPATCH")})
    if members != expected_members:
        walle_agent = ("serviceAccount:service-%s@gcp-sa-discoveryengine.iam.gserviceaccount.com"
                       % (project_number(ctx) or "<PROJECT_NUMBER>"))
        hints = []
        if walle_agent in members:
            hints.append("it carries WALL-E's own project number's service agent, which "
                         "never calls the engine: the app's is GEMINI_PROJECT_NUMBER's")
        if "serviceAccount:" + ctx.need("SA_EVE") in members:
            hints.append("eve-controller@ is a member; C10 removed it (topology row 13)")
        return FAIL, "engine principals are %s, expected exactly %s%s" % (
            members, expected_members, "; " + "; ".join(hints) if hints else "")
    # SETUP.md 6.1 says "counting inherited project and organisation bindings".
    # A resource-level policy does not override an inherited one, and all four
    # roles below confer aiplatform.reasoningEngines.query — roles/editor and
    # roles/owner included, which the old check never looked for. One editor
    # group at project level and an arbitrary number of principals can invoke
    # the agent, which is exactly the property that makes Gemini Enterprise's
    # asserted end-user email trustworthy.
    conferring = [
        "roles/aiplatform.user", "roles/aiplatform.admin",
        "roles/editor", "roles/owner",
    ]
    # Decision 42's fallback role is project-level and Google's; whether it
    # carries reasoningEngines.query is read back, not assumed. No --project:
    # it is a predefined role, not one of the project's custom roles.
    fallback_confers = False
    described = probe(ctx, ["gcloud", "iam", "roles", "describe", GEMINI_FALLBACK_ROLE,
                            "--format=json"])
    if described.ok and described.out.strip():
        permissions = (json.loads(described.out) or {}).get("includedPermissions", []) or []
        fallback_confers = "aiplatform.reasoningEngines.query" in permissions
        if fallback_confers:
            conferring.append(GEMINI_FALLBACK_ROLE)
    fallback_on_file = gemini_access_fallback_on_file(ctx)
    inherited: List[str] = []
    for label, argv in (
        ("project", ("projects", "get-iam-policy", ctx.need("PROJECT"))),
        ("organisation", ("organizations", "get-iam-policy", ctx.need("ORG_ID"))),
    ):
        scope_policy = gcloud_probe_json(ctx, *argv) or {}
        for binding in scope_policy.get("bindings", []):
            if binding.get("role") in conferring:
                for m in binding.get("members", []):
                    # The one recorded exception: the app's service agent holding
                    # the documented fallback at project level, with the spike
                    # on file saying row 1 was not enough.
                    if (binding["role"] == GEMINI_FALLBACK_ROLE and m == gemini_agent
                            and fallback_on_file and label == "project"):
                        continue
                    inherited.append("%s (%s at %s)" % (m, binding["role"], label))
    if inherited:
        return FAIL, (
            "the two-principal lock does not hold: these can also query the engine "
            "through an inherited binding: %s" % sorted(set(inherited))
        )
    return PASS, "exactly the app's service agent (%s) and walle-dispatcher@; no inherited " \
                 "binding confers query%s" % (
                     number, "; decision 42 fallback on file" if fallback_on_file else "")


def check_scheduler_states(ctx: Ctx) -> CheckResult:
    jobs = gcloud_probe_json(ctx, "scheduler", "jobs", "list", "--location", ctx.need("REGION"))
    if not jobs:
        return SKIP, "no scheduler jobs exist yet"
    bad = []
    watch_state = None
    for job in jobs:
        name = job.get("name", "").rsplit("/", 1)[-1]
        state = job.get("state")
        if name == WATCH_RENEW_JOB:
            watch_state = state
            continue
        if state != "PAUSED":
            bad.append("%s=%s" % (name, state))
    if bad:
        return FAIL, "playbook jobs not paused: %s" % ", ".join(bad)
    if watch_state is None:
        return FAIL, "%s does not exist; the watch dies silently after 7 days" % WATCH_RENEW_JOB
    if watch_state != "ENABLED":
        return FAIL, "%s is %s; it is the one job that must never be paused" % (
            WATCH_RENEW_JOB, watch_state)
    return PASS, "%d playbook jobs paused, %s running" % (len(jobs) - 1, WATCH_RENEW_JOB)


def deployed_actions_env(ctx: Ctx) -> Optional[Dict[str, str]]:
    return deployed_service_env(ctx, ACTIONS_SERVICE)


def deployed_service_env(ctx: Ctx, service: str) -> Optional[Dict[str, str]]:
    """The env of one deployed Cloud Run service. None when not deployed."""
    described = gcloud_probe_json(
        ctx, "run", "services", "describe", service, "--region", ctx.need("REGION")
    )
    if described is None:
        return None
    containers = described.get("spec", {}).get("template", {}).get("spec", {}).get(
        "containers", [])
    if not containers:
        return {}
    return {
        entry["name"]: str(entry.get("value", ""))
        for entry in containers[0].get("env", []) or []
        if "name" in entry
    }


def check_actions_env_complete(ctx: Ctx) -> CheckResult:
    env = deployed_actions_env(ctx)
    if env is None:
        return SKIP, "walle-actions is not deployed yet"
    missing = [name for name in ACTIONS_ENV_NAMES if name not in env]
    if missing:
        return FAIL, (
            "missing env vars on the deployed revision: %s. Repeating "
            "--set-env-vars does not merge: the last occurrence wins and every "
            "earlier one is discarded silently." % missing
        )
    # Present is not the same as set. Several values come through ctx.get()
    # rather than ctx.need(), and SETUP.md 1.7 names this failure exactly: an
    # unset config value expands to an empty string and deploys a service that
    # is WRONG rather than failing the command.
    empty = sorted(name for name in ACTIONS_ENV_NAMES if not str(env.get(name, "")).strip())
    if empty:
        return FAIL, (
            "present but EMPTY on the deployed revision: %s. An unset config value "
            "expands to an empty string and deploys a service that is wrong rather "
            "than failing the command (SETUP.md 1.7)." % empty
        )
    url = current_service_url(ctx, "walle-actions")
    if url and env.get("AUDIENCE") != url:
        return FAIL, "AUDIENCE is %r, service URL is %r" % (env.get("AUDIENCE"), url)
    return PASS, (
        "%d env vars present and non-empty, AUDIENCE matches the service URL"
        % len(ACTIONS_ENV_NAMES)
    )


def check_control_caller_allowlist(ctx: Ctx) -> CheckResult:
    env = deployed_actions_env(ctx)
    if env is None:
        return SKIP, "walle-actions is not deployed yet"
    value = env.get("CONTROL_CALLER_ALLOWLIST", "")
    entries = [e.strip() for e in value.split(",") if e.strip()]
    if ctx.need("SA_EVE") not in entries:
        return FAIL, "eve-controller@%s is not in CONTROL_CALLER_ALLOWLIST" % ctx.need("EVE_PROJECT")
    if ctx.need("SA_EVE_VERIFIER") not in entries:
        return FAIL, "eve-verifier@%s is not in CONTROL_CALLER_ALLOWLIST" % ctx.need("EVE_PROJECT")
    # The pre-2026-09-13 placement: an Eve or Mo identity spelled in Wall-E's
    # project. Such an entry is not a typo, it is the old topology deployed.
    old_placement = [
        e for e in entries
        if (e.startswith("eve-") or e.startswith("mo-"))
        and e.endswith("@%s.iam.gserviceaccount.com" % ctx.need("PROJECT"))
    ]
    if old_placement:
        return FAIL, (
            "CONTROL_CALLER_ALLOWLIST names an Eve or Mo identity in Wall-E's own "
            "project: %s. Eve's live in EVE_PROJECT, Mo's in MO_PROJECT." % old_placement
        )
    for key, who in (("SA_EVE_CONSOLE", "eve-console@"), ("SA_MO_ANALYST", "mo-analyst@")):
        if ctx.get(key) and ctx.get(key) in entries:
            return FAIL, "%s is on the CONTROL list; it belongs on the read-endpoint list only" % who
    if ctx.need("OPERATORS") not in entries:
        return FAIL, (
            "the operators group is not in CONTROL_CALLER_ALLOWLIST. Eve alone means "
            "NO HUMAN CAN HALT OR DEMOTE and every kill-switch timing is unmeasurable"
        )
    if ctx.need("SA_AGENT") in entries:
        return FAIL, "walle-agent@ is in the control allowlist; that is the whole design gone"
    return PASS, "contains eve-controller@ and eve-verifier@ (EVE_PROJECT) and %s" % ctx.need("OPERATORS")


def check_read_caller_allowlist(ctx: Ctx) -> CheckResult:
    """project-topology.md §3.1, rows 3 and 8: the read endpoints are
    allowlisted, and the two read-only foreign callers are on THIS list at
    their cross-project addresses and never on the control list (the negative
    half lives in check_control_caller_allowlist)."""
    env = deployed_actions_env(ctx)
    if env is None:
        return SKIP, "walle-actions is not deployed yet"
    value = env.get("READ_CALLER_ALLOWLIST", "")
    entries = [e.strip() for e in value.split(",") if e.strip()]
    if not entries:
        return FAIL, ("READ_CALLER_ALLOWLIST is absent or empty: the read endpoints would "
                      "be open to every run.invoker holder, or closed to Eve's console "
                      "and Mo's analyst")
    problems = []
    mo_analyst = iam_member(ctx.need("MO_PRINCIPAL")).split(":", 1)[-1]
    for who, email in (("eve-console@%s" % ctx.need("EVE_PROJECT"), ctx.need("SA_EVE_CONSOLE")),
                       ("mo-analyst@%s" % ctx.need("MO_PROJECT"), mo_analyst)):
        if email not in entries:
            problems.append("%s is not in READ_CALLER_ALLOWLIST" % who)
    old_placement = [
        e for e in entries
        if (e.startswith("eve-") or e.startswith("mo-"))
        and e.endswith("@%s.iam.gserviceaccount.com" % ctx.need("PROJECT"))
    ]
    if old_placement:
        problems.append("READ_CALLER_ALLOWLIST names an Eve or Mo identity in Wall-E's own "
                        "project: %s" % old_placement)
    if ctx.need("SA_AGENT") in entries:
        problems.append("walle-agent@ is on the read list; the agent reaches the service "
                        "through EXEC_CALLER_ALLOWLIST only")
    control = [e.strip() for e in env.get("CONTROL_CALLER_ALLOWLIST", "").split(",") if e.strip()]
    for who, email in (("eve-console@", ctx.need("SA_EVE_CONSOLE")), ("mo-analyst@", mo_analyst)):
        if email in control:
            problems.append("%s is on the CONTROL list as well as the read list" % who)
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, ("eve-console@ (EVE_PROJECT) and mo-analyst@ (MO_PROJECT) are on the read "
                  "list at their cross-project addresses and on no other")


def check_cloud_run_requires_auth(ctx: Ctx) -> CheckResult:
    problems = []
    checked = 0
    for service in ("walle-actions", SUPER_SERVICE, "walle-dispatcher"):
        policy = gcloud_probe_json(
            ctx, "run", "services", "get-iam-policy", service, "--region", ctx.need("REGION")
        )
        if policy is None:
            continue
        checked += 1
        members = {m for b in policy.get("bindings", []) for m in b.get("members", [])}
        public = members & {"allUsers", "allAuthenticatedUsers"}
        if public:
            problems.append("%s is invocable by %s" % (service, sorted(public)))
        url = current_service_url(ctx, service)
        if url:
            status, _payload = http_json(ctx, "GET", url + "/v1/ladder", "")
            if status not in (401, 403):
                problems.append("%s answered %s unauthenticated, expected 401/403" % (service, status))
    # A check that cannot fail is worse than no check: with neither service
    # deployed the loop body never ran and this returned PASS on an empty
    # project. Absence is SKIP, the way every other absent-resource check here
    # already treats it.
    if not checked:
        return SKIP, "neither Cloud Run service is deployed yet"
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "%d service(s) refuse unauthenticated callers at Cloud Run" % checked


def check_ladder_config(ctx: Ctx) -> CheckResult:
    url = ctx.get("ACTIONS_URL") or current_service_url(ctx, "walle-actions")
    if not url:
        return SKIP, "walle-actions is not deployed yet"
    status, payload = http_json(ctx, "GET", url + "/v1/ladder", id_token(ctx, url))
    if status != 200 or not isinstance(payload, dict):
        return FAIL, "GET /v1/ladder returned HTTP %s: %s" % (status, str(payload)[:200])
    problems = []
    if str(payload.get("stage")) != "0":
        problems.append("stage is %s, not 0" % payload.get("stage"))
    defaults = payload.get("defaults", {}) or {}
    if str(defaults.get("daily_write_budget", payload.get("daily_write_budget"))) != "0":
        problems.append("daily_write_budget is not 0")
    if not defaults.get("ou_allowlist"):
        problems.append(
            "ou_allowlist is not in defaults. Per-family only, and six of seven "
            "write families deny every shadow item on scope"
        )
    exempt = payload.get("exempt_operations", []) or []
    if "notify.operators" not in exempt:
        problems.append("notify.operators is not in exempt_operations")
    families = payload.get("families", {}) or {}
    for name, family in families.items():
        if "notify" in name and family.get("levels") and name != "F2b-free-notify":
            problems.append("%s is a ladder family with levels; it must be outside" % name)
        for trigger, level in (family.get("levels", {}) or {}).items():
            if name == "F1-observe":
                continue
            if str(level) not in ("L0", "L1"):
                problems.append("%s/%s is %s, above L1" % (name, trigger, level))
        if name != "F1-observe" and not (
            family.get("ou_allowlist") or defaults.get("ou_allowlist")
        ):
            problems.append("%s has no ou_allowlist" % name)
    # SETUP.md Phase 14's verify table has nine rows; these four were not
    # asserted anywhere.
    version = str(payload.get("config_version", ""))
    if not re.match(r"^2026\.09\.0-[12]$", version):
        problems.append(
            "config_version is %r, expected 2026.09.0-1 (pre-Phase 18) or "
            "2026.09.0-2 (after)" % version
        )
    if not payload.get("ceilings_sha"):
        problems.append(
            "ceilings_sha is absent; the running service must stamp the ceiling "
            "hash it is actually enforcing (A17)"
        )
    halt = payload.get("halt")
    if halt not in (None, "", "clear", False):
        problems.append("halt is %r, not clear" % halt)
    f4b = families.get("F4b-ou-move", {}) or {}
    scope = set(f4b.get("ou_allowlist") or defaults.get("ou_allowlist") or [])
    destination = set(f4b.get("ou_destination_allowlist") or [])
    if destination and not destination <= scope:
        problems.append(
            "F4b ou_destination_allowlist %s is not a subset of its ou_allowlist %s "
            "(the CI assertion 03-lld.md depends on, and the reason ou_allowlist "
            "lives in defaults at all)" % (sorted(destination), sorted(scope))
        )
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, (
        "stage 0, budget 0, all write families L1 or below, ou_allowlist inherited, "
        "config_version %s, ceilings stamped, halt clear" % version
    )


def check_project_roles(ctx: Ctx) -> CheckResult:
    policy = gcloud_probe_json(ctx, "projects", "get-iam-policy", ctx.need("PROJECT"))
    if policy is None:
        return SKIP, "project does not exist yet"
    problems = []
    actions = set(_roles_of_member(policy, "serviceAccount:" + ctx.need("SA_ACTIONS")))
    if not set(ACTIONS_PROJECT_ROLES) <= actions:
        problems.append("walle-actions@ is missing %s" % sorted(set(ACTIONS_PROJECT_ROLES) - actions))
    super_roles = set(_roles_of_member(policy, "serviceAccount:" + ctx.need("SA_ACTIONS_SUPER")))
    if not set(SUPER_PROJECT_ROLES) <= super_roles:
        problems.append("walle-actions-super@ is missing %s"
                        % sorted(set(SUPER_PROJECT_ROLES) - super_roles))
    if "roles/cloudtasks.enqueuer" in super_roles:
        problems.append("walle-actions-super@ holds cloudtasks.enqueuer; band B has no queue")
    dispatch = set(_roles_of_member(policy, "serviceAccount:" + ctx.need("SA_DISPATCH")))
    if not set(DISPATCH_PROJECT_ROLES) <= dispatch:
        problems.append("walle-dispatcher@ is missing %s" % sorted(set(DISPATCH_PROJECT_ROLES) - dispatch))
    agent = _roles_of_member(policy, "serviceAccount:" + ctx.need("SA_AGENT"))
    if agent:
        problems.append("walle-agent@ holds project roles and must hold none: %s" % agent)
    # project-topology.md row 26, the rule of the page, inverted from the old
    # "eve-controller@ has datastore.viewer": NO identity from EVE_PROJECT or
    # MO_PROJECT holds ANY project-level role in Wall-E's project. Every
    # legitimate cross-project reach is a grant on a resource (a dataset, a
    # service, the engine), checked elsewhere. EVE_PROJECT_ROLES stays empty
    # until decision 44 names a resource-scoped form.
    for key in FOREIGN_IDENTITY_KEYS:
        email = ctx.get(key)
        if not email:
            continue
        held = _roles_of_member(policy, "serviceAccount:" + email)
        if held:
            problems.append(
                "%s (a foreign identity) holds project-level %s in Wall-E's project; "
                "the topology allows resource-level grants only (row 26)" % (email, held)
            )
    # Any principal from the two agent projects, whatever its name.
    for member in {m for b in policy.get("bindings", []) for m in b.get("members", [])}:
        for foreign_project in (ctx.get("EVE_PROJECT"), ctx.get("MO_PROJECT")):
            if foreign_project and member.endswith("@%s.iam.gserviceaccount.com" % foreign_project):
                if member.split(":", 1)[-1] not in {ctx.get(k) for k in FOREIGN_IDENTITY_KEYS}:
                    problems.append("%s from %s holds a project-level role in Wall-E's "
                                    "project" % (member, foreign_project))
    # The old placement, by name: an eve-* or mo-* account created IN Wall-E's
    # project is the pre-2026-09-13 state and must not exist.
    listed = gcloud_probe_json(ctx, "iam", "service-accounts", "list") or []
    present = {a.get("email"): bool(a.get("disabled", False)) for a in listed}
    misplaced = sorted(
        e for e in present
        if e and (e.startswith("eve-") or e.startswith("mo-"))
        and e.endswith("@%s.iam.gserviceaccount.com" % ctx.need("PROJECT"))
    )
    if misplaced:
        problems.append("Eve or Mo identities exist IN Wall-E's project: %s; they belong in "
                        "EVE_PROJECT / MO_PROJECT" % misplaced)
    # SETUP.md Phase 6's verify asks for both halves: the roles, and that all
    # four accounts exist and are enabled. A disabled service account produces
    # a failure that looks nothing like a missing role.
    for name in SERVICE_ACCOUNT_IDS:
        email = "%s@%s.iam.gserviceaccount.com" % (name, ctx.need("PROJECT"))
        if email not in present:
            problems.append("service account %s is missing" % email)
        elif present[email]:
            problems.append("service account %s is DISABLED" % email)
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, (
        "all %d service accounts exist and are enabled; actions and dispatcher have "
        "their roles; agent holds nothing; no Eve or Mo identity holds a project-level "
        "role here" % len(SERVICE_ACCOUNT_IDS)
    )


def check_run_invoker_handles(ctx: Ctx) -> CheckResult:
    problems = []
    actions_policy = gcloud_probe_json(
        ctx, "run", "services", "get-iam-policy", "walle-actions", "--region", ctx.need("REGION")
    )
    if actions_policy is None:
        return SKIP, "walle-actions is not deployed yet"
    invokers = set(_members_with_role(actions_policy, "roles/run.invoker"))
    for required in (
        "group:" + ctx.need("OPERATORS"),
        "serviceAccount:" + ctx.need("SA_OPS_CALLER"),
        "serviceAccount:" + ctx.need("SA_AGENT"),
        "serviceAccount:" + ctx.need("SA_ACTIONS"),
    ):
        if required not in invokers:
            problems.append("walle-actions is missing run.invoker for %s" % required)
    # The old placement: an Eve or Mo account spelled in Wall-E's project
    # holding the invoker. Not a typo — the pre-2026-09-13 topology, deployed.
    misplaced = sorted(
        m for m in invokers
        if m.split(":", 1)[-1].startswith(("eve-", "mo-"))
        and m.endswith("@%s.iam.gserviceaccount.com" % ctx.need("PROJECT"))
    )
    if misplaced:
        problems.append("run.invoker on walle-actions names Eve or Mo identities IN Wall-E's "
                        "project: %s (they live in EVE_PROJECT / MO_PROJECT)" % misplaced)
    # The cross-project invokers the design requires (project-topology.md rows
    # 3 and 8). Their principals exist only once Eve's runbook Phase 8 and
    # Mo-6 have run, so a missing one is "not yet bound", reported as SKIP,
    # never silently passed; --strict turns it into a failure.
    pending = []
    for label, member in (
        ("eve-controller@EVE_PROJECT", "serviceAccount:" + ctx.need("SA_EVE")),
        ("eve-verifier@EVE_PROJECT", "serviceAccount:" + ctx.need("SA_EVE_VERIFIER")),
        ("eve-console@EVE_PROJECT", "serviceAccount:" + ctx.need("SA_EVE_CONSOLE")),
        ("mo-analyst@MO_PROJECT", iam_member(ctx.need("MO_PRINCIPAL"))),
    ):
        if member not in invokers:
            pending.append(label)
    dispatcher_policy = gcloud_probe_json(
        ctx, "run", "services", "get-iam-policy", "walle-dispatcher",
        "--region", ctx.need("REGION"),
    )
    if dispatcher_policy is not None:
        d_invokers = set(_members_with_role(dispatcher_policy, "roles/run.invoker"))
        if "serviceAccount:" + ctx.need("SA_DISPATCH") not in d_invokers:
            problems.append(
                "walle-dispatcher is missing run.invoker for itself; every trigger 403s"
            )
    if problems:
        return FAIL, "; ".join(problems)
    if pending:
        return SKIP, (
            "Wall-E's own invokers hold; cross-project invokers not yet bound on "
            "walle-actions: %s. Re-run 'walle deploy' once Eve's runbook Phase 8 / Mo-6 "
            "has created them." % ", ".join(pending)
        )
    return PASS, ("the andon cord has a handle; Eve's three and mo-analyst@ hold run.invoker "
                  "cross-project; triggers can reach the dispatcher")


def check_residency(ctx: Ctx) -> CheckResult:
    problems = []
    # Every branch below is guarded on the resource existing, so on an empty
    # project this used to return PASS: residency, the property the whole
    # europe-west1 pin exists for, reporting green with nothing to be in region.
    checked = 0
    firestore = gcloud_probe_json(
        ctx, "firestore", "databases", "describe", "--database", "(default)")
    if firestore:
        checked += 1
        if firestore.get("locationId") != ctx.need("REGION"):
            problems.append("Firestore is in %s" % firestore.get("locationId"))
    for dataset in (ctx.get("AUDIT_DATASET"), ctx.get("LOGS_DATASET")):
        shown = probe(ctx, ["bq", "show", "--format=prettyjson",
                            "%s:%s" % (ctx.need("PROJECT"), dataset)])
        if shown.ok:
            checked += 1
            location = json.loads(shown.out).get("location")
            if location != ctx.need("BQ_LOCATION"):
                problems.append("dataset %s is in %s" % (dataset, location))
    bucket = gcloud_probe_json(ctx, "storage", "buckets", "describe", ctx.need("STAGING_BUCKET"))
    if bucket:
        checked += 1
        if str(bucket.get("location", "")).upper() != ctx.need("REGION").upper():
            problems.append("staging bucket is in %s" % bucket.get("location"))
    for service in ("walle-actions", SUPER_SERVICE, "walle-dispatcher"):
        described = gcloud_probe_json(
            ctx, "run", "services", "describe", service, "--region", ctx.need("REGION"))
        if described is None:
            continue
        checked += 1
        annotations = described.get("metadata", {}).get("annotations", {})
        ingress = annotations.get("run.googleapis.com/ingress")
        if ingress and ingress != "all":
            problems.append(
                "%s ingress is %s. Agent Runtime egresses from a Google-managed "
                "tenant project, which Cloud Run treats as external, so internal "
                "ingress blocks the agent entirely and the symptom is a timeout "
                "with no log line" % (service, ingress)
            )
        timeout = described.get("spec", {}).get("template", {}).get("spec", {}).get(
            "timeoutSeconds")
        if service in ("walle-actions", SUPER_SERVICE) and timeout not in (60, "60"):
            problems.append("%s timeout is %s, not 60s" % (service, timeout))
    if not checked:
        return SKIP, "nothing exists yet to be in region"
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "%d resources checked, all in region" % checked


def check_audit_tables(ctx: Ctx) -> CheckResult:
    problems = []
    for table in AUDIT_TABLES:
        target = "%s:%s.%s" % (ctx.need("PROJECT"), ctx.get("AUDIT_DATASET"), table)
        shown = probe(ctx, ["bq", "show", "--format=prettyjson", target])
        if not shown.ok:
            problems.append("%s missing" % table)
            continue
        payload = json.loads(shown.out)
        partitioning = payload.get("timePartitioning") or {}
        if partitioning.get("field") != "ts" or partitioning.get("type") != "DAY":
            problems.append("%s is not DAY-partitioned on ts" % table)
        expiry = partitioning.get("expirationMs")
        if str(expiry) != str(PARTITION_EXPIRATION_SECONDS * 1000):
            problems.append("%s expiry is %s ms" % (table, expiry))
        # Clustering is what makes the hourly 30-day rolling metric evaluation
        # affordable (SETUP.md Phase 7). Only `actions` carries an `operation`
        # column, so only `actions` is clustered on it.
        clustering = (payload.get("clustering") or {}).get("fields", []) or []
        if table == "actions" and "operation" not in clustering:
            problems.append("actions is not clustered on operation (%s)" % clustering)
        if table in ("runs", "plans") and clustering and "run_id" not in clustering:
            problems.append("%s is clustered on %s, not run_id" % (table, clustering))
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "6 tables, DAY-partitioned on ts, 400 day expiry, clustered as designed"


def check_eve_separation(ctx: Ctx) -> CheckResult:
    """If they shared a key, "Eve approved" and "Eve verified" would both mean
    nothing."""
    problems = []
    # The Wall-E half is testable from the moment Phase 8 has run, long before
    # Eve exists, and it is the half that matters most while Eve is still
    # hypothetical: if an Eve identity could read walle-refresh-token, Eve's
    # independence is gone before she is built. Every Eve identity, not only
    # the controller: the secrets are Wall-E's, the principals are foreign.
    eve_members = {
        "serviceAccount:" + ctx.get(k) for k in ("SA_EVE_V0", "SA_EVE", "SA_EVE_VERIFIER",
                                                 "SA_EVE_CONSOLE") if ctx.get(k)
    }
    for secret in WALLE_SECRETS:
        if not secret_exists(ctx, secret):
            continue
        policy = gcloud_probe_json(
            ctx, "secrets", "get-iam-policy", secret, "--location", ctx.need("REGION")) or {}
        for member in sorted(eve_members):
            if _roles_of_member(policy, member):
                problems.append("%s can read %s" % (member, secret))
        for binding in policy.get("bindings", []):
            for member in binding.get("members", []):
                if member.endswith("@%s.iam.gserviceaccount.com" % ctx.need("EVE_PROJECT")) \
                        and member not in eve_members:
                    problems.append("%s (EVE_PROJECT) can read %s" % (member, secret))
    # The Eve half lives in EVE_PROJECT and is read THERE. Reading Eve's
    # project through the default project would answer "does not exist" for
    # secrets that exist in Eve's, and the check would silently narrow to half.
    eve_side, eve_detail = _eve_side_policies(ctx)
    eve_secret_labels = [l for l in eve_side if l.startswith("secret ")]
    for label in eve_secret_labels:
        if _roles_of_member(eve_side[label], "serviceAccount:" + ctx.need("SA_ACTIONS")):
            problems.append("walle-actions@ can read Eve's %s in EVE_PROJECT" % label)
        for binding in eve_side[label].get("bindings", []):
            for member in binding.get("members", []):
                if member.endswith("@%s.iam.gserviceaccount.com" % ctx.need("PROJECT")):
                    problems.append("%s (a Wall-E principal) can read Eve's %s" % (member, label))
    if problems:
        return FAIL, "; ".join(problems)
    if not eve_secret_labels:
        return SKIP, (
            "the Wall-E half passes: no Eve identity can read any of Wall-E's secrets. "
            "Eve's secrets %s" % eve_detail
        )
    return PASS, "no Eve identity reads a Wall-E secret; no Wall-E principal reads an Eve secret"


def check_protected_covers_floor(ctx: Ctx) -> CheckResult:
    path = os.path.expanduser(ctx.get("FLOOR_LIST_PATH"))
    if not os.path.isfile(path):
        return FAIL, "the committed floor list does not exist at %s" % path
    with open(path, "r", encoding="utf-8") as handle:
        floor = {
            line.strip().lower() for line in handle
            if line.strip() and not line.startswith("#")
        }
    members = admin(ctx).members()
    request = members.list(
        groupKey=ctx.need("PROTECTED"), includeDerivedMembership=True, maxResults=200
    )
    have = {
        m.get("email", "").lower() for m in paginate(ctx, members, request, "members")
    }
    # includeDerivedMembership flattens nested groups to their users, so a GROUP
    # address in the floor list (collect_admins records one when a role is
    # assigned to a group) never appears in that listing and the check fails for
    # the wrong reason. Read the direct membership too.
    direct_request = members.list(groupKey=ctx.need("PROTECTED"), maxResults=200)
    have |= {
        m.get("email", "").lower()
        for m in paginate(ctx, members, direct_request, "members")
    }
    missing = sorted(floor - have)
    if missing:
        return FAIL, "%s does not cover the floor list: %s" % (ctx.need("PROTECTED"), missing)
    return PASS, "%d floor addresses, all covered transitively" % len(floor)


def _super_admin_addresses(ctx: Ctx) -> List[str]:
    """Every super admin, from users.list isAdmin=true, fully paginated."""
    users = admin(ctx).users()
    request = users.list(customer=ctx.need("CUSTOMER_ID"), query="isAdmin=true",
                         maxResults=200, projection="basic")
    return sorted(u["primaryEmail"].lower() for u in paginate(ctx, users, request, "users"))


def _roster_problems(ctx: Ctx, granted: bool) -> Tuple[List[str], List[str]]:
    """The roster rule (platform 04 §8.1, P68), read live as the operator.

    Returns (problems, notes). Eve's daily roster check from her own credential
    is the detective control; this is the build-time assertion of the same rule.
    """
    problems: List[str] = []
    notes: List[str] = []
    robot = ctx.need("ROBOT").lower()
    eve = ctx.get("EVE_ROBOT", "").lower()
    supers = _super_admin_addresses(ctx)
    humans = [a for a in supers if a not in (robot, eve)]
    if eve and eve in supers:
        problems.append("%s (Eve's robot) is a super admin; Eve never holds super admin "
                        "(platform HLD §4.6)" % eve)
    if granted:
        if robot not in supers:
            problems.append("the robot is not a super admin although the grant record is "
                            "on file (role_assignment_missing)")
        if len(humans) < 2:
            problems.append(
                "%d human super admin(s) besides the robot; at least two are required, so "
                "the robot is never the only super admin and never the only one who can "
                "recover another (platform HLD §13.1 item 6)" % len(humans))
    else:
        if robot in supers:
            problems.append("the robot is a super admin and SUPER_ADMIN_GRANT_DECISION names "
                            "no signed record: the tier gate (platform HLD §0.4) was skipped")
        if len(humans) < 2:
            notes.append("%d human super admin(s): two are a precondition of the grant"
                         % len(humans))
    # "Never the recovery super admin": no super admin's recovery email is the
    # robot's address (Directory API users.get, projection full).
    for address in humans:
        record = api_get(ctx, "users.get %s" % address,
                         admin(ctx).users().get(userKey=address, projection="full"))
        if record and str(record.get("recoveryEmail", "")).lower() == robot:
            problems.append("the robot is the recovery email of super admin %s" % address)
        # Added 2026-09-13: the two humans count only if hardened (platform HLD
        # §13.1 item 6, "separate admin accounts with hardware keys"). The
        # Directory API exposes 2SV enrolment and enforcement, not the key type;
        # the hardware-key half stays the console check of Phase 2 G3.
        if record and not (record.get("isEnrolledIn2Sv") and record.get("isEnforcedIn2Sv")):
            message = ("human super admin %s is not enrolled in and enforced for 2-step "
                       "verification (isEnrolledIn2Sv=%s, isEnforcedIn2Sv=%s)" % (
                           address, record.get("isEnrolledIn2Sv"), record.get("isEnforcedIn2Sv")))
            (problems if granted else notes).append(message)
    roster = sorted(a.strip().lower() for a in ctx.get("SUPER_ADMIN_ROSTER", "").split(",")
                    if a.strip())
    if roster:
        added = sorted(set(supers) - set(roster))
        missing = sorted(set(roster) - set(supers))
        if added:
            problems.append("super admins NOT on the committed roster: %s (role_assignment_added)"
                            % added)
        if missing:
            problems.append("roster entries that are not super admins: %s "
                            "(role_assignment_missing)" % missing)
        if granted and robot not in roster:
            problems.append("SUPER_ADMIN_ROSTER does not list the robot although it is granted")
    elif granted:
        problems.append("SUPER_ADMIN_ROSTER is empty: after the grant the committed roster "
                        "must list exactly the super admins (P68)")
    else:
        notes.append("no committed roster yet (SUPER_ADMIN_ROSTER)")
    return problems, notes


def check_robot_hardening(ctx: Ctx) -> CheckResult:
    """INVERTED 2026-09-13 (platform HLD §13.1 item 10, §18 item 5).

    Was: FAIL if the robot isAdmin ("the difference between a contained
    incident and a breach"). The objective makes the robot a super admin, so
    the check now asserts, from the operator's credential:
      - the super-admin state matches the tier gate: a super admin once the
        signed P33 record is on file, not one before;
      - the account hygiene set: no recovery email or phone, 2SV enrolled and
        enforced, in the robot OU;
      - the roster rule: at least two human super admins, Eve's robot never
        one, the robot never the recovery email of a super admin, and the
        live roster equal to the committed SUPER_ADMIN_ROSTER in both
        directions.
    Not readable with this script's scopes and asserted by the platform drift
    job's Policy API read instead (platform 04 §8.2, §8.4): super-admin
    self-recovery Off at the top OU, multi-party approval on, session control.
    """
    robot = api_get(ctx, "users.get robot", admin(ctx).users().get(
        userKey=ctx.need("ROBOT"), projection="full"))
    if not robot:
        return FAIL, "robot account does not exist"
    granted = super_admin_grant_on_file(ctx)
    problems = []
    if granted and not robot.get("isAdmin"):
        problems.append("the grant record is on file and the robot is NOT a super admin")
    if not granted and robot.get("isAdmin"):
        problems.append("the robot is a SUPER ADMIN with no signed grant record on file "
                        "(SUPER_ADMIN_GRANT_DECISION): the tier gate was skipped")
    if robot.get("recoveryEmail"):
        problems.append("a recovery email is set")
    if robot.get("recoveryPhone"):
        problems.append("a recovery phone is set")
    if not robot.get("isEnforcedIn2Sv"):
        problems.append("2-step verification is not ENFORCED on this account")
    if not robot.get("isEnrolledIn2Sv"):
        problems.append("no 2SV method is enrolled")
    if robot.get("orgUnitPath") != ctx.need("SVC_OU"):
        problems.append("the robot is in %s, not %s" % (robot.get("orgUnitPath"), ctx.need("SVC_OU")))
    roster_problems, notes = _roster_problems(ctx, granted)
    problems.extend(roster_problems)
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "%s; no recovery contacts, 2SV enrolled and enforced; roster rule holds%s" % (
        "super admin per the grant record" if granted else "not a super admin (gate not passed)",
        " (%s)" % "; ".join(notes) if notes else "")


def verify_super_admin_grant(ctx: Ctx) -> CheckResult:
    """M2C's verifier: the human grant happened, and the roster still holds."""
    if not super_admin_grant_on_file(ctx):
        return FAIL, "SUPER_ADMIN_GRANT_DECISION names no signed record"
    robot = api_get(ctx, "users.get robot", admin(ctx).users().get(
        userKey=ctx.need("ROBOT"), projection="full"))
    if not robot or not robot.get("isAdmin"):
        return FAIL, "the robot is not a super admin yet"
    problems, _notes = _roster_problems(ctx, True)
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "the robot is a super admin and the roster rule holds"


def check_sandbox(ctx: Ctx) -> CheckResult:
    users = admin(ctx).users()
    request = users.list(
        customer=ctx.need("CUSTOMER_ID"), query="orgUnitPath='%s'" % ctx.need("SANDBOX_OU"),
        maxResults=200,
    )
    found = paginate(ctx, users, request, "users")
    if len(found) < 3:
        return FAIL, "%s holds %d accounts; at least three synthetic accounts are required" % (
            ctx.need("SANDBOX_OU"), len(found))
    return PASS, "%d synthetic accounts in %s" % (len(found), ctx.need("SANDBOX_OU"))


def check_single_engine(ctx: Ctx) -> CheckResult:
    engines = list_engines(ctx)
    if not engines:
        return SKIP, "no reasoning engine deployed yet"
    if len(engines) != 1:
        return FAIL, (
            "%d reasoning engines exist. create is not idempotent and the IAM "
            "lockdown was applied to one id only: %s"
            % (len(engines), ", ".join(str(e.get("name")) for e in engines))
        )
    return PASS, "exactly one engine: %s" % engines[0].get("name")


def check_budget(ctx: Ctx) -> CheckResult:
    budgets = gcloud_probe_json(
        ctx, "billing", "budgets", "list", "--billing-account", ctx.need("BILLING"))
    if budgets is None:
        return SKIP, "cannot list budgets on %s" % ctx.need("BILLING")
    for budget in budgets:
        if budget.get("displayName") == "walle-stage-0":
            projects = budget.get("budgetFilter", {}).get("projects", [])
            if "projects/%s" % ctx.need("PROJECT") not in projects:
                return FAIL, "budget is scoped to %s, not this project" % projects
            return PASS, "walle-stage-0 scoped to this project"
    return FAIL, "no walle-stage-0 budget exists"


def robot_credential_fields(ctx: Ctx, band_b: bool = False) -> Dict[str, Any]:
    """The client id, secret, token URI and PINNED refresh token of one client.

    In memory only; never printed. Reads the pinned version, never 'latest'.
    """
    pin_key = "SUPER_REFRESH_TOKEN_VERSION" if band_b else "REFRESH_TOKEN_VERSION"
    client_secret, token_secret = SUPER_CLIENT_SECRETS if band_b else NARROW_CLIENT_SECRETS
    version = ctx.get(pin_key)
    if not version:
        env = (deployed_service_env(ctx, SUPER_SERVICE) if band_b
               else deployed_actions_env(ctx)) or {}
        version = env.get("REFRESH_TOKEN_VERSION", "")
    if not version.isdigit():
        die("%s is not a version number: %r" % (pin_key, version))
    client = json.loads(read_secret(ctx, client_secret).decode("utf-8"))
    block = client.get("installed") or client.get("web") or {}
    token = read_secret(ctx, token_secret, version).decode("utf-8").strip()
    return {
        "refresh_token": token,
        "client_id": block.get("client_id"),
        "client_secret": block.get("client_secret"),
        "token_uri": block.get("token_uri", "https://oauth2.googleapis.com/token"),
    }


def robot_credentials(ctx: Ctx, band_b: bool = False) -> Any:
    """Build one of the robot's two credentials from Secret Manager, in memory only.

    Reads the PINNED version, never 'latest', for the same reason the service
    does: latest resolves to the newest enabled version, so disabling the newest
    falls back to the previous, still-valid token. band_b selects client 2.

    NOT for proving what Google granted: google-auth sends `scopes` as the
    `scope` parameter of the refresh, so the access token comes back narrowed
    to exactly this list. check_robot_credentials_scoped uses
    refresh_unnarrowed() instead (corrected 2026-09-13).
    """
    _Request, Credentials, _Flow, _build = _import_google()
    fields = robot_credential_fields(ctx, band_b)
    scopes = parse_scope_list(ctx.get("SUPER_SCOPES")) if band_b else list(ROBOT_SCOPES)
    return Credentials(token=None, scopes=scopes, **fields)


def refresh_unnarrowed(request: Any, fields: Dict[str, Any]) -> Tuple[str, List[str]]:
    """Refresh WITHOUT a scope parameter and return (access_token, granted scopes).

    Google's refresh request takes client_id, client_secret, grant_type and
    refresh_token, and its response carries `scope`, "the scopes of access
    granted by the access_token" (developers.google.com/identity/protocols/
    oauth2/native-app, read 2026-09-13). With no scope parameter nothing narrows
    the answer, so an extra or cloud-platform scope on the consent is visible.
    Neither the token nor the response body is ever printed or logged.
    """
    body = urllib.parse.urlencode({
        "client_id": fields.get("client_id") or "",
        "client_secret": fields.get("client_secret") or "",
        "grant_type": "refresh_token",
        "refresh_token": fields.get("refresh_token") or "",
    }).encode("utf-8")
    response = request(url=fields["token_uri"], method="POST", body=body,
                       headers={"Content-Type": "application/x-www-form-urlencoded"})
    if getattr(response, "status", None) != 200:
        raise WalleError("the refresh was refused (HTTP %s)" % getattr(response, "status", "?"))
    data = response.data
    data = json.loads(data.decode("utf-8") if isinstance(data, bytes) else data)
    token = data.get("access_token") or ""
    if not token:
        raise WalleError("the refresh returned no access token")
    return token, str(data.get("scope") or "").split()


def check_robot_credentials_scoped(ctx: Ctx) -> CheckResult:
    """Rewritten 2026-09-13. Was robot_credential_is_read_only.

    The old check proved a users.update as the robot was REFUSED at Google's
    end, because the Stage 0 role was read-only. Against a super admin that
    write SUCCEEDS, so the probe would be an unaudited robot write and a
    reconciliation gap, and "Google refuses" is no longer a property of the
    design. What still holds at Google's end is the scope set, so for each
    stored client this asserts: the credential belongs to the robot (SETUP.md
    7.1), and the scopes Google granted equal the reviewed list exactly and
    carry no cloud-platform in any form (platform HLD §13.1 item 3).

    Refreshing a token and calling userinfo are robot-attributed token events,
    not admin writes. Run verify inside a change window the operators know of.
    """
    if ctx.dry_run:
        return SKIP, "--dry-run: refreshing the robot's tokens is a robot-attributed token event"
    _Request, Credentials, _Flow, build = _import_google()
    Request = _Request
    checked: List[str] = []
    problems: List[str] = []
    for band_b, label in ((False, "client 1 (narrow)"), (True, "client 2 (broad)")):
        token_secret = (SUPER_CLIENT_SECRETS if band_b else NARROW_CLIENT_SECRETS)[1]
        if not secret_exists(ctx, token_secret):
            continue
        versions = gcloud_probe_json(ctx, "secrets", "versions", "list", token_secret,
                                     "--location", ctx.need("REGION"),
                                     "--filter", "state=ENABLED") or []
        if not versions:
            continue
        expected = set(parse_scope_list(ctx.get("SUPER_SCOPES")) if band_b else ROBOT_SCOPES)
        if band_b and not expected:
            # Refuse before touching the token: with no reviewed list there is
            # nothing to compare Google's answer with.
            problems.append("%s is stored but SUPER_SCOPES is empty: the reviewed broad "
                            "list is unknown, so its scope set cannot be asserted" % label)
            continue
        fields = robot_credential_fields(ctx, band_b)
        try:
            # Corrected 2026-09-13: refresh WITHOUT narrowing. The old code built
            # Credentials(scopes=expected), which google-auth sends as `scope`,
            # so Google's answer could never hold a scope outside the list.
            access_token, granted = refresh_unnarrowed(Request(), fields)
        except Exception as exc:
            problems.append("%s cannot refresh: %s" % (label, type(exc).__name__))
            continue
        creds = Credentials(token=access_token)
        email = fetch_consented_email(ctx, creds, build)
        if email.lower() != ctx.need("ROBOT").lower():
            problems.append("%s belongs to %s, not %s; destroy that version and re-run the "
                            "consent (SETUP.md 7.1)" % (label, email, ctx.need("ROBOT")))
        if not granted:
            problems.append("%s: Google's refresh response carried no scope field; its "
                            "breadth is unknown" % label)
            continue
        bad = forbidden_scopes(granted)
        if bad:
            problems.append("%s carries %s" % (label, ", ".join(bad)))
        if set(granted) != expected:
            problems.append("%s granted scopes differ from the reviewed list: extra %s, "
                            "missing %s" % (label, sorted(set(granted) - expected),
                                            sorted(expected - set(granted))))
        checked.append(label)
    if problems:
        return FAIL, "; ".join(problems)
    if not checked:
        return SKIP, "no stored refresh token yet (phase 9)"
    return PASS, "%s: the robot's, exact scope set, no cloud-platform" % ", ".join(checked)


def verify_operator_client_file(ctx: Ctx) -> CheckResult:
    path = os.path.expanduser(ctx.get("OPERATOR_OAUTH_CLIENT_FILE"))
    if not os.path.isfile(path):
        return FAIL, "%s does not exist" % path
    try:
        with open(path, "r", encoding="utf-8") as handle:
            payload = json.load(handle)
    except ValueError as exc:
        return FAIL, "%s is not valid JSON: %s" % (path, exc)
    if not ({"installed", "web"} & set(payload)):
        return FAIL, "%s is not an OAuth client file" % path
    return PASS, "operator OAuth client present at %s" % path


def verify_no_recovery_contacts(ctx: Ctx) -> CheckResult:
    problems = []
    for key in ("ROBOT", "EVE_ROBOT"):
        email = ctx.get(key)
        if not email:
            continue
        record = api_get(ctx, "users.get %s" % email,
                         admin(ctx).users().get(userKey=email, projection="full"))
        if not record:
            problems.append("%s does not exist" % email)
            continue
        if record.get("recoveryEmail") or record.get("recoveryPhone"):
            problems.append("%s still has a recovery contact" % email)
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "no recovery email or phone on either robot account"


def verify_2sv_enrolled(ctx: Ctx) -> CheckResult:
    """The gate between registering keys (M2A) and enforcing them (M2B).

    Enforcing hardware-key-only on an account with no key enrolled locks it out
    permanently, and by then the recovery email, the recovery phone and the
    code fallbacks are all gone: the recovery path is a full Phase 9
    re-bootstrap (SETUP.md Phase 3). verify_2sv_enforced can only confirm the
    damage; this runs before it is possible.
    """
    problems = []
    for key in ("ROBOT", "EVE_ROBOT"):
        email = ctx.get(key)
        if not email:
            continue
        record = api_get(ctx, "users.get %s" % email,
                         admin(ctx).users().get(userKey=email, projection="full"))
        if not record:
            problems.append("%s does not exist" % email)
        elif not record.get("isEnrolledIn2Sv"):
            problems.append(
                "%s has NO 2SV method enrolled. DO NOT ENFORCE: it would lock the "
                "account out permanently." % email
            )
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "both robots have a key enrolled; enforcement is now safe"


def verify_2sv_enforced(ctx: Ctx) -> CheckResult:
    problems = []
    for key in ("ROBOT", "EVE_ROBOT"):
        email = ctx.get(key)
        if not email:
            continue
        record = api_get(ctx, "users.get %s" % email,
                         admin(ctx).users().get(userKey=email, projection="full"))
        if not record:
            problems.append("%s does not exist" % email)
            continue
        if not record.get("isEnrolledIn2Sv"):
            problems.append("%s has no 2SV method enrolled (register the key FIRST)" % email)
        if not record.get("isEnforcedIn2Sv"):
            problems.append("%s is not under 2SV enforcement" % email)
        # Rewritten 2026-09-13: kept for EVE_ROBOT, which is never a super admin.
        # For ROBOT the super-admin state is the tier gate's, asserted by
        # check_robot_hardening; M2B runs before the grant, so at this point the
        # robot must not be one yet either.
        if key == "EVE_ROBOT" and record.get("isAdmin"):
            problems.append("%s (Eve's robot) is a super admin" % email)
        if key == "ROBOT" and record.get("isAdmin") and not super_admin_grant_on_file(ctx):
            problems.append("%s is already a super admin before the tier gate (M2C)" % email)
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "both robots: 2SV enrolled and enforced; Eve's robot is not a super admin"


def verify_workspace_log_sharing(ctx: Ctx) -> CheckResult:
    """Ask Google's own log, at organisation scope. Empty after 24h means off."""
    results = {}
    for service in ("admin.googleapis.com", "login.googleapis.com"):
        result = probe(
            ctx,
            [
                "gcloud", "logging", "read",
                'protoPayload.serviceName="%s"' % service,
                "--organization", ctx.need("ORG_ID"),
                "--freshness", "24h", "--limit", "1", "--format", "value(timestamp)",
            ],
        )
        results[service] = bool(result.ok and result.out.strip())
    missing = [name for name, present in results.items() if not present]
    # Neither log type visible is most often "enabled less than 24 hours ago",
    # which is the normal state the moment the operator flips the toggle. FAIL
    # there made do_manual_step die and left the operator waiting a day to
    # restart the phase. One visible and one missing is a real asymmetry.
    if missing and not any(results.values()):
        return SKIP, (
            "no rows at organisation scope for either log type. Sharing may have "
            "been enabled less than 24h ago; re-run `walle verify` tomorrow. If it "
            "is still empty then, sharing is off."
        )
    if missing:
        return FAIL, (
            "%s is not shared at organisation scope while the other is. The Phase 4 "
            "fallback has no data source. Resolve that before Phase 9."
            % ", ".join(missing)
        )
    return PASS, "admin and login audit events are both visible at organisation scope"


def _assert_no_robot_admin_events(ctx: Ctx, freshness: str = "24h") -> CheckResult:
    """Ask Google, not Wall-E, whether a write happened.

    The single most load-bearing verification in the runbook, and it appears
    three times: Phase 12 verify check 4 ("it asks Google, not Wall-E, whether
    a write happened"), Phase 14's forced shadow run, and the Stage 0 checklist
    ("zero rows attributed to $ROBOT, apart from the single event deliberately
    generated in Phase 17"). Every other write check here asks Wall-E's own
    configuration.

    No methodName filter, deliberately: the Workspace admin audit log records
    CHANGES only and never reads, so ANY row attributed to the robot is a write.

    Qualified 2026-09-13: this stays the Stage 0 assertion. Once Super Admin
    is granted and band B is live, legitimate robot writes exist, and the
    control that matters is Eve's minute-latency reconciliation of every
    robot-attributed event against walle_audit and the band-B audit rows
    (platform HLD §13.1 item 5), not a count of zero here.
    """
    result = probe(ctx, [
        "gcloud", "logging", "read",
        'protoPayload.serviceName="admin.googleapis.com" AND '
        'protoPayload.authenticationInfo.principalEmail="%s"' % ctx.need("ROBOT"),
        "--organization", ctx.need("ORG_ID"), "--freshness", freshness,
        "--limit", "10", "--format", "value(protoPayload.methodName)",
    ])
    if not result.ok:
        return SKIP, "cannot read the organisation log: %s" % result.err.strip()[:120]
    rows = [line for line in result.out.strip().splitlines() if line.strip()]
    if rows:
        return FAIL, (
            "%d admin-audit row(s) attributed to the robot in the last %s: %s. That "
            "log records changes only, so each one is a WRITE. Only the single event "
            "deliberately generated in Phase 17 is allowed."
            % (len(rows), freshness, ", ".join(rows[:5]))
        )
    return PASS, "no admin-audit rows attributed to the robot in the last %s" % freshness


def check_no_robot_writes(ctx: Ctx) -> CheckResult:
    return _assert_no_robot_admin_events(ctx, "24h")


def check_engine_properties(ctx: Ctx) -> CheckResult:
    """SETUP.md Phase 12 names four properties "this deployment must have".

    min_instances=1 bills around the clock; an admin agent must not accumulate
    long-term memories about employees; Code Execution has no EU at-rest
    residency. None of the three was set, printed as a contract, or checked.
    """
    engine_id = resolve_engine_id(ctx)
    if not engine_id:
        return SKIP, "no engine deployed yet"
    described = describe_engine(ctx, engine_id)
    if described is None:
        return SKIP, "engine %s is not readable" % engine_id
    spec = json.dumps(described)
    problems = []
    if '"minInstances": 1' in spec or '"min_instances": 1' in spec:
        problems.append("min_instances is 1; it bills around the clock")
    if "memoryBank" in spec and '"memoryBank": {}' not in spec:
        problems.append("Memory Bank appears to be configured")
    if "codeExecution" in spec:
        problems.append("Code Execution appears to be configured (no EU at-rest residency)")
    # Phase 12b: on the AGENT_IDENTITY path the engine runs as its own principal
    # and must carry NO service account; on the recorded fallback it is walle-agent@.
    mode = ctx.get("AGENT_IDENTITY_MODE") or "AGENT_IDENTITY"
    service_account = str((described.get("spec", {}) or {}).get("serviceAccount", "") or "")
    if mode == "SERVICE_ACCOUNT":
        if ctx.need("SA_AGENT") not in (service_account or spec):
            problems.append("the engine does not run as walle-agent@")
        identity_summary = "runs as walle-agent@ (SERVICE_ACCOUNT fallback)"
    else:
        if service_account:
            problems.append(
                "AGENT_IDENTITY_MODE is AGENT_IDENTITY but the engine carries "
                "serviceAccount %s; identity_type cannot be patched" % service_account
            )
        identity_summary = "runs as an agent identity, no service account"
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, (
        "%s, min_instances 0, no Memory Bank, no Code Execution" % identity_summary
    )


# --------------------------------------------------------------------------- #
# Phases 12b, 12c and 13b — the new invariants
# --------------------------------------------------------------------------- #


def deployed_engine_env(ctx: Ctx) -> Optional[Dict[str, str]]:
    """The engine's environment as deployed. None when there is no engine."""
    engine_id = resolve_engine_id(ctx)
    if not engine_id:
        return None
    described = describe_engine(ctx, engine_id)
    if described is None:
        return None
    spec = described.get("spec", {}) or {}
    entries = (spec.get("deploymentSpec", {}) or {}).get("env", []) or []
    return {
        str(entry.get("name")): str(entry.get("value", ""))
        for entry in entries
        if isinstance(entry, dict) and "name" in entry
    }


def check_agent_identity_effective(ctx: Ctx) -> CheckResult:
    """Phase 12b step 5: the identity is READ BACK, and the fallback is on file."""
    engine_id = resolve_engine_id(ctx)
    if not engine_id:
        return SKIP, "no engine deployed yet"
    effective = read_effective_identity(ctx, engine_id)
    if effective.startswith(AGENT_TRUST_DOMAIN_PREFIX):
        return PASS, "effectiveIdentity %s" % effective
    mode = ctx.get("AGENT_IDENTITY_MODE") or "AGENT_IDENTITY"
    spike_file = os.path.expanduser(ctx.get("AGENT_IDENTITY_SPIKE_RESULT") or "")
    if mode == "SERVICE_ACCOUNT" and spike_file and os.path.isfile(spike_file):
        return PASS, (
            "SERVICE_ACCOUNT fallback, spike recorded at %s (effectiveIdentity %r); "
            "Agent Identity is deferred hardening" % (spike_file, effective)
        )
    return FAIL, (
        "effectiveIdentity is %r, not an agent identity, and no recorded fallback "
        "(AGENT_IDENTITY_MODE=%s, AGENT_IDENTITY_SPIKE_RESULT=%r). identity_type "
        "cannot be patched: the engine must be recreated." % (effective, mode, spike_file)
    )


def check_engine_no_span_content(ctx: Ctx) -> CheckResult:
    """ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS defaults ON and would put tool
    arguments and responses, which carry employee data, into Cloud Trace."""
    env = deployed_engine_env(ctx)
    if env is None:
        return SKIP, "no engine deployed yet"
    value = env.get("ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS")
    if value is None:
        return FAIL, ("ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS is absent from the deployed "
                      "env; it defaults ON")
    if value.strip().lower() != "false":
        return FAIL, "ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS is %r, not false" % value
    return PASS, "ADK_CAPTURE_MESSAGE_CONTENT_IN_SPANS=false on the deployed engine"


def check_engine_no_token_sharing_optout(ctx: Ctx) -> CheckResult:
    env = deployed_engine_env(ctx)
    if env is None:
        return SKIP, "no engine deployed yet"
    if TOKEN_SHARING_OPTOUT in env:
        return FAIL, ("%s is set on the deployed engine; it unbinds tokens from the "
                      "runtime certificate" % TOKEN_SHARING_OPTOUT)
    return PASS, "%s absent from the deployed env" % TOKEN_SHARING_OPTOUT


def check_agentidentitycredentials_disabled(ctx: Ctx) -> CheckResult:
    enabled = gcloud_probe_json(ctx, "services", "list", "--enabled")
    if enabled is None:
        return SKIP, "cannot list enabled services"
    names = {item.get("config", {}).get("name") for item in enabled}
    if AGENT_IDENTITY_CREDENTIALS_API in names:
        return FAIL, ("%s is ENABLED; with it on, an auth provider can be exercised in "
                      "this project" % AGENT_IDENTITY_CREDENTIALS_API)
    return PASS, "%s is disabled" % AGENT_IDENTITY_CREDENTIALS_API


def check_extension_yaml_fail_closed(ctx: Ctx) -> CheckResult:
    """The committed YAML AND the live extension: failOpen false, or nothing."""
    path = os.path.join(os.path.expanduser(ctx.need("WALLE_REPO")), *ARMOR_CONFIG_SUBDIR,
                        "walle-ma-ext.yaml")
    if not os.path.isfile(path):
        return SKIP, "'walle armor' has not written %s yet" % path
    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()
    match = re.search(r"^\s*failOpen:\s*(\S+)", text, re.M)
    if not match:
        return FAIL, "%s carries no failOpen key; the default is fail-OPEN" % path
    if match.group(1).strip().strip("'\"").lower() != "false":
        return FAIL, "%s has failOpen %s; must be false" % (path, match.group(1))
    live = gcloud_probe_json(ctx, "service-extensions", "authz-extensions", "describe",
                             ARMOR_EXTENSION_NAME, "--location", ctx.need("REGION"))
    if live is not None and live.get("failOpen") is True:
        return FAIL, "the committed YAML says false but the LIVE extension is failOpen true"
    return PASS, "failOpen: false in %s%s" % (
        os.path.relpath(path, os.path.expanduser(ctx.need("WALLE_REPO"))),
        "" if live is None else ", and on the live extension")


def check_dispatcher_stream_query(ctx: Ctx) -> CheckResult:
    """Phase 12c step 6: every caller uses streamQuery. CI forbids the other two."""
    root = os.path.join(os.path.expanduser(ctx.need("WALLE_REPO")), "dispatcher")
    if not os.path.isdir(root):
        return SKIP, "no dispatcher source at %s" % root
    hits = grep_tree(root, (".query(", "async_query("), suffixes=(".py",))
    if hits:
        return FAIL, ("the dispatcher calls query or async_query, which the ingress "
                      "gateway does not screen: %s" % ", ".join(
                          os.path.relpath(h, root) for h in hits))
    return PASS, "no .query( or async_query( under dispatcher/"


def check_agent_no_dynamic_toolsets(ctx: Ctx) -> CheckResult:
    """No Skill Registry, no MCP, no remote A2A in the agent package (chapter 13)."""
    root = os.path.join(os.path.expanduser(ctx.need("WALLE_REPO")), "agent")
    if not os.path.isdir(root):
        return SKIP, "no agent package at %s" % root
    needles = ("skill_registry", "SkillToolset", "McpToolset", "RemoteA2aAgent")
    found = []
    for needle in needles:
        hits = grep_tree(root, (needle,), suffixes=(".py",))
        if hits:
            found.append("%s in %s" % (needle, ", ".join(os.path.relpath(h, root) for h in hits)))
    if found:
        return FAIL, "; ".join(found)
    return PASS, "none of %s imported under agent/" % ", ".join(needles)


def _urls_in(node: Any) -> List[str]:
    if isinstance(node, dict):
        return [u for v in node.values() for u in _urls_in(v)]
    if isinstance(node, list):
        return [u for item in node for u in _urls_in(item)]
    if isinstance(node, str) and "://" in node:
        return [node]
    return []


def check_egress_registry_no_forbidden_hosts(ctx: Ctx) -> CheckResult:
    services = gcloud_probe_json(ctx, "agent-registry", "services", "list",
                                 "--location", ctx.need("REGION"))
    if services is None:
        return SKIP, "cannot list registry services"
    if not services:
        return SKIP, "no endpoints registered yet ('walle registry')"
    offending = []
    for service in services:
        for url in _urls_in(service):
            host = (urllib.parse.urlsplit(url).netloc or url).lower()
            if any(marker in host for marker in FORBIDDEN_EGRESS_HOST_MARKERS):
                offending.append("%s -> %s" % (service.get("name", "?"), host))
    if offending:
        return FAIL, ("the egress allowlist names a host the reasoning layer must never "
                      "reach directly: %s" % "; ".join(offending))
    return PASS, "%d registered endpoints, none of them a forbidden host" % len(services)


def check_cross_project_dataset_access(ctx: Ctx) -> CheckResult:
    """project-topology.md rows 4, 6 and 9 on Wall-E's two datasets.

    Positive: the dataset-level READER entries for Eve's and Mo's identities
    (a missing one is "not yet granted", SKIP, since the principal may not
    exist before Eve's Phase 8 / Mo-2). Negative, and the part that is a
    control: NO authorised-view entry naming a dataset in another project —
    a view runs with its own authorisation, mo-metrics@ can redefine it, and
    a view authorised on walle_audit would hand raw free text to any reader of
    the view's dataset (row 9) — and no READER entry for an Eve or Mo account
    spelled in Wall-E's own project (the old placement).
    """
    problems: List[str] = []
    pending: List[str] = []
    checked = 0
    foreign_projects = {ctx.need("EVE_PROJECT"), ctx.need("MO_PROJECT")}
    for dataset in (ctx.get("AUDIT_DATASET"), ctx.get("LOGS_DATASET")):
        target = "%s:%s" % (ctx.need("PROJECT"), dataset)
        shown = probe(ctx, ["bq", "show", "--format=prettyjson", target])
        if not shown.ok:
            continue
        checked += 1
        access = json.loads(shown.out).get("access", []) or []
        for entry in access:
            view = entry.get("view") or {}
            if view and view.get("projectId") and view.get("projectId") != ctx.need("PROJECT"):
                problems.append(
                    "%s authorises a view from another project (%s.%s.%s); topology row 9 "
                    "forbids any foreign authorised view on a Wall-E dataset"
                    % (dataset, view.get("projectId"), view.get("datasetId"), view.get("tableId"))
                )
            email = str(entry.get("userByEmail", "") or "")
            if email.startswith(("eve-", "mo-")) and email.endswith(
                    "@%s.iam.gserviceaccount.com" % ctx.need("PROJECT")):
                problems.append("%s grants %s, an Eve/Mo account IN Wall-E's project"
                                % (dataset, email))
            if any(email.endswith("@%s.iam.gserviceaccount.com" % p) for p in foreign_projects) \
                    and not _same_dataset_role(str(entry.get("role", "")), "roles/bigquery.dataViewer"):
                problems.append("%s grants %s %s; a foreign identity may hold READER only"
                                % (dataset, email, entry.get("role")))
        for principal_key, dataset_key, stage, row in CROSS_PROJECT_DATASET_READERS:
            if ctx.get(dataset_key) != dataset:
                continue
            wanted = ctx.need(principal_key)
            if not any(
                e.get("userByEmail") == wanted
                and _same_dataset_role(str(e.get("role", "")), "roles/bigquery.dataViewer")
                for e in access
            ):
                pending.append("%s on %s (row %s, %s)" % (wanted, dataset, row, stage))
    if not checked:
        return SKIP, "neither dataset exists yet"
    if problems:
        return FAIL, "; ".join(problems)
    if pending:
        return SKIP, ("no foreign view and no misplaced reader; READER entries not yet present: "
                      "%s — re-run 'walle gcp' once the principal exists" % ", ".join(pending))
    return PASS, ("Eve's and Mo's identities hold dataset-level READER only, no foreign "
                  "authorised view, nothing spelled in Wall-E's project")


# --------------------------------------------------------------------------- #
# The super-admin robot: two clients, two services, the lists (2026-09-13)
# --------------------------------------------------------------------------- #


def check_no_cloud_platform_scope(ctx: Ctx) -> CheckResult:
    """cloud-platform is consented in neither client (platform HLD §13.1 item 3).

    Static half: the constant and the configured list. The consented half is
    robot_credentials_scoped, which reads what Google actually granted. The
    self-test asserts the static half without credentials: that is the CI
    assertion the HLD asks for.
    """
    problems = []
    for label, scopes in (("ROBOT_SCOPES (client 1)", list(ROBOT_SCOPES)),
                          ("SUPER_SCOPES (client 2)", parse_scope_list(ctx.get("SUPER_SCOPES")))):
        bad = forbidden_scopes(scopes)
        if bad:
            problems.append("%s carries %s" % (label, ", ".join(bad)))
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "no cloud-platform scope in either client's list%s" % (
        "" if ctx.get("SUPER_SCOPES") else " (client 2's list not set yet)")


def check_hard_denied_list(ctx: Ctx) -> CheckResult:
    """The hard-denied list as data: closed vocabulary, every row resolvable."""
    problems = hard_denied_problems()
    unresolved = sorted({t for row in hard_denied_resolved(ctx.cfg) for t in row["targets"]
                         if "unset>" in t})
    if unresolved:
        problems.append("targets that cannot be resolved from the config: %s" % unresolved)
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "%d hard-denied rows, closed reason vocabulary, every target resolved; " \
                 "the denial suite exercises them (walle denials)" % len(HARD_DENIED)


def check_secret_readers_split(ctx: Ctx) -> CheckResult:
    """One reader per OAuth pair, never crossed (platform HLD §13.1 item 3)."""
    problems = []
    checked = 0
    members = {key: "serviceAccount:" + ctx.need(key) for key in ("SA_ACTIONS", "SA_ACTIONS_SUPER")}
    for secret, reader_key in SECRET_READERS.items():
        if not secret_exists(ctx, secret):
            continue
        checked += 1
        policy = gcloud_probe_json(
            ctx, "secrets", "get-iam-policy", secret, "--location", ctx.need("REGION")) or {}
        accessors = set(_members_with_role(policy, "roles/secretmanager.secretAccessor"))
        other_key = "SA_ACTIONS_SUPER" if reader_key == "SA_ACTIONS" else "SA_ACTIONS"
        if members[other_key] in accessors:
            problems.append("%s is readable by %s; each client has exactly one reader"
                            % (secret, ctx.need(other_key)))
        extra = sorted(a for a in accessors if a != members[reader_key])
        if extra:
            problems.append("%s has accessors beyond %s: %s" % (secret, ctx.need(reader_key), extra))
    if not checked:
        return SKIP, "no Wall-E secret exists yet (phase 8)"
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "narrow pair read by walle-actions@ only, broad pair by walle-actions-super@ only"


def check_super_service(ctx: Ctx) -> CheckResult:
    """walle-actions-super: env complete, pins a number, allowlists and invokers
    EXACTLY the HLD's set, compared both ways (tightened 2026-09-13; the old
    check only intersected with a denylist, so walle-actions@, a user: or
    group: principal, or any unlisted account passed):

      EXEC_CALLER_ALLOWLIST    = {the agent's service account} plus, only when
                                 AGENT_IDENTITY_SPIKE_RESULT is on file, the
                                 agent-identity claim;
      CONTROL_CALLER_ALLOWLIST = {eve-controller@, eve-verifier@} (halt only,
                                 project-topology.md row 27);
      run.invoker              = {the agent's service account, eve-controller@,
                                 eve-verifier@} plus the agent principal bound
                                 in Phase 12b, plus SUPER_EXTRA_INVOKERS (the
                                 approval surface's and the platform drift job's
                                 accounts once named).
    Never the narrow secrets, no read or internal list."""
    env = deployed_service_env(ctx, SUPER_SERVICE)
    if env is None:
        return SKIP, "walle-actions-super is not deployed yet (band B client not consented)"
    problems = []
    missing = [n for n in SUPER_ENV_NAMES if not str(env.get(n, "")).strip()]
    if missing:
        problems.append("missing or empty env: %s" % missing)
    if env.get("REFRESH_TOKEN_SECRET") != SUPER_CLIENT_SECRETS[1] or \
            env.get("OAUTH_CLIENT_SECRET") != SUPER_CLIENT_SECRETS[0]:
        problems.append("it does not read the broad pair (%s, %s): %s, %s" % (
            SUPER_CLIENT_SECRETS[0], SUPER_CLIENT_SECRETS[1],
            env.get("OAUTH_CLIENT_SECRET"), env.get("REFRESH_TOKEN_SECRET")))
    if not str(env.get("REFRESH_TOKEN_VERSION", "")).isdigit():
        problems.append("REFRESH_TOKEN_VERSION is %r, not a version NUMBER"
                        % env.get("REFRESH_TOKEN_VERSION"))
    for name in ("READ_CALLER_ALLOWLIST", "INTERNAL_CALLER_ALLOWLIST"):
        if name in env:
            problems.append("%s is set; the band-B service has no read and no internal "
                            "caller" % name)
    agent_sa = ctx.need("SA_AGENT")
    eve_control = {ctx.need("SA_EVE"), ctx.need("SA_EVE_VERIFIER")}
    spike_on_file = bool(ctx.get("AGENT_IDENTITY_SPIKE_RESULT")) and os.path.isfile(
        os.path.expanduser(ctx.get("AGENT_IDENTITY_SPIKE_RESULT")))

    def is_agent_claim(entry: str) -> bool:
        return entry.startswith("principal://" + AGENT_TRUST_DOMAIN_PREFIX) or \
            entry.startswith(AGENT_TRUST_DOMAIN_PREFIX)

    exec_list = [e.strip() for e in env.get("EXEC_CALLER_ALLOWLIST", "").split(",") if e.strip()]
    control = [e.strip() for e in env.get("CONTROL_CALLER_ALLOWLIST", "").split(",") if e.strip()]
    if ctx.need("SA_DISPATCH") in exec_list + control:
        problems.append("walle-dispatcher@ is on an allowlist; it has no route to band B")
    exec_extra = sorted(e for e in set(exec_list)
                        if e != agent_sa and not (spike_on_file and is_agent_claim(e)))
    if exec_extra:
        problems.append("EXEC_CALLER_ALLOWLIST names callers the HLD does not give this "
                        "service: %s (expected the agent only)" % exec_extra)
    if not any(e == agent_sa or is_agent_claim(e) for e in exec_list):
        problems.append("EXEC_CALLER_ALLOWLIST does not name the agent (%s)" % agent_sa)
    if set(control) != eve_control or len(control) != len(set(control)):
        problems.append("CONTROL_CALLER_ALLOWLIST is %s, expected exactly eve-controller@ and "
                        "eve-verifier@ of %s (halt only; extra %s, missing %s)" % (
                            control, ctx.need("EVE_PROJECT"),
                            sorted(set(control) - eve_control), sorted(eve_control - set(control))))
    policy = gcloud_probe_json(ctx, "run", "services", "get-iam-policy", SUPER_SERVICE,
                               "--region", ctx.need("REGION")) or {}
    members = {m for b in policy.get("bindings", []) for m in b.get("members", [])}
    if members & {"allUsers", "allAuthenticatedUsers"}:
        problems.append("walle-actions-super is publicly invocable")
    invokers = set(_members_with_role(policy, "roles/run.invoker"))
    required = {"serviceAccount:" + agent_sa} | {"serviceAccount:" + e for e in eve_control}
    extra_ok = {m.strip() for m in ctx.get("SUPER_EXTRA_INVOKERS", "").split(",") if m.strip()}
    allowed = required | extra_ok
    extra = sorted(m for m in invokers - allowed if not is_agent_claim(m))
    if extra:
        problems.append("run.invoker on walle-actions-super held by %s; the set is the agent, "
                        "eve-controller@ and eve-verifier@ (plus SUPER_EXTRA_INVOKERS)" % extra)
    missing_invokers = sorted(required - invokers)
    if missing_invokers:
        problems.append("run.invoker on walle-actions-super is missing %s (an Eve identity "
                        "absent before Eve's runbook created it: re-run 'walle deploy')"
                        % missing_invokers)
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "broad pair pinned to version %s; EXEC the agent, CONTROL eve-controller@ " \
                 "and eve-verifier@ only; invokers exactly the HLD's set" % env.get("REFRESH_TOKEN_VERSION")

CHECKS: Tuple[Tuple[str, str, Callable[[Ctx], CheckResult]], ...] = (
    ("agent_reads_no_secret", "8", check_agent_reads_no_secret),
    # Rewritten 2026-09-13: Wall-E's Stage 0 role is retired; Eve's role is checked.
    ("eve_role_is_read_only", "2", check_eve_role_is_read_only),
    ("role_assignments", "2", check_role_assignments),
    ("secrets_regional_and_version_pinned", "8/10", check_secrets_regional_and_pinned),
    ("kms_separation", "8", check_kms_separation),
    ("actions_cannot_delete_bigquery", "8", check_actions_cannot_delete_bigquery),
    ("cross_project_dataset_access", "7", check_cross_project_dataset_access),
    ("sink_actor_exclusion", "11", check_sink_filters),
    ("engine_two_principals", "12", check_engine_principals),
    ("schedulers_paused_watch_running", "14/16", check_scheduler_states),
    ("ladder_config", "14", check_ladder_config),
    ("actions_env_complete", "10", check_actions_env_complete),
    ("control_caller_allowlist", "10", check_control_caller_allowlist),
    ("read_caller_allowlist", "10", check_read_caller_allowlist),
    ("cloud_run_requires_auth", "10/11", check_cloud_run_requires_auth),
    ("project_roles", "6", check_project_roles),
    ("run_invoker_handles", "10/11", check_run_invoker_handles),
    ("residency_and_ingress", "6/7/10", check_residency),
    ("audit_tables_partitioned", "7", check_audit_tables),
    ("eve_credential_separation", "8", check_eve_separation),
    ("protected_group_covers_floor", "1", check_protected_covers_floor),
    # Inverted 2026-09-13: the robot IS a super admin once the grant is on file.
    ("robot_hardening_and_roster", "3/gate", check_robot_hardening),
    ("robot_credentials_scoped", "9", check_robot_credentials_scoped),
    ("sandbox_accounts", "1", check_sandbox),
    ("exactly_one_engine", "12", check_single_engine),
    ("budget_alert", "6", check_budget),
    ("workspace_log_sharing", "5", verify_workspace_log_sharing),
    ("gemini_registration", "13", verify_gemini_registration),
    ("engine_properties", "12", check_engine_properties),
    # The only check that asks Google rather than Wall-E's own configuration.
    ("no_robot_writes_at_google", "12/14/18", check_no_robot_writes),
    # Phases 12b, 12c and 13b.
    ("agent_identity_effective", "12b", check_agent_identity_effective),
    ("engine_no_span_content", "12c", check_engine_no_span_content),
    ("engine_no_token_sharing_optout", "12b", check_engine_no_token_sharing_optout),
    ("agentidentitycredentials_disabled", "12b", check_agentidentitycredentials_disabled),
    ("extension_yaml_fail_closed", "12c", check_extension_yaml_fail_closed),
    ("dispatcher_uses_stream_query", "12c", check_dispatcher_stream_query),
    ("agent_no_dynamic_toolsets", "13b", check_agent_no_dynamic_toolsets),
    ("egress_registry_no_forbidden_hosts", "13b", check_egress_registry_no_forbidden_hosts),
    # The super-admin robot (2026-09-13, platform HLD §13.1 items 2 and 3).
    ("no_cloud_platform_scope", "9", check_no_cloud_platform_scope),
    ("hard_denied_list", "17", check_hard_denied_list),
    ("secret_readers_split", "8", check_secret_readers_split),
    ("super_service_allowlists", "10", check_super_service),
)


def cmd_verify(ctx: Ctx) -> int:
    section("verify — every security invariant, asserted")
    # Fail on a broken environment once, here. Without this the Workspace checks
    # each report the same underlying problem and a missing venv or an expired
    # operator consent reads as eight security failures.
    _import_google()
    client_status, client_detail = verify_operator_client_file(ctx)
    if client_status != PASS:
        die("cannot reach the Admin SDK: %s (manual step M0)" % client_detail)
    try:
        operator_credentials(ctx)
    except WalleError:
        raise
    except Exception as exc:
        die("operator consent is not usable: %s: %s" % (type(exc).__name__, exc))
    rows: List[List[str]] = []
    failures = 0
    skips = 0
    for name, phase, function in CHECKS:
        try:
            status, detail = function(ctx)
        except WalleError as exc:
            status, detail = FAIL, str(exc).splitlines()[0][:160]
        except Exception as exc:  # a check that crashes is a failed check
            status, detail = FAIL, "%s: %s" % (type(exc).__name__, exc)
        if status == FAIL:
            failures += 1
        elif status == SKIP:
            skips += 1
        rows.append([status, name, phase, detail[:110]])
    say("")
    say(render_table(rows, ["RESULT", "CHECK", "PHASE", "DETAIL"]))
    say("")
    say("%d checks: %d passed, %d failed, %d could not run"
        % (len(rows), len(rows) - failures - skips, failures, skips))
    if skips:
        warn("a skipped check is not a passed check. Re-run once its phase is done.")
    if failures:
        warn("verification FAILED. Do not proceed to the next phase.")
        return 1
    if skips and getattr(ctx.args, "strict", False):
        warn("--strict: treating %d skipped checks as failures" % skips)
        return 1
    say("")
    say("Every invariant holds. The playbook schedules are still PAUSED, which is")
    say("the deliberate final state of the build, not an oversight. Stage 0 entry is")
    say("a separate act: `walle stage0`.")
    print_manual_steps(ctx, "verify")
    return 0


# --------------------------------------------------------------------------- #
# denials — section 4 of the runbook, against the deployed service
# --------------------------------------------------------------------------- #


def cmd_denials(ctx: Ctx) -> int:
    section("Phase 17 — the denial suite")
    url = ctx.get("ACTIONS_URL") or current_service_url(ctx, "walle-actions")
    if not url:
        die("walle-actions is not deployed; there is nothing to test")
    infra = run_infrastructure_denials(ctx, url)
    rows = [[status, "%02d" % number, name, detail[:90]] for number, name, status, detail in infra]
    say("")
    say(render_table(rows, ["RESULT", "#", "TEST", "DETAIL"]))
    failures = sum(1 for _n, _t, status, _d in infra if status == FAIL)

    script = os.path.join(os.path.expanduser(ctx.need("WALLE_REPO")), "tests", "denials.py")
    if not os.path.isfile(script):
        warn(
            "tests/denials.py is not in the repository. The 52-test suite is the "
            "gate, not these five: a promotion whose denial suite has not been run "
            "is not a promotion, it is a hope."
        )
        return 1
    # min-instances=2 tells per-instance state apart from durable state. Test 27
    # is meaningless on a single instance.
    say("")
    say("  raising min-instances to 2 so test 27 can distinguish durable counters")
    run(ctx, ["gcloud", "run", "services", "update", "walle-actions",
              "--region", ctx.need("REGION"), "--min-instances", "2",
              "--project", ctx.need("PROJECT")])
    try:
        output = os.path.join(
            os.path.expanduser(ctx.need("WALLE_REPO")), "drills",
            "denials-%s.json" % datetime.date.today().isoformat(),
        )
        os.makedirs(os.path.dirname(output), exist_ok=True)
        # The hard-denied list as data (2026-09-13, platform HLD §13.1 items 2
        # and 10). Every row must be refused in every lane with its reason and
        # a severity-1 page, including "a write targeting the robot itself"
        # (HD-01) and "any makeAdmin" (HD-11). The contract with
        # tests/denials.py is the environment, like deploy.py's: the file path
        # and the band-B service URL. Not a secret; a scratch file.
        problems = hard_denied_problems()
        if problems:
            die("the hard-denied list is inconsistent: %s" % "; ".join(problems))
        # Added 2026-09-13: the same resolvability rule as check_hard_denied_list.
        # A row whose target reads "<EVE_ROBOT unset>" would be handed to the
        # suite, test nothing and read green.
        unresolved = sorted({t for row in hard_denied_resolved(ctx.cfg) for t in row["targets"]
                             if "unset>" in t})
        if unresolved:
            die("the hard-denied list has targets the config cannot resolve: %s; set those "
                "keys before running the denial suite" % unresolved)
        hard_denied_path = ctx.scratch_file(
            "hard-denied.json", json.dumps(hard_denied_resolved(ctx.cfg), indent=2))
        say("  hard-denied list for the suite: %d rows -> %s"
            % (len(HARD_DENIED), hard_denied_path))
        denial_env = {"WALLE_HARD_DENIED_FILE": hard_denied_path}
        super_url = ctx.get("SUPER_ACTIONS_URL") or current_service_url(ctx, SUPER_SERVICE)
        if super_url:
            denial_env["WALLE_SUPER_ACTIONS_URL"] = super_url
        else:
            warn("walle-actions-super is not deployed: the suite can test the hard-denied "
                 "rows in band A only. Bands B and C must be run once it exists.")
            ctx.note("hard-denied rows NOT yet tested in bands B and C (no walle-actions-super)")
        result = run(
            ctx,
            [
                sys.executable, script, "--actions-url", url,
                "--project", ctx.need("PROJECT"), "--json",
            ],
            check=False,
            env=denial_env,
        )
        if not ctx.dry_run:
            with open(output, "w", encoding="utf-8") as handle:
                handle.write(result.out)
            say("  wrote %s" % output)
        if not result.ok:
            warn("the denial suite reported failures. Every failure is a build blocker.")
            failures += 1
    finally:
        # Restoring min-instances is not error swallowing: the exception, if any,
        # propagates out of the finally block untouched.
        say("  restoring min-instances to 0")
        run(ctx, ["gcloud", "run", "services", "update", "walle-actions",
                  "--region", ctx.need("REGION"), "--min-instances", "0",
                  "--project", ctx.need("PROJECT")])
    failures += phase_17_actor_exclusion(ctx)
    return 1 if failures else 0


def phase_17_actor_exclusion(ctx: Ctx) -> int:
    """The behavioural half of check 48, deferred from Phase 11 on purpose.

    It needs a working credential, so SETUP.md puts it alongside denial test 48
    rather than in Phase 11. check_sink_filters only inspects the filter TEXT,
    which is the static half. "An event that appears in check 1 and also in
    check 2 is the loop in 7.9. Stop and fix the sink filter before Phase 18."
    """
    say("")
    section("Phase 17 check 48 — the behavioural half of the actor exclusion")
    say("  Generate ONE robot-attributed admin event on a SANDBOX account through")
    say("  the action service, then confirm both halves: Google saw it, and the")
    say("  dispatcher did not turn it into a trigger.")
    confirm(ctx, "Have you generated exactly one robot-attributed admin event?")
    if ctx.dry_run:
        return 0
    seen = probe(ctx, [
        "gcloud", "logging", "read",
        'protoPayload.serviceName="admin.googleapis.com" AND '
        'protoPayload.authenticationInfo.principalEmail="%s"' % ctx.need("ROBOT"),
        "--organization", ctx.need("ORG_ID"), "--freshness", "1h", "--limit", "5",
        "--format", "value(protoPayload.methodName)",
    ])
    triggered = probe(ctx, [
        "gcloud", "run", "services", "logs", "read", "walle-dispatcher",
        "--region", ctx.need("REGION"), "--limit", "100",
        "--project", ctx.need("PROJECT"),
    ])
    leaked = [
        line for line in triggered.out.splitlines()
        if "trigger" in line.lower() and ctx.need("ROBOT") in line
    ]
    if not seen.out.strip():
        warn("48: Google saw no robot-attributed event; the test proved nothing.")
        return 0
    if leaked:
        die(
            "48 FAILED: the dispatcher logged a trigger for a robot-attributed "
            "event. That is the loop in SETUP.md 7.9 — Wall-E's own writes feeding "
            "Wall-E's own triggers. Fix the sink filter before Phase 18."
        )
    step("48: Google saw the event, the dispatcher did not. The exclusion held.")
    return 0


def run_infrastructure_denials(ctx: Ctx, url: str) -> List[Tuple[int, str, str, str]]:
    """The handful of denial tests that are platform, not application, behaviour.

    These prove things at Google's end. They do not replace tests/denials.py.
    """
    results: List[Tuple[int, str, str, str]] = []

    status, _payload = http_json(ctx, "GET", url + "/v1/ladder", "")
    results.append((
        1, "unauthenticated request",
        PASS if status in (401, 403) else FAIL,
        "HTTP %s (expect 403 at Cloud Run, before the app is reached)" % status,
    ))

    bad = id_token(ctx, "https://example.invalid")
    status, _payload = http_json(ctx, "GET", url + "/v1/ladder", bad)
    results.append((
        2, "valid token, wrong audience",
        PASS if status in (401, 403) else FAIL,
        "HTTP %s (expect 401 bad_audience)" % status,
    ))

    # A refusal only proves something if we got as far as being refused BY THE
    # SECRET. Nothing grants the operator tokenCreator on walle-agent@, so the
    # impersonation itself normally fails with a message containing "permission"
    # and "denied", and this test used to report PASS without ever reaching
    # Secret Manager.
    can_agent, why_agent = impersonation_works(ctx, ctx.need("SA_AGENT"))
    # Both refresh tokens since 2026-09-13: the broad one is the super-admin
    # credential with the widest scopes, and trust boundary 3 covers it too.
    for token_secret in (NARROW_CLIENT_SECRETS[1], SUPER_CLIENT_SECRETS[1]):
        if not can_agent:
            results.append((7, "walle-agent@ accesses %s" % token_secret, SKIP, why_agent))
        elif not secret_exists(ctx, token_secret):
            results.append((7, "walle-agent@ accesses %s" % token_secret, SKIP, "secret absent"))
        else:
            probe_secret = run(
                ctx,
                [
                    "gcloud", "secrets", "versions", "access", "latest",
                    "--secret", token_secret, "--location", ctx.need("REGION"),
                    "--project", ctx.need("PROJECT"),
                    # If this test FAILS the payload exists; never let it reach a
                    # terminal or a captured log.
                    "--out-file", os.devnull,
                ],
                mutating=False, check=False, stdout_is_secret=True,
                env={"CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT": ctx.need("SA_AGENT")},
            )
            results.append((
                7, "walle-agent@ accesses %s" % token_secret,
                FAIL if probe_secret.ok else PASS,
                "SUCCEEDED, which is trust boundary 3 gone" if probe_secret.ok
                else "refused at Google",
            ))

    status_bq, detail_bq = check_actions_cannot_delete_bigquery(ctx)
    results.append((9, "walle-actions@ DELETEs audit rows", status_bq, detail_bq))

    say("")
    say("  Test 52 (an operator can halt) sets and clears a halt on the live service.")
    confirm(ctx, "Run denial test 52, which sets and then clears a halt?")
    token = id_token(ctx, url)
    halted = False
    status = 0
    try:
        status, _payload = http_json(
            ctx, "POST", url + "/v1/control/halt", token,
            {"mode": "no_writes", "reason": "denial test 52"},
        )
        halted = status in (200, 202)
    finally:
        # SETUP.md section 5 records "whether the halt state was correctly
        # cleared afterwards" precisely because a drill that leaves writes
        # halted is a drill that becomes an outage on Monday. The clear is not
        # fire-and-forget and its status is not optional.
        if halted:
            clear_status, _clear = http_json(
                ctx, "POST", url + "/v1/control/halt", token,
                {"mode": "clear", "reason": "denial test 52 complete"},
            )
            if clear_status not in (200, 202):
                die(
                    "denial test 52 set a no_writes halt and the CLEAR returned HTTP "
                    "%s. WRITES ARE HALTED RIGHT NOW. Clear it by hand before "
                    "anything else:\n"
                    "  curl -X POST -H \"Authorization: Bearer <token>\" \\\n"
                    "    %s/v1/control/halt \\\n"
                    "    -d '{\"mode\":\"clear\",\"reason\":\"manual clear\"}'"
                    % (clear_status, url)
                )
    results.append((
        52, "operator halt is accepted and cleared",
        PASS if halted else FAIL,
        "HTTP %s. Eve alone in the allowlist leaves no human able to halt" % status,
    ))
    return results


# --------------------------------------------------------------------------- #
# status
# --------------------------------------------------------------------------- #


def cmd_status(ctx: Ctx) -> int:
    section("status — where this build actually is")
    rows: List[List[str]] = []

    def add(phase: str, resource: str, present: bool, detail: str = "") -> None:
        rows.append([phase, resource, "yes" if present else "NO", detail])

    try:
        for path_key in ("SVC_OU", "SANDBOX_OU"):
            path = ctx.get(path_key)
            found = api_get(
                ctx, "orgunits.get", admin(ctx).orgunits().get(
                    customerId=ctx.need("CUSTOMER_ID"), orgUnitPath=path.strip("/")),
                absent_on_403=True,
            )
            add("1", "OU %s" % path, bool(found))
        for key in ("ROBOT", "EVE_ROBOT"):
            record = api_get(ctx, "users.get", admin(ctx).users().get(userKey=ctx.get(key)))
            add("1", "user %s" % ctx.get(key), bool(record),
                (record or {}).get("orgUnitPath", ""))
        for key in ("OPERATORS", "READERS", "PROTECTED"):
            record = api_get(ctx, "groups.get", admin(ctx).groups().get(groupKey=ctx.get(key)))
            add("1", "group %s" % ctx.get(key), bool(record),
                "%s members" % (record or {}).get("directMembersCount", "?"))
        role = find_role(ctx, ROLE_EVE_NAME)
        assignments = list_role_assignments(ctx, role["roleId"]) if role else []
        add("2", "role %s" % ROLE_EVE_NAME, bool(role), "%d assignment(s)" % len(assignments))
        # Retired 2026-09-13: "yes" on these rows is a finding, not progress.
        for title in RETIRED_WALLE_ROLE_NAMES:
            role = find_role(ctx, title)
            if role:
                assignments = list_role_assignments(ctx, role["roleId"])
                add("2", "RETIRED role %s (remove it)" % title, True,
                    "%d assignment(s)" % len(assignments))
        robot = api_get(ctx, "users.get", admin(ctx).users().get(userKey=ctx.get("ROBOT")))
        add("gate", "robot is a super admin", bool((robot or {}).get("isAdmin")),
            "grant record on file" if super_admin_grant_on_file(ctx)
            else "no grant record: must read NO until the tier gate")
    except WalleError as exc:
        rows.append(["1/2", "Workspace", "?", str(exc).splitlines()[0][:80]])

    add("6", "project %s" % ctx.get("PROJECT"),
        gcloud_probe_json(ctx, "projects", "describe", ctx.need("PROJECT")) is not None,
        "number %s" % project_number(ctx))
    accounts = gcloud_probe_json(ctx, "iam", "service-accounts", "list") or []
    add("6", "service accounts", len(accounts) >= len(SERVICE_ACCOUNT_IDS),
        "%d present (Wall-E's %d; Eve's and Mo's live in their own projects)"
        % (len(accounts), len(SERVICE_ACCOUNT_IDS)))
    add("6", "staging bucket",
        gcloud_probe_json(ctx, "storage", "buckets", "describe", ctx.need("STAGING_BUCKET"))
        is not None)
    firestore = gcloud_probe_json(
        ctx, "firestore", "databases", "describe", "--database", "(default)")
    add("7", "Firestore", firestore is not None, (firestore or {}).get("locationId", ""))
    for dataset in (ctx.get("AUDIT_DATASET"), ctx.get("LOGS_DATASET")):
        add("7", "dataset %s" % dataset, bq_dataset_exists(ctx, dataset))
    topics = gcloud_probe_json(ctx, "pubsub", "topics", "list") or []
    add("7", "pub/sub topics", len(topics) >= 4, "%d present" % len(topics))
    add("7", "tasks queue",
        gcloud_probe_json(ctx, "tasks", "queues", "describe", ctx.get("TASKS_QUEUE"),
                          "--location", ctx.need("REGION")) is not None)
    # Eve's key and secrets are NOT in this project: no row pretends to look
    # for them here. The cross-project grants this script OWNS are reported
    # below, under their own heading.
    for secret in WALLE_SECRETS:
        versions = gcloud_probe_json(
            ctx, "secrets", "versions", "list", secret, "--location", ctx.need("REGION"),
            "--filter", "state=ENABLED") if secret_exists(ctx, secret) else None
        add("8", "secret %s" % secret, versions is not None,
            "%d enabled version(s)" % len(versions or []))
    # Cross-project grants made by this runbook on Wall-E's resources
    # (project-topology.md §7.1). Read-only probes, never an abort.
    try:
        for principal_key, dataset_key, _stage, row in CROSS_PROJECT_DATASET_READERS:
            dataset = ctx.get(dataset_key)
            shown = probe(ctx, ["bq", "show", "--format=prettyjson",
                                "%s:%s" % (ctx.need("PROJECT"), dataset)])
            access = json.loads(shown.out).get("access", []) if shown.ok else []
            wanted = ctx.get(principal_key, "")
            add("7 x-proj", "READER %s on %s" % (wanted, dataset),
                any(e.get("userByEmail") == wanted for e in access or []),
                "topology row %s" % row)
    except (WalleError, ValueError) as exc:
        rows.append(["7 x-proj", "dataset readers", "?", str(exc).splitlines()[0][:60]])
    try:
        actions_policy = gcloud_probe_json(
            ctx, "run", "services", "get-iam-policy", "walle-actions",
            "--region", ctx.need("REGION")) or {}
        invokers = set(_members_with_role(actions_policy, "roles/run.invoker"))
        for label, member in (
            ("eve-controller@ (EVE_PROJECT)", "serviceAccount:" + ctx.get("SA_EVE", "")),
            ("eve-verifier@ (EVE_PROJECT)", "serviceAccount:" + ctx.get("SA_EVE_VERIFIER", "")),
            ("eve-console@ (EVE_PROJECT)", "serviceAccount:" + ctx.get("SA_EVE_CONSOLE", "")),
            ("mo-analyst@ (MO_PROJECT)", iam_member(ctx.get("MO_PRINCIPAL", "") or "-")),
        ):
            add("10 x-proj", "run.invoker %s" % label, member in invokers, "topology rows 3, 8")
    except WalleError as exc:
        rows.append(["10 x-proj", "run.invoker", "?", str(exc).splitlines()[0][:60]])
    for service in ("walle-actions", SUPER_SERVICE, "walle-dispatcher"):
        url = current_service_url(ctx, service)
        add("10/11", "cloud run %s" % service, bool(url), url)
    for sink in ("walle-workspace-audit", "walle-audit-bq"):
        add("11", "org sink %s" % sink,
            gcloud_probe_json(ctx, "logging", "sinks", "describe", sink,
                              "--organization", ctx.need("ORG_ID")) is not None)
    # status is the command you run after an interruption, so a single
    # unreadable resource must not take the whole report down with it.
    try:
        engines = list_engines(ctx)
        add("12", "reasoning engine", len(engines) == 1,
            "%d found" % len(engines) if engines else "none")
        if len(engines) == 1:
            engine_id = str(engines[0].get("name", "")).rsplit("/", 1)[-1]
            gemini_number = gemini_project_number(ctx) or "<GEMINI_PROJECT_NUMBER>"
            gemini_agent = ("serviceAccount:service-%s@gcp-sa-discoveryengine.iam."
                            "gserviceaccount.com" % gemini_number)
            status_code, policy = http_json(
                ctx, "POST",
                aiplatform_url(ctx, "%s/%s:getIamPolicy" % (engine_collection_path(ctx), engine_id)),
                access_token(ctx), {}, mutating=False,
            )
            members = {m for b in (policy or {}).get("bindings", []) for m in b.get("members", [])} \
                if status_code == 200 and isinstance(policy, dict) else set()
            add("12 x-proj", "engine member service-%s@ (GEMINI_PROJECT)" % gemini_number,
                gemini_agent in members, "topology row 1")
    except WalleError as exc:
        add("12", "reasoning engine", False,
            "unreadable: %s" % str(exc).splitlines()[0][:60])
    jobs = gcloud_probe_json(ctx, "scheduler", "jobs", "list",
                             "--location", ctx.need("REGION")) or []
    states = ", ".join(
        "%s=%s" % (j.get("name", "").rsplit("/", 1)[-1], j.get("state")) for j in jobs)
    add("14/16", "scheduler jobs", bool(jobs), states[:80])
    env = deployed_actions_env(ctx)
    add("10", "refresh token pin", bool(env and env.get("REFRESH_TOKEN_VERSION", "").isdigit()),
        "version %s" % (env or {}).get("REFRESH_TOKEN_VERSION", "-"))
    super_env = deployed_service_env(ctx, SUPER_SERVICE)
    add("10", "band-B refresh token pin",
        bool(super_env and super_env.get("REFRESH_TOKEN_VERSION", "").isdigit()),
        "version %s" % (super_env or {}).get("REFRESH_TOKEN_VERSION", "-"))
    # Phases 12b, 12c, 13b. Read-only probes; an unreadable one is a "NO" row,
    # never an abort: status is the command you run when something is broken.
    try:
        engine_id = resolve_engine_id(ctx)
        effective = read_effective_identity(ctx, engine_id) if engine_id else ""
        add("12b", "agent identity", effective.startswith(AGENT_TRUST_DOMAIN_PREFIX),
            (effective or "none")[:60])
    except WalleError as exc:
        add("12b", "agent identity", False, str(exc).splitlines()[0][:60])
    for template in ARMOR_TEMPLATES:
        try:
            described = gcloud_probe_json(ctx, "beta", "model-armor", "templates", "describe",
                                          template, "--location", ctx.need("REGION"))
            add("12c", "armor template %s" % template, described is not None,
                str(((described or {}).get("templateMetadata") or {}).get("enforcementType", "")))
        except WalleError as exc:
            add("12c", "armor template %s" % template, False, str(exc).splitlines()[0][:60])
    for phase, gateway in (("12c", INGRESS_GATEWAY_NAME),
                           ("13b", ctx.get("EGRESS_GATEWAY") or EGRESS_GATEWAY_NAME)):
        try:
            add(phase, "agent gateway %s" % gateway,
                gcloud_probe_json(ctx, "network-services", "agent-gateways", "describe",
                                  gateway, "--location", ctx.need("REGION")) is not None)
        except WalleError as exc:
            add(phase, "agent gateway %s" % gateway, False, str(exc).splitlines()[0][:60])
    try:
        registered = gcloud_probe_json(ctx, "agent-registry", "services", "list",
                                       "--location", ctx.need("REGION")) or []
        add("13b", "egress endpoints", bool(registered), "%d registered" % len(registered))
    except WalleError as exc:
        add("13b", "egress endpoints", False, str(exc).splitlines()[0][:60])
    say("")
    say(render_table(rows, ["PHASE", "RESOURCE", "PRESENT", "DETAIL"]))
    say("")
    say("Config values still to fill in as phases produce them:")
    for key in ("PROJECT_NUMBER", "GEMINI_PROJECT_NUMBER", "REFRESH_TOKEN_VERSION",
                "SUPER_REFRESH_TOKEN_VERSION", "ACTIONS_URL", "SUPER_ACTIONS_URL",
                "DISPATCHER_URL", "ENGINE_ID", "SUPER_ADMIN_GRANT_DECISION",
                "SUPER_ADMIN_ROSTER"):
        say("  %-28s %s" % (key, ctx.get(key) or "<empty>"))
    say("(EVE_TOKEN_VERSION is Eve's runbook's, in EVE_PROJECT; not tracked here.)")
    return 0


# --------------------------------------------------------------------------- #
# teardown
# --------------------------------------------------------------------------- #


def cmd_teardown(ctx: Ctx) -> int:
    section("teardown — the only subcommand that deletes anything")
    project = ctx.need("PROJECT")
    say("  This deletes resources this script created, in dependency order.")
    say("  It does NOT delete the GCP project unless --delete-project is given,")
    say("  and it does NOT touch Workspace unless --include-workspace is given.")
    say("")
    say("  Note what cannot be undone:")
    say("   - a deleted project id can never be reused")
    say("   - the OAuth grants (both clients) survive project deletion: revoke them")
    say("     as the robot at https://myaccount.google.com/permissions")
    say("   - Super Admin on the robot is NOT removed here: that is K6, a human super")
    say("     admin's act, and teardown never touches the roster")
    say("  And what this teardown never reaches (project-topology.md §1.3): nothing")
    say("  in EVE_PROJECT (%s) or MO_PROJECT (%s) — Eve's key, secrets and mirror,"
        % (ctx.get("EVE_PROJECT", "<EVE_PROJECT>"), ctx.get("MO_PROJECT", "<MO_PROJECT>")))
    say("  Mo's datasets and drop box are their owners' to remove. The dataset-level")
    say("  READER entries and the run.invoker and engine bindings this script made for")
    say("  Eve's and Mo's identities die with the datasets, the services and the engine.")
    say("")
    if not ctx.dry_run:
        if not _is_tty():
            die("teardown needs a terminal: it asks you to type the project id")
        typed = input("  Type the project id (%s) to confirm: " % project).strip()
        if typed != project:
            die("that is not the project id. Nothing was deleted.")

    org = ctx.need("ORG_ID")
    for sink in ("walle-workspace-audit", "walle-audit-bq"):
        if gcloud_probe_json(ctx, "logging", "sinks", "describe", sink,
                             "--organization", org) is not None:
            run(ctx, ["gcloud", "logging", "sinks", "delete", sink,
                      "--organization", org, "--quiet"])
    for job in list(gcloud_probe_json(ctx, "scheduler", "jobs", "list",
                                      "--location", ctx.need("REGION")) or []):
        name = job.get("name", "").rsplit("/", 1)[-1]
        if name.startswith("walle-"):
            run(ctx, ["gcloud", "scheduler", "jobs", "delete", name,
                      "--location", ctx.need("REGION"), "--quiet",
                      "--project", project])
    for sub in ("walle-triggers-push", "walle-inbox-push", "walle-dead-letter-hold"):
        if gcloud_probe_json(ctx, "pubsub", "subscriptions", "describe", sub) is not None:
            run(ctx, ["gcloud", "pubsub", "subscriptions", "delete", sub, "--quiet",
                      "--project", project])
    for engine in list_engines(ctx):
        # Every other loop here is scoped — scheduler jobs to "walle-", topics
        # and subscriptions to module constants, Workspace users to OUs this
        # script created. This one deleted every reasoning engine in the region,
        # which is how a colleague's unrelated Agent Engine deployment in the
        # same project gets destroyed by one flag and one typed project id.
        # The Phase 12b spike engine is this script's too (`walle spike`).
        if engine.get("displayName") not in (ctx.get("ENGINE_DISPLAY_NAME"), SPIKE_DISPLAY_NAME):
            warn(
                "leaving reasoning engine %s (displayName %r) alone: this script "
                "did not create it"
                % (engine.get("name"), engine.get("displayName"))
            )
            continue
        engine_name = str(engine.get("name", ""))
        say("  DELETE reasoning engine %s" % engine_name)
        if not ctx.dry_run:
            confirm(ctx, "Delete reasoning engine %s?" % engine_name)
            status, body = http_json(
                ctx, "DELETE", aiplatform_url(ctx, engine_name), access_token(ctx)
            )
            if status not in (200, 202):
                warn("deleting engine %s returned HTTP %s: %s"
                     % (engine_name, status, str(body)[:200]))
    for service in ("walle-actions", SUPER_SERVICE, "walle-dispatcher"):
        if current_service_url(ctx, service):
            run(ctx, ["gcloud", "run", "services", "delete", service,
                      "--region", ctx.need("REGION"), "--quiet", "--project", project])
    for topic in PUBSUB_TOPICS:
        if gcloud_probe_json(ctx, "pubsub", "topics", "describe", topic) is not None:
            run(ctx, ["gcloud", "pubsub", "topics", "delete", topic, "--quiet",
                      "--project", project])
    if gcloud_probe_json(ctx, "tasks", "queues", "describe", ctx.get("TASKS_QUEUE"),
                         "--location", ctx.need("REGION")) is not None:
        run(ctx, ["gcloud", "tasks", "queues", "delete", ctx.get("TASKS_QUEUE"),
                  "--location", ctx.need("REGION"), "--quiet", "--project", project])
    # Wall-E's five secrets only (both OAuth pairs and the HMAC). Eve's two are
    # in EVE_PROJECT and are Eve's.
    for secret in WALLE_SECRETS:
        if secret_exists(ctx, secret):
            run(ctx, ["gcloud", "secrets", "delete", secret,
                      "--location", ctx.need("REGION"), "--quiet", "--project", project])
    for dataset in (ctx.get("AUDIT_DATASET"), ctx.get("LOGS_DATASET")):
        if bq_dataset_exists(ctx, dataset):
            run(ctx, ["bq", "rm", "-r", "-f", "-d", "%s:%s" % (project, dataset)])
    for role in ("walleAuditWriter", "walleEngineQuery"):
        if gcloud_probe_json(ctx, "iam", "roles", "describe", role,
                             "--project", project) is not None:
            run(ctx, ["gcloud", "iam", "roles", "delete", role, "--project", project,
                      "--quiet"])
    # No --destroy-key-versions any more: Eve's key lives in EVE_PROJECT and
    # destroying its versions is Eve's owner's act (eve/07-build-runbook.md
    # Phase 12). A Wall-E teardown that reached into Eve's project would be
    # the escalation the four-project topology exists to make impossible.
    # Named, not silently left behind: an operator who tears down and re-runs
    # `walle gcp` otherwise gets a partially populated project whose state does
    # not match a clean build.
    if gcloud_probe_json(ctx, "artifacts", "repositories", "describe", "walle",
                         "--location", ctx.need("REGION")) is not None:
        run(ctx, ["gcloud", "artifacts", "repositories", "delete", "walle",
                  "--location", ctx.need("REGION"), "--quiet", "--project", project])
    if gcloud_probe_json(ctx, "storage", "buckets", "describe",
                         ctx.need("STAGING_BUCKET")) is not None:
        run(ctx, ["gcloud", "storage", "rm", "--recursive",
                  ctx.need("STAGING_BUCKET"), "--project", project])
    if getattr(ctx.args, "include_workspace", False):
        if not ctx.dry_run:
            if not _is_tty():
                die("teardown --include-workspace needs a terminal")
            warn(
                "--include-workspace DELETES %s, %s, every sandbox account, the "
                "three groups and the organisational units. A deleted Workspace "
                "user is restorable for 20 days only and needs a spare licence "
                "(SETUP.md 6.2), and deleting %s removes the group the action "
                "service reads on every directory write. The GCP project id you "
                "typed has nothing to do with the Workspace tenant."
                % (ctx.get("ROBOT"), ctx.get("EVE_ROBOT"), ctx.get("PROTECTED"))
            )
            typed_domain = input(
                "  Type the Workspace domain (%s) to confirm: " % ctx.need("DOMAIN")
            ).strip()
            if typed_domain != ctx.need("DOMAIN"):
                die("that is not the domain. Nothing in Workspace was deleted.")
        teardown_workspace(ctx)
    if getattr(ctx.args, "delete_project", False):
        confirm(ctx, "Delete the project? The id can NEVER be reused.")
        run(ctx, ["gcloud", "projects", "delete", project, "--quiet"])
    say("")
    say("  Remaining by design, and NOT cleaned up:")
    say("   - the Firestore database (delete the project to remove it)")
    say("   - both OAuth grants at Google: revoke them as the robot at")
    say("     https://myaccount.google.com/permissions")
    say("   - Super Admin on the robot (K6 is a human's act, never this script's)")
    say("   - the five service accounts and every project-level IAM binding")
    say("   - everything in EVE_PROJECT and MO_PROJECT, which this script never touches")
    say("   - the budget walle-stage-0, which keeps alerting on a rebuilt project")
    say("   - Workspace, unless --include-workspace was given")
    return 0


def teardown_workspace(ctx: Ctx) -> None:
    """Order matters: an OU that still contains a user cannot be deleted, and
    suspending the robot does not remove it from the unit."""
    section("teardown — Workspace")
    # --yes skips confirmations on the BUILD. It must not silently delete a
    # Workspace account: every deletion below is asked for individually.
    ctx.yes = False
    # The retired Wall-E roles are removed too, if a pre-2026-09-13 build left
    # them. The robot's Super Admin is NOT: a Super Admin assignment is not a
    # role this script made, and removing it is K6, a human's act. Deleting a
    # super-admin user through the API is hard-denied for the robot and refused
    # here; the robot's own deletion below is only reached once K6 is done.
    for title in RETIRED_WALLE_ROLE_NAMES + (ROLE_EVE_NAME,):
        role = find_role(ctx, title)
        if not role:
            continue
        for assignment in list_role_assignments(ctx, role["roleId"]):
            api_mutate(
                ctx, "delete role assignment %s" % assignment["roleAssignmentId"],
                lambda a=assignment: admin(ctx).roleAssignments().delete(
                    customer=ctx.need("CUSTOMER_ID"), roleAssignmentId=a["roleAssignmentId"]),
            )
        api_mutate(
            ctx, "delete role %s" % title,
            lambda r=role: admin(ctx).roles().delete(
                customer=ctx.need("CUSTOMER_ID"), roleId=r["roleId"]),
        )
    accounts = [a.strip() for a in ctx.get("SANDBOX_ACCOUNTS").split(",") if a.strip()]
    for email in accounts + [ctx.get("ROBOT"), ctx.get("EVE_ROBOT")]:
        if not email:
            continue
        record = api_get(ctx, "users.get", admin(ctx).users().get(userKey=email))
        if not record:
            continue
        if record.get("orgUnitPath") not in (ctx.get("SVC_OU"), ctx.get("SANDBOX_OU")):
            warn("refusing to delete %s: it is in %s, not an OU this script created"
                 % (email, record.get("orgUnitPath")))
            continue
        if record.get("isAdmin"):
            warn("refusing to delete %s: it is a SUPER ADMIN. A human super admin removes "
                 "the role first (K6) and records it on the roster; then re-run." % email)
            continue
        api_mutate(ctx, "DELETE user %s" % email,
                   lambda e=email: admin(ctx).users().delete(userKey=e))
    for group_key in ("OPERATORS", "READERS", "PROTECTED"):
        email = ctx.get(group_key)
        if email and api_get(ctx, "groups.get", admin(ctx).groups().get(groupKey=email)):
            api_mutate(ctx, "delete group %s" % email,
                       lambda e=email: admin(ctx).groups().delete(groupKey=e))
    for path in (ctx.get("SANDBOX_OU"), ctx.get("SVC_OU")):
        if not path:
            continue
        if api_get(ctx, "orgunits.get", admin(ctx).orgunits().get(
                customerId=ctx.need("CUSTOMER_ID"), orgUnitPath=path.strip("/")),
                absent_on_403=True):
            api_mutate(
                ctx, "delete org unit %s" % path,
                lambda p=path: admin(ctx).orgunits().delete(
                    customerId=ctx.need("CUSTOMER_ID"), orgUnitPath=p.strip("/")),
            )


# --------------------------------------------------------------------------- #
# preflight
# --------------------------------------------------------------------------- #


def test_iam_permissions(ctx: Ctx, url: str, permissions: Sequence[str]) -> List[str]:
    token = access_token(ctx)
    status, payload = http_json(
        ctx, "POST", url, token, {"permissions": list(permissions)}, mutating=False
    )
    if status != 200 or not isinstance(payload, dict):
        return []
    return list(payload.get("permissions", []))


def cmd_preflight(ctx: Ctx) -> int:
    section("preflight")
    blockers: List[str] = []

    say("Tools")
    for tool, why in (
        ("gcloud", "every GCP phase"),
        ("bq", "phases 7, 8 and 11"),
        ("git", "the floor list and image tags"),
    ):
        path = shutil.which(tool)
        say("  %-8s %s" % (tool, path or "MISSING"))
        if not path:
            blockers.append("%s is not on PATH (%s)" % (tool, why))
    say("  python   %s" % sys.version.split()[0])
    if sys.version_info < (3, 9):
        blockers.append("Python 3.9 or newer is required")
    beta = probe(ctx, ["gcloud", "components", "list", "--only-local-state",
                       "--format=value(id)"])
    if beta.ok and "beta" not in beta.out:
        warn("the gcloud beta component is not installed; phase 12 needs it")

    say("")
    say("Config")
    problems = validate_config(ctx.cfg)
    if problems:
        for problem in problems:
            say("  BAD  " + problem)
        blockers.extend(problems)
    else:
        say("  every required key is present and no placeholders remain")

    say("")
    say("Caller")
    account = probe(ctx, ["gcloud", "config", "get-value", "account"])
    active = account.out.strip()
    if active.lower() in ("", "(unset)"):
        say("  gcloud account: none")
        blockers.append("gcloud is not authenticated. Run: gcloud auth login")
        print_manual_steps(ctx)
        section("BLOCKED")
        for blocker in blockers:
            say("  - " + blocker)
        return 1
    say("  gcloud account: %s" % active)
    if ctx.get("OPERATOR_EMAIL") and active.lower() != ctx.get("OPERATOR_EMAIL").lower():
        warn("gcloud is authenticated as %s, not OPERATOR_EMAIL %s"
             % (active, ctx.get("OPERATOR_EMAIL")))
    if PLACEHOLDER_RE.search(ctx.get("ORG_ID", "")) or PLACEHOLDER_RE.search(
            ctx.get("BILLING", "")):
        warn("ORG_ID or BILLING is still a placeholder; skipping the permission checks")
        print_manual_steps(ctx)
        section("BLOCKED")
        for blocker in blockers:
            say("  - " + blocker)
        return 1
    org_url = "https://cloudresourcemanager.googleapis.com/v1/organizations/%s:testIamPermissions" \
        % ctx.get("ORG_ID")
    wanted_org = ["resourcemanager.projects.create", "logging.sinks.create"]
    granted = test_iam_permissions(ctx, org_url, wanted_org)
    for permission in wanted_org:
        held = permission in granted
        say("  org %-38s %s" % (permission, "yes" if held else "NO"))
        if not held:
            blockers.append(
                "you do not hold %s on organisation %s. Phase 11 stalls without "
                "logging.sinks.create: Workspace audit logs land at organisation "
                "level, so a project-level sink cannot see them."
                % (permission, ctx.get("ORG_ID"))
            )
    billing_url = "https://cloudbilling.googleapis.com/v1/billingAccounts/%s:testIamPermissions" \
        % ctx.get("BILLING")
    wanted_billing = ["billing.resourceAssociations.create", "billing.budgets.create"]
    granted_billing = test_iam_permissions(ctx, billing_url, wanted_billing)
    for permission in wanted_billing:
        held = permission in granted_billing
        say("  billing %-34s %s" % (permission, "yes" if held else "NO"))
        if not held:
            blockers.append(
                "you do not hold %s on billing account %s. Billing Account User is "
                "enough to link the project and NOT enough to create the budget, and "
                "the failure lands on the last command of phase 6."
                % (permission, ctx.get("BILLING"))
            )
    cache = ctx.get("OPERATOR_TOKEN_CACHE")
    if cache and os.path.isfile(cache):
        try:
            record = api_get(
                ctx, "users.get self",
                admin(ctx).users().get(userKey=ctx.get("OPERATOR_EMAIL")))
            if record and record.get("isAdmin"):
                say("  Workspace super admin: yes")
            else:
                blockers.append("%s is not a Workspace super admin" % ctx.get("OPERATOR_EMAIL"))
        except WalleError as exc:
            warn("could not check Workspace admin status: %s" % str(exc).splitlines()[0])
    else:
        say("  Workspace super admin: not checked (no operator consent cached yet)")

    print_manual_steps(ctx)

    say("")
    if blockers:
        section("BLOCKED")
        for blocker in blockers:
            say("  - " + blocker)
        return 1
    say("preflight passed. Start with 'walle workspace'.")
    return 0


def cmd_dump_privileges(ctx: Ctx) -> int:
    """Google publishes no complete privilege catalogue and console labels do not
    always match API names. Use this, not the labels, for Eve's read role."""
    catalogue = list_privileges(ctx)
    rows = [[name, service] for name, service in sorted(catalogue.items())]
    say(render_table(rows, ["PRIVILEGE", "SERVICE ID"]))
    say("")
    say("%d privileges. Filter for user/group/report/role when you fix Eve's read" % len(rows))
    say("set in '%s'. (Wall-E's Stage 1 role is retired since 2026-09-13: the" % ROLE_EVE_NAME)
    say("robot holds Super Admin, which no privilege list describes.)")
    return 0


# --------------------------------------------------------------------------- #
# Phase 18 — Stage 0 entry, and per-phase rollback
# --------------------------------------------------------------------------- #


def check_scheduler_states_after_entry(ctx: Ctx) -> int:
    """After Stage 0 entry the invariant INVERTS: every job must read ENABLED."""
    jobs = gcloud_probe_json(
        ctx, "scheduler", "jobs", "list", "--location", ctx.need("REGION")) or []
    bad = [
        "%s=%s" % (j.get("name", "").rsplit("/", 1)[-1], j.get("state"))
        for j in jobs if j.get("state") != "ENABLED"
    ]
    if bad:
        warn("these jobs did not come back ENABLED: %s" % ", ".join(bad))
        return 1
    step("%d scheduler jobs, all ENABLED. Stage 0 evidence collection has begun." % len(jobs))
    return 0


def cmd_stage0(ctx: Ctx) -> int:
    """SETUP.md 6.1's closing block. Resuming a schedule is the deliberate final
    act of the build, and until now there was no command for it."""
    section("Phase 18 — Stage 0 entry")
    if cmd_verify(ctx) != 0:
        die("verify is not clean. Every box in SETUP.md 6.1 must be ticked first.")
    do_manual_step(ctx, "M10")
    confirm(ctx, "Resume every scheduler job? This starts Stage 0 evidence collection.")
    for job in gcloud_probe_json(
        ctx, "scheduler", "jobs", "list", "--location", ctx.need("REGION")
    ) or []:
        name = job.get("name", "").rsplit("/", 1)[-1]
        # walle-gmail-watch-renew is already running; resuming it is a no-op.
        run(ctx, ["gcloud", "scheduler", "jobs", "resume", name,
                  "--location", ctx.need("REGION"), "--project", ctx.need("PROJECT")])
    ctx.print_notes()
    return check_scheduler_states_after_entry(ctx)


def cmd_rollback(ctx: Ctx) -> int:
    """Per-phase rollback. `teardown` is all-or-nothing and is not a substitute.

    SETUP.md gives a rollback for every phase and they are not interchangeable.
    Phase 14's in particular pauses every scheduler job EXCEPT
    walle-gmail-watch-renew, because pausing that one as collateral damage
    produces SETUP.md 7.6 exactly: no T3 runs, no errors, everything looks
    healthy while the watch quietly dies.
    """
    phase = str(getattr(ctx.args, "phase", "") or "")
    section("rollback — phase %s" % (phase or "?"))
    location = ["--location", ctx.need("REGION"), "--project", ctx.need("PROJECT")]
    if phase == "14":
        for job in gcloud_probe_json(
            ctx, "scheduler", "jobs", "list", "--location", ctx.need("REGION")
        ) or []:
            name = job.get("name", "").rsplit("/", 1)[-1]
            if name == WATCH_RENEW_JOB:
                step("leaving %s RUNNING on purpose (SETUP.md 7.6)" % name)
                continue
            run(ctx, ["gcloud", "scheduler", "jobs", "pause", name] + location)
        say("  Then, in the repository:")
        say("    python config/deploy_ladder.py --revert-to=<previous version>")
    elif phase == "9":
        band_b = bool(getattr(ctx.args, "super", False))
        pin_key = "SUPER_REFRESH_TOKEN_VERSION" if band_b else "REFRESH_TOKEN_VERSION"
        token_secret = (SUPER_CLIENT_SECRETS if band_b else NARROW_CLIENT_SECRETS)[1]
        version = ctx.need(pin_key)
        say("  FIRST, as the robot in the clean profile, revoke the app at")
        say("  https://myaccount.google.com/permissions. The grant survives this.")
        confirm(ctx, "Destroy %s version %s?" % (token_secret, version))
        run(ctx, ["gcloud", "secrets", "versions", "destroy", version,
                  "--secret", token_secret, "--location", ctx.need("REGION"),
                  "--project", ctx.need("PROJECT"), "--quiet"])
        say("  Now delete the OAuth client in the console and remove it from API")
        say("  controls. Never reuse it: more than 100 live tokens for one client")
        say("  makes Google invalidate the oldest silently. A re-run produces a")
        say("  HIGHER version: re-export %s and redeploy" % pin_key)
        say("  %s, or the service stays pinned to what you just destroyed."
            % (SUPER_SERVICE if band_b else ACTIONS_SERVICE))
    elif phase == "2":
        # The account is left intact: Phase 2's rollback is the ASSIGNMENT only:
        # Eve's, and any assignment of a retired Wall-E role (2026-09-13). The
        # robot's Super Admin is never rolled back by this script; that is K6.
        for title in RETIRED_WALLE_ROLE_NAMES + (ROLE_EVE_NAME,):
            role = find_role(ctx, title)
            if not role:
                continue
            for assignment in list_role_assignments(ctx, role["roleId"]):
                api_mutate(
                    ctx,
                    "delete role assignment %s (%s)"
                    % (assignment["roleAssignmentId"], title),
                    lambda a=assignment: admin(ctx).roleAssignments().delete(
                        customer=ctx.need("CUSTOMER_ID"),
                        roleAssignmentId=a["roleAssignmentId"],
                    ),
                )
        say("  The roles and the accounts are left in place: the assignment is the")
        say("  single act that grants anything. Super Admin on the robot is untouched:")
        say("  removing it is K6, by a human super admin.")
    elif phase in ("10", "11"):
        services = (("walle-actions", SUPER_SERVICE) if phase == "10"
                    else ("walle-dispatcher",))
        for service in services:
            if current_service_url(ctx, service):
                confirm(ctx, "Delete Cloud Run service %s?" % service)
                run(ctx, ["gcloud", "run", "services", "delete", service,
                          "--region", ctx.need("REGION"), "--quiet",
                          "--project", ctx.need("PROJECT")])
        if phase == "11":
            for sink in ("walle-workspace-audit", "walle-audit-bq"):
                if gcloud_probe_json(ctx, "logging", "sinks", "describe", sink,
                                     "--organization", ctx.need("ORG_ID")) is not None:
                    run(ctx, ["gcloud", "logging", "sinks", "delete", sink,
                              "--organization", ctx.need("ORG_ID"), "--quiet"])
    elif phase == "12":
        for engine in list_engines(ctx):
            if engine.get("displayName") != ctx.get("ENGINE_DISPLAY_NAME"):
                continue
            name = str(engine.get("name", ""))
            confirm(ctx, "Delete reasoning engine %s?" % name)
            status, body = http_json(
                ctx, "DELETE", aiplatform_url(ctx, name), access_token(ctx))
            if status not in (200, 202):
                die("deleting %s returned HTTP %s: %s" % (name, status, str(body)[:200]))
        say("  A production engine cannot change identity in place: recreating it")
        say("  produces a NEW principal, and every resource-level binding on the old")
        say("  one dies with it. Treat a recreate as an identity change under the IAM")
        say("  change checklist (SETUP.md Phase 12b rollback).")
    elif phase == "12b":
        # SETUP.md Phase 12b rollback: the throwaway spike engine and its binding.
        rollback_spike(ctx)
    else:
        die("rollback takes a phase: 2, 9, 10, 11, 12, 12b or 14")
    ctx.print_notes()
    return 0


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #

COMMANDS: Dict[str, Tuple[str, Callable[[Ctx], int]]] = {
    "preflight": ("tools, permissions, config, and the manual step list", cmd_preflight),
    "workspace": ("phases 1 and 2: OUs, robots, groups, sandbox, floor list, Eve's role; "
                  "M2C (the Super Admin grant) only at the tier gate", cmd_workspace),
    "gcp": ("phases 6, 7 and 8: project, data, secrets, and the cross-project reader "
            "grants for Eve and Mo", cmd_gcp),
    "consent": ("phase 9: the robot's OAuth bootstraps, client 1 and (--super) client 2 "
                "(Eve's is Eve's runbook)", cmd_consent),
    "deploy": ("phases 10, 11, 12, 12b and 14: services, sinks, agent + identity, ladder, schedulers", cmd_deploy),
    "spike": ("phase 12b step 3: the Agent Identity spike on a throwaway engine", cmd_spike),
    "armor": ("phase 12c: Model Armor templates, ingress gateway, floor (inspect-only)", cmd_armor),
    "register": ("phase 13: Gemini Enterprise registration and sharing", cmd_register),
    "registry": ("phase 13b: Agent Registry roles, egress gateway in dry-run", cmd_registry),
    "triggers": ("phase 16: Gmail watch and its daily renewal", cmd_triggers),
    "verify": ("every security invariant, asserted", cmd_verify),
    "denials": ("phase 17: the denial suite against the deployed service", cmd_denials),
    "stage0": ("phase 18: verify, attest M10, then resume every schedule", cmd_stage0),
    "status": ("the current state of every resource", cmd_status),
    "rollback": ("undo ONE phase: --phase 2, 9, 10, 11, 12 or 14", cmd_rollback),
    "teardown": ("delete what this script created (confirmation gated)", cmd_teardown),
    "dump-privileges": ("print the tenant's real privilege names", cmd_dump_privileges),
}


def _add_global_flags(parser: argparse.ArgumentParser) -> None:
    """The same four flags, on the top-level parser and on every subparser.

    argparse puts options before the subcommand only. A runbook reader types
    `walle gcp --config X --yes` at least as often as `walle --config X --yes
    gcp`, and the first used to die with "unrecognized arguments" — a usability
    trap in a tool whose whole job is to be followed step by step. Registering
    the flags in both places makes either order work. SUPPRESS defaults matter:
    without them the subparser's default would overwrite a value the top-level
    parser had already set.
    """
    parser.add_argument("--dry-run", action="store_true", default=argparse.SUPPRESS,
                        help="print every command and API call, change nothing")
    parser.add_argument("--yes", action="store_true", default=argparse.SUPPRESS,
                        help="skip confirmations on writes this script makes; it "
                             "never attests a manual console step")
    parser.add_argument("--config", default=argparse.SUPPRESS,
                        help="path to the env file (default ~/.walle-env)")
    parser.add_argument("--verbose", action="store_true", default=argparse.SUPPRESS)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="walle",
        description="Stand up Wall-E to Stage 0, following platform/wall-e/SETUP.md.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Subcommands:\n"
        + "\n".join("  %-16s %s" % (name, help_text)
                    for name, (help_text, _fn) in COMMANDS.items())
        + "\n\nThe global flags work before OR after the subcommand.",
    )
    _add_global_flags(parser)
    parser.set_defaults(dry_run=False, yes=False, config=None, verbose=False)
    subparsers = parser.add_subparsers(dest="command", metavar="SUBCOMMAND")
    for name, (help_text, _fn) in COMMANDS.items():
        sub = subparsers.add_parser(name, help=help_text)
        _add_global_flags(sub)
        if name == "rollback":
            sub.add_argument("--phase", required=True,
                             choices=("2", "9", "10", "11", "12", "12b", "14"),
                             help="which phase's rollback to run (12b: the spike engine)")
            sub.add_argument("--super", action="store_true",
                             help="with --phase 9: act on client 2 (the band-B pair)")
        if name == "armor":
            sub.add_argument("--enforce", action="store_true",
                             help="the blocking flips (Stage 1): refused unless "
                                  "MODEL_ARMOR_ENFORCE_DECISION names an existing file")
        if name == "registry":
            sub.add_argument("--card", metavar="PATH",
                             help="register the hand-written agent card; refused while "
                                  "a supportedInterfaces url is still 'tbd'")
        if name == "triggers":
            sub.add_argument("--drill-watch-alert", action="store_true",
                             help="Phase 16 verify step 3: pause the renewal on "
                                  "purpose and prove the ABSENCE condition fires")
        if name == "consent":
            sub.add_argument("--rotate", action="store_true",
                             help="re-bootstrap: allow a SECOND refresh-token "
                                  "version after the old grant has been revoked")
            sub.add_argument("--eve", action="store_true",
                             help="REFUSED: Eve's consent lives in EVE_PROJECT and is "
                                  "Eve's runbook (eve/07-build-runbook.md Phase 9)")
            sub.add_argument("--store-client", metavar="PATH",
                             help="store this downloaded client JSON, then shred it")
            sub.add_argument("--paste", action="store_true",
                             help="consent on another machine: paste the redirect URL back")
            sub.add_argument("--super", action="store_true",
                             help="client 2, the broad band-B client read by "
                                  "walle-actions-super; refused unless SUPER_SCOPES_DECISION "
                                  "names the signed scope record; cloud-platform never")
        if name == "deploy":
            sub.add_argument("--skip-build", action="store_true",
                             help="reuse the images already in Artifact Registry")
            sub.add_argument("--skip-deny-policy", action="store_true",
                             help="phase 12b step 7: do not create the deny policy "
                                  "(escape hatch while its permission names are "
                                  "being verified against the supported list)")
        if name == "verify":
            sub.add_argument("--strict", action="store_true",
                             help="treat checks that could not run as failures")
        if name == "teardown":
            sub.add_argument("--include-workspace", action="store_true",
                             help="also delete the Workspace objects this script created")
            sub.add_argument("--delete-project", action="store_true",
                             help="delete the GCP project: the id can never be reused")
            # --destroy-key-versions is gone: Eve's key is in EVE_PROJECT and
            # is Eve's owner's to destroy, never Wall-E's teardown's.
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(list(argv) if argv is not None else None)
    if not args.command:
        parser.print_help()
        return 2
    try:
        cfg = derive_config(load_config(find_config_path(args.config)))
        ctx = Ctx(cfg, args)
        if args.command != "preflight":
            # Scoped to the keys this subcommand uses. All-or-nothing validation
            # made `walle gcp` refuse over OPERATOR_OAUTH_CLIENT_FILE and
            # SANDBOX_ACCOUNTS, which it never touches, and the operator has no
            # way to know that from the message.
            problems = validate_config(cfg, args.command)
            if problems:
                say("Refusing to run '%s': the config is not ready for it."
                    % args.command)
                for problem in problems:
                    say("  - " + problem)
                say("")
                say("Only the keys '%s' uses are checked. Run 'walle preflight' for"
                    % args.command)
                say("the full picture across every subcommand.")
                return 2
        if ctx.dry_run:
            section("DRY RUN — read-only probes only; nothing will be changed")
        _help, function = COMMANDS[args.command]
        return function(ctx)
    except WalleError as exc:
        say("")
        warn("STOPPED: %s" % exc)
        return 1
    except KeyboardInterrupt:
        say("")
        warn("interrupted. Re-run the same subcommand: every step is get-or-create.")
        return 130


if __name__ == "__main__":
    sys.exit(main())
