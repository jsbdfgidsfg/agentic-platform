#!/usr/bin/env python3
"""Stand up Wall-E to Stage 0, as far as a script honestly can.

This implements platform/wall-e/SETUP.md, the 18-phase runbook. SETUP.md is the
authoritative source: where ARCHITECTURE.md or the design set disagrees with it,
this script follows SETUP.md and the disagreement is recorded in README.md.

Five things in the runbook cannot be automated, or must not be. Each of them
prints an exact ordered instruction block, blocks until the operator confirms,
and is verified afterwards wherever an API can see the result:

  Phase 3   security key registration, then 2SV enforcement, then the password
  Phase 4   the login reporting rule, under Rules
  Phase 5   "Share data with Google Cloud services"
  Phase 9   the OAuth consent screen and the OAuth client
  Phase 9   the robot's own consent, which is interactive by design

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
    OAuth token, cached 0600 at OPERATOR_TOKEN_CACHE so phases 1, 2 and 15 do
    not re-consent on every run. It is the operator's own super-admin
    credential, it is re-consentable at zero cost, and setting
    OPERATOR_TOKEN_CACHE="" disables the cache entirely.
  - placeholders in the config are a refusal, not a warning
  - --dry-run prints every command and every API call and changes nothing. It
    issues read-only probes only: no subprocess with mutating=True runs, no
    Admin SDK write is attempted, and the checks whose *probe* is itself a
    write (the Workspace users.update probe, the BigQuery DELETE probe) return
    SKIP rather than executing.
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

# SETUP.md Phase 15. Eve never writes to Workspace, at any stage, ever.
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

# The operator's own consent, used by this script for phases 1, 2 and 15 and by
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
    "discoveryengine.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "firestore.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudtasks.googleapis.com",
    "pubsub.googleapis.com",
    "bigquery.googleapis.com",
    "cloudkms.googleapis.com",
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

SERVICE_ACCOUNT_IDS: Tuple[str, ...] = (
    "walle-actions",
    "walle-agent",
    "walle-dispatcher",
    "eve-controller",
    "walle-operators-caller",
)

ACTIONS_PROJECT_ROLES: Tuple[str, ...] = (
    "roles/datastore.user",
    "roles/pubsub.publisher",
    "roles/cloudtasks.enqueuer",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
)
DISPATCH_PROJECT_ROLES: Tuple[str, ...] = (
    "roles/datastore.user",
    "roles/logging.logWriter",
)
EVE_PROJECT_ROLES: Tuple[str, ...] = ("roles/datastore.viewer",)

WALLE_SECRETS: Tuple[str, ...] = (
    "walle-oauth-client",
    "walle-refresh-token",
    "walle-confirm-hmac",
)
EVE_SECRETS: Tuple[str, ...] = ("eve-oauth-client", "eve-refresh-token")

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

# SETUP.md Phase 10 says "all sixteen environment variables". It lists
# seventeen. The set is what matters, so this script asserts names, not a count,
# and README.md records the discrepancy.
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
    "EVE_KMS_KEY",
    "AUDIT_DATASET",
    "TASKS_QUEUE",
    "EXEC_CALLER_ALLOWLIST",
    "CONTROL_CALLER_ALLOWLIST",
    "INTERNAL_CALLER_ALLOWLIST",
    "AUDIENCE",
)

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
REGISTRY_APIS: Tuple[str, ...] = (
    "agentregistry.googleapis.com",
    "apphub.googleapis.com",
    "iap.googleapis.com",
    "dns.googleapis.com",
    "compute.googleapis.com",
)
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
# skip. Finalise the Stage 1 role from `walle dump-privileges` output.
READER_PRIVILEGE_CANDIDATES: Tuple[Tuple[str, Tuple[str, ...]], ...] = (
    ("users read", ("USERS_RETRIEVE", "USER_READ")),
    ("groups read", ("GROUPS_RETRIEVE", "GROUP_READ")),
    ("org units read", ("ORGANIZATION_UNITS_RETRIEVE",)),
    ("reports audit read", ("SECURITY_REPORTS", "REPORTS_ACCESS", "ADMIN_DASHBOARD")),
    ("reports usage read", ("USAGE_REPORTS", "REPORTS_ACCESS", "ADMIN_DASHBOARD")),
    ("admin roles read", ("ROLE_MANAGEMENT_RETRIEVE", "ROLE_MANAGEMENT")),
)
OPERATOR_PRIVILEGE_CANDIDATES: Tuple[Tuple[str, Tuple[str, ...]], ...] = (
    ("users update", ("USERS_UPDATE", "USER_UPDATE")),
    ("groups update", ("GROUPS_UPDATE", "GROUP_UPDATE")),
    ("license management", ("MANAGE_LICENSES", "LICENSE_MANAGEMENT")),
)
EVE_PRIVILEGE_CANDIDATES = READER_PRIVILEGE_CANDIDATES

# A denylist of write-shaped substrings cannot prove "no write privilege at
# all". Google publishes no complete privilege catalogue (SETUP.md Phase 2
# step 4), and the most dangerous names carry no write-shaped marker at all:
# USERS_ALL, GROUPS_ALL, ORGANIZATION_UNITS_ALL and ADMIN_APIS_ALL are the
# whole-service grants (create, update, delete), SUPER_ADMIN and ROOT_APP_ADMIN
# are total, and USER_SECURITY is password reset and session revocation. So the
# classification is INVERTED: this is the exact set of read privileges Stage 0
# is permitted to hold, and anything not named here counts as a write.
READ_PRIVILEGE_ALLOWLIST: frozenset = frozenset(
    name
    for _family, candidates in READER_PRIVILEGE_CANDIDATES
    for name in candidates
)


def is_write_privilege(name: str) -> bool:
    """True unless this privilege is on the Stage 0 read allowlist.

    Unknown is a write. A privilege this script has never resolved has no
    business in a role it is about to assign to the robot customer-scoped, and
    treating the unknown as harmless is how USERS_ALL passes a denylist.
    """
    return name.strip().upper() not in READ_PRIVILEGE_ALLOWLIST


ROLE_READER_NAME = "Wall-E — Reader"
ROLE_OPERATOR_NAME = "Wall-E — Operator (Stage 1)"
ROLE_EVE_NAME = "Eve — Verifier"

GEMINI_ROUTING_DESCRIPTION = (
    "Answers questions about the Google Workspace directory: users, groups, "
    "organisational units, licences, admin-role holders, sign-in activity and "
    "audit reports. Does not send mail on your behalf, does not change any user "
    "or group, and cannot suspend accounts. For anything outside Workspace "
    "administration, do not route here."
)

REQUIRED_CONFIG_KEYS: Tuple[str, ...] = (
    "DOMAIN",
    "PROJECT",
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
)
_DEPLOY_KEYS: Tuple[str, ...] = (
    "DOMAIN", "PROJECT", "REGION", "BQ_LOCATION", "ORG_ID", "ROBOT",
    "OPERATORS", "READERS", "PROTECTED", "WALLE_REPO", "SVC_OU", "PILOT_OU",
    "SANDBOX_OU",
    # Phase 12b. INGRESS_GATEWAY and AGENT_IDENTITY_SPIKE_RESULT are optional
    # here and are checked at runtime: the first binds the gateway only when
    # set, the second is required only on the SERVICE_ACCOUNT fallback.
    "AGENT_IDENTITY_MODE",
)
# Phase 12c. MODEL_ARMOR_ENFORCE_DECISION is checked only under --enforce.
_ARMOR_KEYS: Tuple[str, ...] = (
    "PROJECT", "REGION", "ORG_ID", "FOLDER_ID", "OPERATORS", "WALLE_REPO",
    "CONTENT_LOG_RETENTION_DAYS",
)
# Phase 13b.
_REGISTRY_KEYS: Tuple[str, ...] = (
    "PROJECT", "REGION", "ORG_ID", "CI_DEPLOYER", "MO_PRINCIPAL", "EGRESS_GATEWAY",
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
    "consent": ("DOMAIN", "PROJECT", "REGION", "ROBOT", "EVE_ROBOT"),
    "deploy": _DEPLOY_KEYS,
    "spike": _SPIKE_KEYS,
    "armor": _ARMOR_KEYS,
    "registry": _REGISTRY_KEYS,
    "register": ("PROJECT", "REGION", "DOMAIN", "READERS", "OPERATORS", "BQ_LOCATION"),
    "triggers": ("PROJECT", "REGION", "ROBOT", "OPERATORS"),
    "verify": REQUIRED_CONFIG_KEYS,
    "denials": ("PROJECT", "REGION", "ORG_ID", "ROBOT", "OPERATORS", "SANDBOX_ACCOUNTS"),
    "stage0": REQUIRED_CONFIG_KEYS,
    "rollback": ("PROJECT", "REGION", "CUSTOMER_ID", "OPERATOR_OAUTH_CLIENT_FILE"),
    "status": ("PROJECT", "REGION"),
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
    "SVC_OU", "PILOT_OU", "SANDBOX_OU", "SA_ACTIONS", "SA_AGENT", "SA_DISPATCH",
    "SA_EVE", "SA_OPS_CALLER", "AUDIT_DATASET", "LOGS_DATASET", "TASKS_QUEUE",
    "KMS_KEYRING", "KMS_KEY", "PROJECT", "REGION",
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
    cfg.setdefault("SA_AGENT", "walle-agent@%s.iam.gserviceaccount.com" % project)
    cfg.setdefault("SA_DISPATCH", "walle-dispatcher@%s.iam.gserviceaccount.com" % project)
    cfg.setdefault("SA_EVE", "eve-controller@%s.iam.gserviceaccount.com" % project)
    cfg.setdefault(
        "SA_OPS_CALLER", "walle-operators-caller@%s.iam.gserviceaccount.com" % project
    )
    cfg.setdefault("AR_REPO", "%s-docker.pkg.dev/%s/walle" % (region, project))
    cfg.setdefault("STAGING_BUCKET", "gs://%s-agent-staging" % project)
    cfg.setdefault("KMS_KEYRING", "walle")
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
    ci = cfg.get("CI_DEPLOYER", "")
    if ci and "CI_DEPLOYER" in required and "@" not in ci:
        problems.append("CI_DEPLOYER must be a service account email, not %r" % ci)
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
                "Enforcement: ON. Methods: security key only. No 'allow codes'.",
                "Same OU: less secure app access OFF; Google session control short, "
                "no 'remember this device'; login challenges at the strictest setting.",
                "Confirm %s is NOT a super admin." % c("ROBOT", ""),
                "Sign out, sign back in, and confirm you are forced through the key. "
                "If a code fallback is offered, enforcement is wrong for this OU.",
                "Repeat the sign-out check for %s." % c("EVE_ROBOT", ""),
            ],
            verifier="verify_2sv_enforced",
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
            "The consent screen and the robot's OAuth client",
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
                "For Eve (Phase 15) create a SEPARATE desktop client. Never reuse the "
                "robot's: more than 100 live tokens for one client makes Google "
                "invalidate the oldest silently.",
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
            "super admin, and the grant is then stored against your account with none "
            "of the role constraints. SETUP.md 7.1.",
            [
                "Have ready: the clean browser profile signed into nothing, the vault "
                "password for the robot, and the hardware key from the safe.",
                "This script prints a URL and waits. Copy it BY HAND into the clean "
                "profile. Do not click it, do not let a terminal open it.",
                "Complete the consent as the robot account.",
                "The script checks, through userinfo, that the account that consented "
                "really is the robot, and refuses to store the token otherwise.",
                "Write down the secret VERSION NUMBER it prints. It is 1 only on a "
                "first clean bootstrap. Export it as REFRESH_TOKEN_VERSION and put it "
                "in the config before deploying.",
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
                "Gemini Enterprise console -> your app -> Agents -> Add agent",
                "-> Custom agent via Agent Runtime.",
                "Display name: Wall-E",
                "Resource path: projects/%s/locations/%s/reasoningEngines/%s"
                % (c("PROJECT", ""), c("REGION", ""), c("ENGINE_ID", "<engine-id>")),
                "Description (this is a ROUTING PROMPT, not documentation; paste it "
                "exactly): " + GEMINI_ROUTING_DESCRIPTION,
                "Do NOT attach a data store. Wall-E's data comes from the action "
                "service, live. A data store is a second, stale, unaudited source.",
                "User permissions tab -> share with %s ONLY." % c("OPERATORS", ""),
                "Do not share with %s yet: that is a separate deliberate act."
                % c("READERS", ""),
                "Re-confirm the app's location matches what D8 recorded. A 'us' app "
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
            # this OU. An account outside it would go on to receive the
            # customer-scoped reader role in phase_2_roles with none of that
            # hardening applied. check_robot_hardening catches it, but only
            # after the role has been granted.
            die(
                "%s is in %s, not %s. Every Phase 3 hardening control is scoped to "
                "%s, so this account would hold the reader role with no 2SV "
                "enforcement, no session limit and no login challenges. Move it in "
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
                "READER_PRIVILEGE_CANDIDATES. SETUP.md Phase 2 step 4 warns that "
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

    phase_2_roles assigns whatever comes back from here to the robot,
    customer-scoped. The privilege set is the Workspace-side enforcement point,
    the one that still stands after every control in the action service has
    failed (SETUP.md Phase 2). A role somebody widened by hand, or an earlier
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
    result reads as success.
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


def phase_2_roles(ctx: Ctx) -> None:
    section("Phase 2 — the two custom admin roles")
    say(
        "  A customer-scoped read role, assigned now, and a separate OU-scoped write "
        "role, created now and assigned to nobody. Groups and Reports privileges "
        "cannot be OU-scoped, and Stage 0's whole value is tenant-wide reads."
    )
    catalogue = list_privileges(ctx)
    say("  %d privilege names in this tenant's catalogue." % len(catalogue))

    reader_privs = resolve_privileges(ctx, catalogue, READER_PRIVILEGE_CANDIDATES)
    for entry in reader_privs:
        name = entry["privilegeName"]
        if is_write_privilege(name):
            die(
                "resolved '%s' into the READ role, and it looks like a write "
                "privilege. Stage 0's role must contain no write privilege at all." % name
            )
    reader = ensure_role(
        ctx, ROLE_READER_NAME,
        "Stage 0. Tenant-wide reads only. No write privilege, no License Management.",
        reader_privs,
    )
    robot = api_get(
        ctx, "users.get robot", admin(ctx).users().get(userKey=ctx.need("ROBOT"))
    )
    if not robot:
        if not ctx.dry_run:
            die("robot account %s does not exist; run the earlier phases" % ctx.need("ROBOT"))
        robot = {"id": "DRYRUN"}
    ensure_role_assignment(ctx, reader["roleId"], robot["id"], "CUSTOMER")

    operator_privs = resolve_privileges(ctx, catalogue, OPERATOR_PRIVILEGE_CANDIDATES)
    ensure_role(
        ctx, ROLE_OPERATOR_NAME,
        "Stage 1 ONLY. Assigned to nobody until a dated decision record says so.",
        operator_privs,
    )
    say("")
    say(
        "  '%s' is created and assigned to NOBODY. Creating a role grants nothing; "
        "only an assignment does, and that assignment is the single act that makes "
        "any Workspace write possible." % ROLE_OPERATOR_NAME
    )
    eve_privs = resolve_privileges(ctx, catalogue, EVE_PRIVILEGE_CANDIDATES)
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
        "  Do not trust console labels: run 'walle dump-privileges' once the robot "
        "has a credential and finalise the Stage 1 role from the real API names."
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
        run(
            ctx,
            ["gcloud", "projects", "create", project, "--organization", ctx.need("ORG_ID")],
        )
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
    for role in DISPATCH_PROJECT_ROLES:
        ensure_project_binding(ctx, "serviceAccount:" + ctx.need("SA_DISPATCH"), role)
    for role in EVE_PROJECT_ROLES:
        ensure_project_binding(ctx, "serviceAccount:" + ctx.need("SA_EVE"), role)
    say("  walle-agent@ gets nothing here, and that is the point.")

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
    section("Phase 7 — Firestore, BigQuery, Pub/Sub, Cloud Tasks")
    ensure_firestore(ctx)
    ensure_datasets(ctx)
    ensure_audit_tables(ctx)
    ensure_topics(ctx)
    ensure_tasks_queue(ctx)


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
    section("Phase 8 — KMS asymmetric key, regional secrets, insert-only audit role")
    ensure_kms(ctx)
    ensure_secrets(ctx)
    ensure_confirm_hmac(ctx)
    ensure_audit_writer_role(ctx)


def ensure_kms(ctx: Ctx) -> None:
    """Asymmetric, and this is not a preference.

    For "Eve approved this" to mean anything the action service must be able to
    verify a signature and unable to produce one. A shared symmetric secret
    cannot express that (attack A2).
    """
    region, ring, key = ctx.need("REGION"), ctx.get("KMS_KEYRING"), ctx.get("KMS_KEY")
    if gcloud_probe_json(ctx, "kms", "keyrings", "describe", ring, "--location", region) is None:
        run(ctx, ["gcloud", "kms", "keyrings", "create", ring, "--location", region,
                  "--project", ctx.need("PROJECT")])
    else:
        step("key ring exists: %s" % ring)
    described = gcloud_probe_json(
        ctx, "kms", "keys", "describe", key, "--keyring", ring, "--location", region
    )
    if described is None:
        run(
            ctx,
            [
                "gcloud", "kms", "keys", "create", key,
                "--keyring", ring, "--location", region,
                "--purpose", "asymmetric-signing",
                "--default-algorithm", "ec-sign-p256-sha256",
                "--project", ctx.need("PROJECT"),
            ],
        )
    else:
        purpose = described.get("purpose")
        algorithm = described.get("versionTemplate", {}).get("algorithm")
        step("key exists: %s (%s / %s)" % (key, purpose, algorithm))
        if purpose != "ASYMMETRIC_SIGN" or algorithm != "EC_SIGN_P256_SHA256":
            die(
                "key %s is %s/%s, not ASYMMETRIC_SIGN/EC_SIGN_P256_SHA256. A key's "
                "purpose cannot be changed: create a new key." % (key, purpose, algorithm)
            )
    for member, role in (
        ("serviceAccount:" + ctx.need("SA_EVE"), "roles/cloudkms.signer"),
        ("serviceAccount:" + ctx.need("SA_ACTIONS"), "roles/cloudkms.publicKeyViewer"),
    ):
        run(
            ctx,
            [
                "gcloud", "kms", "keys", "add-iam-policy-binding", key,
                "--keyring", ring, "--location", region,
                "--member", member, "--role", role,
                "--project", ctx.need("PROJECT"),
            ],
        )


def secret_exists(ctx: Ctx, name: str) -> bool:
    return gcloud_probe_json(
        ctx, "secrets", "describe", name, "--location", ctx.need("REGION")
    ) is not None


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
        run(
            ctx,
            [
                "gcloud", "secrets", "add-iam-policy-binding", name,
                "--location", ctx.need("REGION"),
                "--member", "serviceAccount:" + ctx.need("SA_ACTIONS"),
                "--role", "roles/secretmanager.secretAccessor",
                "--project", ctx.need("PROJECT"),
            ],
        )
    say(
        "  walle-agent@ appears nowhere in that loop and must never be added: the "
        "credential does not exist in the model's process or context, so no prompt "
        "and no tool can exfiltrate it. That absence is trust boundary 3."
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


def add_dataset_access(ctx: Ctx, dataset: str, role: str, member_email: str) -> None:
    """bq add-iam-policy-binding works on tables, views and connections only.

    Dataset access lives in the dataset's own access array: read it, append, and
    write it back. Idempotent because the entry is compared first.
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
    say("  DATASET ACCESS: %s gains %s on %s" % (member_email, role, dataset))
    if ctx.dry_run:
        return
    confirm(ctx, "Apply this dataset access change?")
    handle = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8")
    try:
        json.dump(payload, handle)
        handle.close()
        run(ctx, ["bq", "update", "--source=%s" % handle.name, target])
    finally:
        os.unlink(handle.name)


def cmd_gcp(ctx: Ctx) -> int:
    phase_6_project(ctx)
    phase_7_data(ctx)
    phase_8_keys_and_secrets(ctx)
    ctx.print_notes()
    say("")
    say("Phases 6, 7 and 8 done. Next: 'walle consent' (phase 9).")
    return 0


# --------------------------------------------------------------------------- #
# Phase 9 and 15 — the one interactive consent
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
    _Request, _Credentials, InstalledAppFlow, build = _import_google()
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
    say("  PUT THIS IN THE CONFIG NOW:")
    if target_secret == "walle-refresh-token":
        say("    REFRESH_TOKEN_VERSION=%s" % version)
        say("  and redeploy walle-actions. It is 1 only on a first clean bootstrap;")
        say("  every rollback and every K4 or K5 drill produces a higher number, and")
        say("  a stale pin points the service at a destroyed version.")
    else:
        say("    EVE_TOKEN_VERSION=%s" % version)
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
    section("Phases 9 and 15 — the one interactive consent")
    eve = bool(getattr(ctx.args, "eve", False))
    client_secret = "eve-oauth-client" if eve else "walle-oauth-client"
    target_secret = "eve-refresh-token" if eve else "walle-refresh-token"
    account = ctx.need("EVE_ROBOT") if eve else ctx.need("ROBOT")
    scopes = EVE_SCOPES if eve else ROBOT_SCOPES

    if eve:
        ensure_eve_secrets(ctx)
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
            "as REFRESH_TOKEN_VERSION and walle-actions redeployed, or the service "
            "stays pinned to the version you just destroyed."
            % (target_secret, len(existing_versions), account)
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
    if not eve and not ctx.dry_run:
        say("")
        say("  While the credential is in hand, close the two Phase 9 items that are")
        say("  cheap only right now and expensive later:")
        say("   1. walle dump-privileges > privileges.txt")
        say("      Finalise '%s' from these API names, not console" % ROLE_OPERATOR_NAME)
        say("      labels: Google publishes no complete privilege catalogue.")
        say("   2. python bootstrap/verify_token.py --project=%s --region=%s \\"
            % (ctx.need("PROJECT"), ctx.need("REGION")))
        say("        --secret=walle-refresh-token --secret-version=<the number above> \\")
        say("        --expect-account=%s \\" % ctx.need("ROBOT"))
        say("        --probe=licensing.licenseAssignments.listForProduct")
        say("      Expect 403: License Management is indivisible and waits for")
        say("      Stage 1. If it returns ROWS, the Phase 2 role carries a privilege")
        say("      it should not, and that is a finding, not a convenience.")
        ctx.note(
            "Phase 9: record the licence probe result against 09-open-decisions "
            "'still to verify' item 1."
        )
    ctx.print_notes()
    return 0


def ensure_eve_secrets(ctx: Ctx) -> None:
    """Eve's secrets are readable by eve-controller@ only.

    walle-actions@ must not appear here and eve-controller@ must not appear in
    Phase 8's loop. If they shared a credential, "Eve approved this" and "Eve
    verified this" would both mean nothing.
    """
    for name in EVE_SECRETS:
        if secret_exists(ctx, name):
            step("secret exists: %s" % name)
        else:
            run(ctx, ["gcloud", "secrets", "create", name,
                      "--location", ctx.need("REGION"), "--project", ctx.need("PROJECT")])
        run(
            ctx,
            [
                "gcloud", "secrets", "add-iam-policy-binding", name,
                "--location", ctx.need("REGION"),
                "--member", "serviceAccount:" + ctx.need("SA_EVE"),
                "--role", "roles/secretmanager.secretAccessor",
                "--project", ctx.need("PROJECT"),
            ],
        )


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
        (
            "EVE_KMS_KEY",
            "projects/%s/locations/%s/keyRings/%s/cryptoKeys/%s"
            % (project, region, ctx.get("KMS_KEYRING"), ctx.get("KMS_KEY")),
        ),
        ("AUDIT_DATASET", ctx.get("AUDIT_DATASET")),
        (
            "TASKS_QUEUE",
            "projects/%s/locations/%s/queues/%s" % (project, region, ctx.get("TASKS_QUEUE")),
        ),
        ("EXEC_CALLER_ALLOWLIST", ctx.need("SA_AGENT")),
        # Eve alone would mean no human can halt or demote, and every kill-switch
        # timing in section 5 becomes unmeasurable.
        ("CONTROL_CALLER_ALLOWLIST", "%s,%s" % (ctx.need("SA_EVE"), ctx.need("OPERATORS"))),
        ("INTERNAL_CALLER_ALLOWLIST", ctx.need("SA_DISPATCH")),
        ("AUDIENCE", audience),
    ]


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
    for member in (
        "serviceAccount:" + ctx.need("SA_AGENT"),
        "serviceAccount:" + ctx.need("SA_DISPATCH"),
        "serviceAccount:" + ctx.need("SA_EVE"),
        "serviceAccount:" + ctx.need("SA_ACTIONS"),
        "serviceAccount:" + ctx.need("SA_OPS_CALLER"),
        # Without this the andon cord has no handle a human can pull.
        "group:" + ctx.need("OPERATORS"),
    ):
        ensure_run_invoker(ctx, "walle-actions", member)
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


def ensure_run_invoker(ctx: Ctx, service: str, member: str) -> None:
    policy = gcloud_probe_json(
        ctx, "run", "services", "get-iam-policy", service, "--region", ctx.need("REGION")
    ) or {}
    for binding in policy.get("bindings", []):
        if binding.get("role") == "roles/run.invoker" and member in binding.get("members", []):
            step("run.invoker present on %s: %s" % (service, member))
            return
    run(
        ctx,
        [
            "gcloud", "run", "services", "add-iam-policy-binding", service,
            "--region", ctx.need("REGION"),
            "--member", member, "--role", "roles/run.invoker",
            "--project", ctx.need("PROJECT"),
        ],
    )


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


def lock_engine_iam(ctx: Ctx) -> None:
    """Three principals and no others, ever.

    Gemini Enterprise passes the signed-in user's email as user_id. That email is
    asserted by the calling service, not cryptographically bound to the user, and
    is trustworthy exactly to the extent that only trusted callers can invoke.
    """
    project, number = ctx.need("PROJECT"), project_number(ctx)
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
    policy = {
        "bindings": [
            {
                "role": "projects/%s/roles/walleEngineQuery" % project,
                "members": [
                    "serviceAccount:service-%s@gcp-sa-discoveryengine.iam.gserviceaccount.com"
                    % number,
                    "serviceAccount:" + ctx.need("SA_DISPATCH"),
                    "serviceAccount:" + ctx.need("SA_EVE"),
                ],
            }
        ]
    }
    say("  engine IAM policy -> exactly three members:")
    for member in policy["bindings"][0]["members"]:
        say("    " + member)
    url = aiplatform_url(
        ctx, "%s/%s:setIamPolicy" % (engine_collection_path(ctx), engine_id)
    )
    if ctx.dry_run:
        say("  WOULD POST %s" % url)
        say("    body: %s" % json.dumps({"policy": policy}))
        return
    confirm(ctx, "Apply this engine IAM policy?")
    status, body = http_json(ctx, "POST", url, access_token(ctx), {"policy": policy})
    if status != 200:
        die(
            "setIamPolicy on engine %s returned HTTP %s: %s\n"
            "Without this the engine keeps whatever the project policy grants, and "
            "the asserted end-user email from Gemini Enterprise means nothing."
            % (engine_id, status, str(body)[:300])
        )
    say(
        "  Confirm the Discovery Engine service agent's exact address on the IAM "
        "page with 'Include Google-provided role grants' on: it is created lazily "
        "when the Gemini Enterprise app first runs."
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
            "GEMINI_APP_ID is not set. D8 closes this before Phase 6: Gemini "
            "Enterprise console -> app -> settings. A 'us' app cannot front a "
            "europe-west1 agent."
        )
    host = "discoveryengine.googleapis.com"
    if location != "global":
        host = "%s-discoveryengine.googleapis.com" % location
    engine_url = (
        "https://%s/v1/projects/%s/locations/%s/collections/default_collection/engines/%s"
        % (host, ctx.need("PROJECT"), location, app_id)
    )
    status, payload = http_json(ctx, "GET", engine_url, access_token(ctx))
    if status == 200 and isinstance(payload, dict):
        say("  Gemini Enterprise app found: %s" % payload.get("displayName", app_id))
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
    url = (
        "https://%s/v1alpha/projects/%s/locations/%s/collections/default_collection/"
        "engines/%s/assistants/default_assistant/agents"
        % (host, ctx.need("PROJECT"), location, app_id)
    )
    status, payload = http_json(ctx, "GET", url, access_token(ctx))
    if status != 200 or not isinstance(payload, dict):
        return "SKIP", "v1alpha agents listing not available (HTTP %s); confirm by eye" % status
    blob = json.dumps(payload)
    if engine_id in blob:
        return "PASS", "engine %s is registered on app %s" % (engine_id, app_id)
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
    say("  step 7: floor settings, conformance at the folder %s, inline on the project"
        % ctx.need("FOLDER_ID"))
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
    ci_member = iam_member(ctx.need("CI_DEPLOYER"))
    mo_member = iam_member(ctx.need("MO_PRINCIPAL"))
    eve_member = "serviceAccount:" + ctx.need("SA_EVE")
    gateway = ctx.get("EGRESS_GATEWAY") or EGRESS_GATEWAY_NAME
    say("  Registry admin to the CI deployer only, viewer to Eve and Mo. The egress")
    say("  gateway is a default-deny hostname allowlist for the reasoning layer, and it")
    say("  starts in DRY_RUN: two undocumented questions gate it to enforced.")
    say("    admin   %s" % ci_member)
    say("    viewer  %s" % eve_member)
    say("    viewer  %s" % mo_member)
    say("    gateway %s" % gateway)
    confirm(ctx, "Proceed with the registry and egress gateway setup?")
    ensure_apis_listed(ctx, REGISTRY_APIS, "Agent Registry")

    say("")
    say("  step 1: roles. Nobody else: an editor can redirect every consumer that")
    say("  resolves Wall-E through the registry and flip the tool annotations gateway")
    say("  rules read.")
    ensure_project_binding(ctx, ci_member, "roles/agentregistry.admin")
    ensure_project_binding(ctx, eve_member, "roles/agentregistry.viewer")
    ensure_project_binding(ctx, mo_member, "roles/agentregistry.viewer")

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
    for secret in list(WALLE_SECRETS) + list(EVE_SECRETS):
        if not secret_exists(ctx, secret):
            continue
        policy = gcloud_probe_json(
            ctx, "secrets", "get-iam-policy", secret, "--location", ctx.need("REGION")
        ) or {}
        if _roles_of_member(policy, agent):
            offenders.append(secret)
    key_policy = gcloud_probe_json(
        ctx, "kms", "keys", "get-iam-policy", ctx.get("KMS_KEY"),
        "--keyring", ctx.get("KMS_KEYRING"), "--location", ctx.need("REGION"),
    ) or {}
    if _roles_of_member(key_policy, agent):
        offenders.append("kms:" + ctx.get("KMS_KEY"))
    # A key-level policy does not subtract an inherited one: a binding on the
    # KEY RING is inherited by the key and is invisible to the read above.
    ring_policy = gcloud_probe_json(
        ctx, "kms", "keyrings", "get-iam-policy", ctx.get("KMS_KEYRING"),
        "--location", ctx.need("REGION"),
    ) or {}
    if _roles_of_member(ring_policy, agent):
        offenders.append("kms keyring:" + ctx.get("KMS_KEYRING"))
    project_policy = gcloud_probe_json(ctx, "projects", "get-iam-policy", ctx.need("PROJECT")) or {}
    broad = [
        role for role in _roles_of_member(project_policy, agent)
        if "secretmanager" in role or "cloudkms" in role or role in ("roles/owner", "roles/editor")
    ]
    if broad:
        offenders.append("project roles %s" % broad)
    if offenders:
        return FAIL, "walle-agent@ can reach: %s" % ", ".join(offenders)
    return PASS, "walle-agent@ holds nothing on any secret or on the KMS key"


def check_stage0_role_has_no_write(ctx: Ctx) -> CheckResult:
    """Allowlist first. A denylist over names Google does not publish in full
    cannot prove "no write privilege at all" (SETUP.md Phase 2 step 4)."""
    role = find_role(ctx, ROLE_READER_NAME)
    if not role:
        return FAIL, "role '%s' does not exist" % ROLE_READER_NAME
    names = {p["privilegeName"] for p in role.get("rolePrivileges", [])}
    expected = {
        p["privilegeName"]
        for p in resolve_privileges(ctx, list_privileges(ctx), READER_PRIVILEGE_CANDIDATES)
    }
    unexpected = sorted(names - expected)
    if unexpected:
        return FAIL, (
            "privileges beyond the resolved Stage 0 read set: %s. Whatever they "
            "are called, this role is assigned to the robot customer-scoped."
            % unexpected
        )
    offenders = sorted(n for n in names if is_write_privilege(n))
    if offenders:
        return FAIL, "write privileges in the Stage 0 role: %s" % ", ".join(offenders)
    licence = sorted(n for n in names if "LICEN" in n.upper())
    if licence:
        return FAIL, "License Management is indivisible and must wait for Stage 1: %s" % licence
    return PASS, "%d privileges, exactly the resolved read set" % len(names)


def check_role_assignments(ctx: Ctx) -> CheckResult:
    reader = find_role(ctx, ROLE_READER_NAME)
    writer = find_role(ctx, ROLE_OPERATOR_NAME)
    if not reader or not writer:
        return FAIL, "expected both '%s' and '%s' to exist" % (ROLE_READER_NAME, ROLE_OPERATOR_NAME)
    robot = api_get(ctx, "users.get robot", admin(ctx).users().get(userKey=ctx.need("ROBOT")))
    if not robot:
        return FAIL, "robot account does not exist"
    reader_assignments = [
        a for a in list_role_assignments(ctx, reader["roleId"])
        if a.get("assignedTo") == robot["id"]
    ]
    if len(reader_assignments) != 1:
        return FAIL, "expected one reader assignment on the robot, found %d" % len(reader_assignments)
    scope = reader_assignments[0].get("scopeType")
    if scope != "CUSTOMER":
        return FAIL, (
            "reader role is scoped %s, not CUSTOMER. Under an OU-scoped role the "
            "admin enumeration returns nothing and an empty result reads as success "
            "(attack A7)." % scope
        )
    writer_assignments = list_role_assignments(ctx, writer["roleId"])
    if writer_assignments:
        return FAIL, (
            "'%s' is ASSIGNED to %d principal(s). That is the single act that makes "
            "a Workspace write possible and it needs a Stage 1 decision record."
            % (ROLE_OPERATOR_NAME, len(writer_assignments))
        )
    # "One reader assignment" only means something if it is ALL of them. A
    # second custom or delegated admin role on the robot is invisible to
    # isAdmin, which is the only thing check_robot_hardening tests.
    all_on_robot = [
        a for a in list_role_assignments(ctx) if a.get("assignedTo") == robot["id"]
    ]
    if len(all_on_robot) != 1:
        return FAIL, (
            "the robot holds %d role assignments, expected exactly one (the "
            "customer-scoped reader): roleIds %s"
            % (len(all_on_robot), [a.get("roleId") for a in all_on_robot])
        )
    eve_role = find_role(ctx, ROLE_EVE_NAME)
    if eve_role:
        eve_writes = sorted(
            p["privilegeName"] for p in eve_role.get("rolePrivileges", [])
            if is_write_privilege(p["privilegeName"])
        )
        if eve_writes:
            return FAIL, (
                "'%s' carries write privileges: %s. Eve never acts on Workspace, at "
                "any stage, ever (SETUP.md Phase 15)." % (ROLE_EVE_NAME, eve_writes)
            )
    return PASS, (
        "robot holds exactly one assignment, customer-scoped reader; Stage 1 write "
        "role assigned to nobody; Eve's role is read-only"
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
    return PASS, "3 regional secrets; service pins version %s, no 'latest' anywhere" % version


def check_kms_split(ctx: Ctx) -> CheckResult:
    described = gcloud_probe_json(
        ctx, "kms", "keys", "describe", ctx.get("KMS_KEY"),
        "--keyring", ctx.get("KMS_KEYRING"), "--location", ctx.need("REGION"),
    )
    if described is None:
        return FAIL, "key %s does not exist" % ctx.get("KMS_KEY")
    purpose = described.get("purpose")
    algorithm = described.get("versionTemplate", {}).get("algorithm")
    if purpose != "ASYMMETRIC_SIGN" or algorithm != "EC_SIGN_P256_SHA256":
        return FAIL, "key is %s / %s" % (purpose, algorithm)
    policy = gcloud_probe_json(
        ctx, "kms", "keys", "get-iam-policy", ctx.get("KMS_KEY"),
        "--keyring", ctx.get("KMS_KEYRING"), "--location", ctx.need("REGION"),
    ) or {}
    actions_roles = _roles_of_member(policy, "serviceAccount:" + ctx.need("SA_ACTIONS"))
    eve_roles = _roles_of_member(policy, "serviceAccount:" + ctx.need("SA_EVE"))
    if actions_roles != ["roles/cloudkms.publicKeyViewer"]:
        return FAIL, (
            "walle-actions@ holds %s on Eve's key. It must hold publicKeyViewer and "
            "nothing else, or it can mint an Eve approval (attack A2)." % actions_roles
        )
    if "roles/cloudkms.signer" not in eve_roles:
        return FAIL, "eve-controller@ does not hold cloudkms.signer (%s)" % eve_roles
    # A key-level policy does not subtract an inherited one. roles/cloudkms.signer
    # or cryptoOperator granted on the KEY RING or at PROJECT level is invisible
    # to the read above and puts walle-actions@ straight back in a position to
    # mint an Eve approval — attack A2, alive again, with this check green.
    actions_member = "serviceAccount:" + ctx.need("SA_ACTIONS")
    for label, argv in (
        ("key ring", ("kms", "keyrings", "get-iam-policy", ctx.get("KMS_KEYRING"),
                      "--location", ctx.need("REGION"))),
        ("project", ("projects", "get-iam-policy", ctx.need("PROJECT"))),
    ):
        wider = gcloud_probe_json(ctx, *argv) or {}
        held = [
            r for r in _roles_of_member(wider, actions_member)
            if "cloudkms" in r or r in ("roles/owner", "roles/editor")
        ]
        if held:
            return FAIL, (
                "walle-actions@ holds %s at %s level, which the key inherits. It "
                "could mint an Eve approval and \"Eve approved this\" would mean "
                "nothing (attack A2)." % (held, label)
            )
    return PASS, (
        "ASYMMETRIC_SIGN/EC_SIGN_P256_SHA256; Eve signs, actions verifies only, and "
        "nothing is inherited from the ring or the project"
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


def check_engine_three_principals(ctx: Ctx) -> CheckResult:
    engine_id = resolve_engine_id(ctx)
    if not engine_id:
        return SKIP, "no single reasoning engine to check"
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
    if len(members) != 3:
        return FAIL, "%d principals can query the engine, expected exactly 3: %s" % (
            len(members), members)
    # SETUP.md 6.1 says "counting inherited project and organisation bindings".
    # A resource-level policy does not override an inherited one, and all four
    # roles below confer aiplatform.reasoningEngines.query — roles/editor and
    # roles/owner included, which the old check never looked for. One editor
    # group at project level and an arbitrary number of principals can invoke
    # the agent, which is exactly the property that makes Gemini Enterprise's
    # asserted end-user email trustworthy.
    conferring = (
        "roles/aiplatform.user", "roles/aiplatform.admin",
        "roles/editor", "roles/owner",
    )
    inherited: List[str] = []
    for label, argv in (
        ("project", ("projects", "get-iam-policy", ctx.need("PROJECT"))),
        ("organisation", ("organizations", "get-iam-policy", ctx.need("ORG_ID"))),
    ):
        scope_policy = gcloud_probe_json(ctx, *argv) or {}
        for binding in scope_policy.get("bindings", []):
            if binding.get("role") in conferring:
                inherited += [
                    "%s (%s at %s)" % (m, binding["role"], label)
                    for m in binding.get("members", [])
                ]
    if inherited:
        return FAIL, (
            "the three-principal lock does not hold: these can also query the engine "
            "through an inherited binding: %s" % sorted(set(inherited))
        )
    return PASS, "exactly 3 principals, and no inherited binding confers query"


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
    described = gcloud_probe_json(
        ctx, "run", "services", "describe", "walle-actions", "--region", ctx.need("REGION")
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
        return FAIL, "eve-controller@ is not in CONTROL_CALLER_ALLOWLIST"
    if ctx.need("OPERATORS") not in entries:
        return FAIL, (
            "the operators group is not in CONTROL_CALLER_ALLOWLIST. Eve alone means "
            "NO HUMAN CAN HALT OR DEMOTE and every kill-switch timing is unmeasurable"
        )
    if ctx.need("SA_AGENT") in entries:
        return FAIL, "walle-agent@ is in the control allowlist; that is the whole design gone"
    return PASS, "contains eve-controller@ and %s" % ctx.need("OPERATORS")


def check_cloud_run_requires_auth(ctx: Ctx) -> CheckResult:
    problems = []
    checked = 0
    for service in ("walle-actions", "walle-dispatcher"):
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
    dispatch = set(_roles_of_member(policy, "serviceAccount:" + ctx.need("SA_DISPATCH")))
    if not set(DISPATCH_PROJECT_ROLES) <= dispatch:
        problems.append("walle-dispatcher@ is missing %s" % sorted(set(DISPATCH_PROJECT_ROLES) - dispatch))
    eve = set(_roles_of_member(policy, "serviceAccount:" + ctx.need("SA_EVE")))
    if not set(EVE_PROJECT_ROLES) <= eve:
        problems.append("eve-controller@ is missing %s" % sorted(set(EVE_PROJECT_ROLES) - eve))
    agent = _roles_of_member(policy, "serviceAccount:" + ctx.need("SA_AGENT"))
    if agent:
        problems.append("walle-agent@ holds project roles and must hold none: %s" % agent)
    # SETUP.md Phase 6's verify asks for both halves: the roles, and that all
    # five accounts exist and are enabled. A disabled service account produces
    # a failure that looks nothing like a missing role.
    listed = gcloud_probe_json(ctx, "iam", "service-accounts", "list") or []
    present = {a.get("email"): bool(a.get("disabled", False)) for a in listed}
    for name in SERVICE_ACCOUNT_IDS:
        email = "%s@%s.iam.gserviceaccount.com" % (name, ctx.need("PROJECT"))
        if email not in present:
            problems.append("service account %s is missing" % email)
        elif present[email]:
            problems.append("service account %s is DISABLED" % email)
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, (
        "all %d service accounts exist and are enabled; actions, dispatcher and eve "
        "have their roles; agent holds nothing" % len(SERVICE_ACCOUNT_IDS)
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
    return PASS, "the andon cord has a handle; triggers can reach the dispatcher"


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
    for service in ("walle-actions", "walle-dispatcher"):
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
        if service == "walle-actions" and timeout not in (60, "60"):
            problems.append("walle-actions timeout is %s, not 60s" % timeout)
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
    # hypothetical: if eve-controller@ could read walle-refresh-token, Eve's
    # independence is gone before she is built. Returning SKIP on the first
    # missing Eve secret abandoned it.
    for secret in WALLE_SECRETS:
        if not secret_exists(ctx, secret):
            continue
        policy = gcloud_probe_json(
            ctx, "secrets", "get-iam-policy", secret, "--location", ctx.need("REGION")) or {}
        if _roles_of_member(policy, "serviceAccount:" + ctx.need("SA_EVE")):
            problems.append("eve-controller@ can read %s" % secret)
    eve_present = [s for s in EVE_SECRETS if secret_exists(ctx, s)]
    for secret in eve_present:
        policy = gcloud_probe_json(
            ctx, "secrets", "get-iam-policy", secret, "--location", ctx.need("REGION")) or {}
        if _roles_of_member(policy, "serviceAccount:" + ctx.need("SA_ACTIONS")):
            problems.append("walle-actions@ can read %s" % secret)
    if problems:
        return FAIL, "; ".join(problems)
    if not eve_present:
        return SKIP, (
            "the Wall-E half passes: eve-controller@ can read none of Wall-E's "
            "secrets. Eve's own secrets do not exist yet (Phase 15)."
        )
    return PASS, "eve-controller@ and walle-actions@ share no secret"


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


def check_robot_hardening(ctx: Ctx) -> CheckResult:
    robot = api_get(ctx, "users.get robot", admin(ctx).users().get(
        userKey=ctx.need("ROBOT"), projection="full"))
    if not robot:
        return FAIL, "robot account does not exist"
    problems = []
    if robot.get("isAdmin"):
        problems.append(
            "the robot is a SUPER ADMIN. That is the difference between a contained "
            "incident and a breach"
        )
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
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "not a super admin, no recovery contacts, 2SV enrolled and enforced"


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


def robot_credentials(ctx: Ctx) -> Any:
    """Build the robot's credential from Secret Manager, in memory only.

    Reads the PINNED version, never 'latest', for the same reason the service
    does: latest resolves to the newest enabled version, so disabling the newest
    falls back to the previous, still-valid token.
    """
    _Request, Credentials, _Flow, _build = _import_google()
    version = ctx.get("REFRESH_TOKEN_VERSION")
    if not version:
        env = deployed_actions_env(ctx) or {}
        version = env.get("REFRESH_TOKEN_VERSION", "")
    if not version.isdigit():
        die("REFRESH_TOKEN_VERSION is not a version number: %r" % version)
    client = json.loads(read_secret(ctx, "walle-oauth-client").decode("utf-8"))
    block = client.get("installed") or client.get("web") or {}
    token = read_secret(ctx, "walle-refresh-token", version).decode("utf-8").strip()
    return Credentials(
        token=None,
        refresh_token=token,
        client_id=block.get("client_id"),
        client_secret=block.get("client_secret"),
        token_uri=block.get("token_uri", "https://oauth2.googleapis.com/token"),
        scopes=list(ROBOT_SCOPES),
    )


def check_robot_credential_is_read_only(ctx: Ctx) -> CheckResult:
    """SETUP.md Phase 9's fourth check, the one people skip.

    At Stage 0 the role is read-only, so a write MUST fail at Google's end. If it
    succeeds, the Phase 2 role carries a write privilege it should not and the
    Workspace layer is not the second enforcement point the design claims.
    """
    if not secret_exists(ctx, "walle-refresh-token"):
        return SKIP, "no refresh token yet (phase 9)"
    if ctx.dry_run:
        # This probe is a real Admin SDK write, issued directly rather than
        # through api_mutate, so nothing else would stop it: confirm() returns
        # under --dry-run and the call went straight out. If the Phase 2 role
        # were wrong the write would SUCCEED, and the Phase 18 checklist
        # requires the Workspace admin audit log to show zero rows attributed
        # to the robot apart from the single Phase 17 event — so a dry run had
        # a path to manufacturing the very evidence Stage 0 entry reads as a
        # control failure.
        return SKIP, (
            "--dry-run: the users.update probe is a real Workspace write and a "
            "robot-attributed admin event. Not issued."
        )
    _Request, _Credentials, _Flow, build = _import_google()
    creds = robot_credentials(ctx)
    email = fetch_consented_email(ctx, creds, build)
    if email.lower() != ctx.need("ROBOT").lower():
        return FAIL, (
            "the stored credential belongs to %s, not %s. Destroy that secret "
            "version and re-run the consent (SETUP.md 7.1)." % (email, ctx.need("ROBOT"))
        )
    directory = build("admin", "directory_v1", credentials=creds, cache_discovery=False)
    try:
        directory.users().list(customer=ctx.need("CUSTOMER_ID"), maxResults=1).execute()
    except Exception as exc:
        return FAIL, "users.list as the robot failed: %s" % exc
    targets = [a.strip() for a in ctx.get("SANDBOX_ACCOUNTS").split(",") if a.strip()]
    if not targets:
        return SKIP, "no sandbox account to probe; a real account must never be named"
    target = targets[0]
    record = api_get(ctx, "users.get sandbox", admin(ctx).users().get(userKey=target))
    if not record or record.get("orgUnitPath") != ctx.need("SANDBOX_OU"):
        return SKIP, "%s is not in %s; refusing to probe" % (target, ctx.need("SANDBOX_OU"))
    say("  WORKSPACE WRITE PROBE: users.update on %s, expected to be REFUSED" % target)
    if refuse_in_dry_run(ctx, "users.update probe on %s" % target):
        return SKIP, "--dry-run"
    confirm(ctx, "Attempt the write that must fail?")
    body = {"name": {"givenName": record.get("name", {}).get("givenName", "Wall-E test"),
                     "familyName": record.get("name", {}).get("familyName", "01")}}
    try:
        directory.users().update(userKey=target, body=body).execute()
    except Exception as exc:
        if _http_status(exc) in (403, 401):
            return PASS, "reads succeed, a write on %s is refused 403" % target
        return FAIL, "the write failed for the wrong reason: %s" % exc
    return FAIL, (
        "a users.update as the robot SUCCEEDED on %s. The Stage 0 role carries a "
        "write privilege and the Workspace layer is not enforcing anything." % target
    )


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
        if record.get("isAdmin"):
            problems.append("%s is a super admin" % email)
    if problems:
        return FAIL, "; ".join(problems)
    return PASS, "both robots: 2SV enrolled and enforced, neither is a super admin"


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


CHECKS: Tuple[Tuple[str, str, Callable[[Ctx], CheckResult]], ...] = (
    ("agent_reads_no_secret", "8", check_agent_reads_no_secret),
    ("stage0_role_has_no_write", "2", check_stage0_role_has_no_write),
    ("role_assignments", "2", check_role_assignments),
    ("secrets_regional_and_version_pinned", "8/10", check_secrets_regional_and_pinned),
    ("kms_asymmetric_and_split", "8", check_kms_split),
    ("actions_cannot_delete_bigquery", "8", check_actions_cannot_delete_bigquery),
    ("sink_actor_exclusion", "11", check_sink_filters),
    ("engine_three_principals", "12", check_engine_three_principals),
    ("schedulers_paused_watch_running", "14/16", check_scheduler_states),
    ("ladder_config", "14", check_ladder_config),
    ("actions_env_complete", "10", check_actions_env_complete),
    ("control_caller_allowlist", "10", check_control_caller_allowlist),
    ("cloud_run_requires_auth", "10/11", check_cloud_run_requires_auth),
    ("project_roles", "6", check_project_roles),
    ("run_invoker_handles", "10/11", check_run_invoker_handles),
    ("residency_and_ingress", "6/7/10", check_residency),
    ("audit_tables_partitioned", "7", check_audit_tables),
    ("eve_credential_separation", "8/15", check_eve_separation),
    ("protected_group_covers_floor", "1", check_protected_covers_floor),
    ("robot_hardening", "3", check_robot_hardening),
    ("robot_credential_is_read_only", "9", check_robot_credential_is_read_only),
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
        result = run(
            ctx,
            [
                sys.executable, script, "--actions-url", url,
                "--project", ctx.need("PROJECT"), "--json",
            ],
            check=False,
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
    if not can_agent:
        results.append((7, "walle-agent@ accesses the refresh token", SKIP, why_agent))
    else:
        probe_secret = run(
            ctx,
            [
                "gcloud", "secrets", "versions", "access", "latest",
                "--secret", "walle-refresh-token", "--location", ctx.need("REGION"),
                "--project", ctx.need("PROJECT"),
                # If this test FAILS the payload exists; never let it reach a
                # terminal or a captured log.
                "--out-file", os.devnull,
            ],
            mutating=False, check=False, stdout_is_secret=True,
            env={"CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT": ctx.need("SA_AGENT")},
        )
        results.append((
            7, "walle-agent@ accesses the refresh token",
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
        for title in (ROLE_READER_NAME, ROLE_OPERATOR_NAME, ROLE_EVE_NAME):
            role = find_role(ctx, title)
            assignments = list_role_assignments(ctx, role["roleId"]) if role else []
            add("2", "role %s" % title, bool(role), "%d assignment(s)" % len(assignments))
    except WalleError as exc:
        rows.append(["1/2", "Workspace", "?", str(exc).splitlines()[0][:80]])

    add("6", "project %s" % ctx.get("PROJECT"),
        gcloud_probe_json(ctx, "projects", "describe", ctx.need("PROJECT")) is not None,
        "number %s" % project_number(ctx))
    accounts = gcloud_probe_json(ctx, "iam", "service-accounts", "list") or []
    add("6", "service accounts", len(accounts) >= 5, "%d present" % len(accounts))
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
    add("8", "kms key %s" % ctx.get("KMS_KEY"),
        gcloud_probe_json(ctx, "kms", "keys", "describe", ctx.get("KMS_KEY"),
                          "--keyring", ctx.get("KMS_KEYRING"),
                          "--location", ctx.need("REGION")) is not None)
    for secret in list(WALLE_SECRETS) + list(EVE_SECRETS):
        versions = gcloud_probe_json(
            ctx, "secrets", "versions", "list", secret, "--location", ctx.need("REGION"),
            "--filter", "state=ENABLED") if secret_exists(ctx, secret) else None
        add("8/15", "secret %s" % secret, versions is not None,
            "%d enabled version(s)" % len(versions or []))
    for service in ("walle-actions", "walle-dispatcher"):
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
    for key in ("PROJECT_NUMBER", "REFRESH_TOKEN_VERSION", "ACTIONS_URL",
                "DISPATCHER_URL", "ENGINE_ID", "EVE_TOKEN_VERSION"):
        say("  %-22s %s" % (key, ctx.get(key) or "<empty>"))
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
    say("   - a deleted project id can never be reused, and the KMS key ring goes")
    say("     with it")
    say("   - the OAuth grant survives project deletion: revoke it as the robot at")
    say("     https://myaccount.google.com/permissions")
    say("   - KMS keys cannot be deleted, only their versions destroyed")
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
    for service in ("walle-actions", "walle-dispatcher"):
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
    for secret in list(WALLE_SECRETS) + list(EVE_SECRETS):
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
    if getattr(ctx.args, "destroy_key_versions", False):
        versions = gcloud_probe_json(
            ctx, "kms", "keys", "versions", "list", "--key", ctx.get("KMS_KEY"),
            "--keyring", ctx.get("KMS_KEYRING"), "--location", ctx.need("REGION")) or []
        for version in versions:
            number = str(version.get("name", "")).rsplit("/", 1)[-1]
            run(ctx, ["gcloud", "kms", "keys", "versions", "destroy", number,
                      "--key", ctx.get("KMS_KEY"), "--keyring", ctx.get("KMS_KEYRING"),
                      "--location", ctx.need("REGION"), "--project", project, "--quiet"])
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
    say("   - the KMS key ring and key: keys can only have versions destroyed")
    say("   - the OAuth grant at Google: revoke it as the robot at")
    say("     https://myaccount.google.com/permissions")
    say("   - the five service accounts and every project-level IAM binding")
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
    for title in (ROLE_READER_NAME, ROLE_OPERATOR_NAME, ROLE_EVE_NAME):
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
    always match API names. Use this, not the labels, for the Stage 1 role."""
    catalogue = list_privileges(ctx)
    rows = [[name, service] for name, service in sorted(catalogue.items())]
    say(render_table(rows, ["PRIVILEGE", "SERVICE ID"]))
    say("")
    say("%d privileges. Filter for licen/user/group/report/role when you finalise" % len(rows))
    say("'%s'." % ROLE_OPERATOR_NAME)
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
        version = ctx.need("REFRESH_TOKEN_VERSION")
        say("  FIRST, as the robot in the clean profile, revoke the app at")
        say("  https://myaccount.google.com/permissions. The grant survives this.")
        confirm(ctx, "Destroy walle-refresh-token version %s?" % version)
        run(ctx, ["gcloud", "secrets", "versions", "destroy", version,
                  "--secret", "walle-refresh-token", "--location", ctx.need("REGION"),
                  "--project", ctx.need("PROJECT"), "--quiet"])
        say("  Now delete the OAuth client in the console and remove it from API")
        say("  controls. Never reuse it: more than 100 live tokens for one client")
        say("  makes Google invalidate the oldest silently. A re-run produces a")
        say("  HIGHER version: re-export REFRESH_TOKEN_VERSION and redeploy")
        say("  walle-actions, or the service stays pinned to what you just destroyed.")
    elif phase == "2":
        # The account is left intact: Phase 2's rollback is the ASSIGNMENT only.
        for title in (ROLE_READER_NAME, ROLE_EVE_NAME):
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
        say("  single act that grants anything.")
    elif phase in ("10", "11"):
        service = "walle-actions" if phase == "10" else "walle-dispatcher"
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
    "workspace": ("phases 1 and 2: OUs, robots, groups, sandbox, floor list, roles", cmd_workspace),
    "gcp": ("phases 6, 7 and 8: project, data, keys and secrets", cmd_gcp),
    "consent": ("phases 9 and 15: the one interactive OAuth bootstrap", cmd_consent),
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
                             help="phase 15: Eve's robot instead of Wall-E's")
            sub.add_argument("--store-client", metavar="PATH",
                             help="store this downloaded client JSON, then shred it")
            sub.add_argument("--paste", action="store_true",
                             help="consent on another machine: paste the redirect URL back")
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
            sub.add_argument("--destroy-key-versions", action="store_true",
                             help="destroy Eve's KMS key versions (the key itself remains)")
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
