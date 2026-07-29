#!/usr/bin/env node

import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '..', '..');
const lockPath = path.join(repo, 'reproducibility', 'dependencies.lock.yaml');
const lock = readFileSync(lockPath, 'utf8');

let passed = 0;
function test(name, fn) {
  fn();
  passed += 1;
  process.stdout.write(`ok ${passed} - ${name}\n`);
}

function git(args) {
  const result = spawnSync('git', args, { cwd: repo, encoding: 'utf8' });
  assert.equal(result.status, 0, result.stderr || result.stdout);
  return result.stdout;
}

test('canonical documentation and patch trees are publishable', () => {
  for (const relative of [
    'docs/BASELINES.md',
    'docs/NETWORK.md',
    'docs/REPRODUCIBILITY.md',
    'docs/SECURITY.md',
    'docs/STATUS.md',
    'patches/performance/oai-dl-mcs-debug-instrumentation.patch',
    'patches/rpi-du/oai-b210-106prb-61p44msps.patch',
    'patches/sib8/oai-pws-sib8-cu-du.patch',
  ]) {
    assert.ok(existsSync(path.join(repo, relative)), `missing ${relative}`);
    const ignored = spawnSync('git', ['check-ignore', '-q', relative], { cwd: repo });
    assert.notEqual(ignored.status, 0, `${relative} is excluded by .gitignore`);
  }
});

test('dependency revisions are immutable full commits', () => {
  const commits = [...lock.matchAll(/^\s+commit:\s+"([0-9a-f]+)"$/gm)].map(match => match[1]);
  assert.equal(commits.length, 3);
  for (const commit of commits) assert.match(commit, /^[0-9a-f]{40}$/);
  assert.match(lock, /authoritative:\s+false/);
});

test('patch hashes match the dependency lock', () => {
  const entries = [...lock.matchAll(
    /^\s+- id:\s+([a-z0-9_]+)[\s\S]*?^\s+path:\s+"([^"]+)"[\s\S]*?^\s+base_commit:\s+"([0-9a-f]{40})"[\s\S]*?^\s+sha256:\s+"([0-9a-f]{64})"/gm,
  )];
  assert.equal(entries.length, 3);
  for (const [, id, relative, base, expected] of entries) {
    const file = path.join(repo, relative);
    assert.ok(existsSync(file), `${id}: missing ${relative}`);
    assert.equal(base, '102965a669b9444857c27843ec8ce62780bf9d37');
    const actual = createHash('sha256').update(readFileSync(file)).digest('hex');
    assert.equal(actual, expected, `${id}: checksum mismatch`);
  }
});

test('tracked and pending text files do not contain credential-shaped values', () => {
  const files = git(['ls-files', '--cached', '--others', '--exclude-standard', '-z'])
    .split('\0')
    .filter(Boolean);
  const patterns = [
    /-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----/,
    /\b(?:ki|opc)\s*[:=]\s*["']?[0-9a-f]{16,}/i,
    /\b(?:imsi|supi)\s*[:= -]\s*[0-9]{14,16}\b/i,
    /\b(?:password|passwd|token)\s*[:=]\s*["']?(?!<)[^\s"'#]{8,}/i,
  ];
  for (const relative of files) {
    const file = path.join(repo, relative);
    let content;
    try {
      content = readFileSync(file, 'utf8');
    } catch {
      continue;
    }
    if (content.includes('\0')) continue;
    for (const pattern of patterns) {
      assert.doesNotMatch(content, pattern, `${relative} contains a credential-shaped value`);
    }
  }
});

test('local Markdown links resolve', () => {
  const files = git(['ls-files', '--cached', '--others', '--exclude-standard', '*.md'])
    .split('\n')
    .filter(Boolean);
  for (const relative of files) {
    const file = path.join(repo, relative);
    const content = readFileSync(file, 'utf8');
    for (const match of content.matchAll(/\[[^\]]+\]\(([^)]+)\)/g)) {
      let target = match[1].trim().replace(/^<|>$/g, '');
      if (/^(?:https?:|mailto:|#)/.test(target)) continue;
      target = decodeURIComponent(target.split('#', 1)[0]);
      if (!target) continue;
      const resolved = path.resolve(path.dirname(file), target);
      assert.ok(existsSync(resolved), `${relative}: broken link ${match[1]}`);
    }
  }
});

process.stdout.write(`# ${passed} reproducibility checks passed\n`);
