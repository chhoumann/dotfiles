#!/usr/bin/env node
import { createSign } from "node:crypto";
import {
  chmodSync,
  mkdirSync,
  readFileSync,
  renameSync,
  writeFileSync,
} from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { spawnSync } from "node:child_process";

const configFile = process.env.AGENT_AUTH_CONFIG ??
  join(homedir(), ".config", "agent-auth", "config.json");
const cacheFile = process.env.GITHUB_APP_TOKEN_CACHE ??
  join(homedir(), ".cache", "agent-auth", "github-installation-token.json");

function base64url(value) {
  const input = Buffer.isBuffer(value) ? value : Buffer.from(value);
  return input.toString("base64url");
}

function readCache() {
  try {
    const cached = JSON.parse(readFileSync(cacheFile, "utf8"));
    const validUntil = Date.parse(cached.expires_at) - 5 * 60 * 1000;
    if (cached.token && Number.isFinite(validUntil) && Date.now() < validUntil) {
      return cached.token;
    }
  } catch {
    // Missing, malformed, or expired cache. Mint a fresh token below.
  }
  return null;
}

function readConfig() {
  let config;
  try {
    config = JSON.parse(readFileSync(configFile, "utf8"));
  } catch (error) {
    throw new Error(`Could not read host-owned agent auth config: ${error.message}`);
  }

  if (!config.onePasswordVault || !config.githubAppItemId) {
    throw new Error("Agent auth config is missing onePasswordVault or githubAppItemId");
  }
  return config;
}

function readAppCredentials(config) {
  const result = spawnSync(
    "op",
    ["item", "get", config.githubAppItemId, "--vault", config.onePasswordVault, "--format", "json"],
    { encoding: "utf8", maxBuffer: 1024 * 1024 },
  );
  if (result.status !== 0) {
    throw new Error(result.stderr.trim() || "Could not read GitHub App credentials from 1Password");
  }

  const item = JSON.parse(result.stdout);
  const fields = Object.fromEntries(item.fields.map((field) => [field.label, field.value]));
  const appId = fields["app id"];
  const installationId = fields["installation id"];
  const privateKey = fields.credential;
  if (!appId || !installationId || !privateKey) {
    throw new Error("The GitHub App 1Password item is missing app id, installation id, or credential");
  }
  return { appId, installationId, privateKey };
}

function createJwt(appId, privateKey) {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64url(JSON.stringify({ iat: now - 60, exp: now + 9 * 60, iss: appId }));
  const unsigned = `${header}.${payload}`;
  const signer = createSign("RSA-SHA256");
  signer.update(unsigned);
  signer.end();
  return `${unsigned}.${base64url(signer.sign(privateKey))}`;
}

async function mintToken() {
  const config = readConfig();
  const { appId, installationId, privateKey } = readAppCredentials(config);
  const response = await fetch(
    `https://api.github.com/app/installations/${encodeURIComponent(installationId)}/access_tokens`,
    {
      method: "POST",
      headers: {
        Accept: "application/vnd.github+json",
        Authorization: `Bearer ${createJwt(appId, privateKey)}`,
        "X-GitHub-Api-Version": "2026-03-10",
        "User-Agent": "coding-agent-github-app",
      },
    },
  );
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`GitHub token request failed (${response.status}): ${body}`);
  }

  const token = await response.json();
  if (!token.token || !token.expires_at) {
    throw new Error("GitHub returned an incomplete installation token response");
  }

  mkdirSync(dirname(cacheFile), { recursive: true, mode: 0o700 });
  const temporary = `${cacheFile}.${process.pid}`;
  writeFileSync(temporary, JSON.stringify({ token: token.token, expires_at: token.expires_at }), {
    mode: 0o600,
  });
  chmodSync(temporary, 0o600);
  renameSync(temporary, cacheFile);
  return token.token;
}

const cached = readCache();
process.stdout.write(cached ?? await mintToken());
