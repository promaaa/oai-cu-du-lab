#!/usr/bin/env node

import assert from 'node:assert/strict';
import { chmodSync, existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, '..', '..');
const tui = path.join(repo, 'scripts', 'oai-lab-tui');
const source = readFileSync(tui, 'utf8');
const temp = mkdtempSync(path.join(tmpdir(), 'oai-tui-static-'));
const mockBin = path.join(temp, 'bin');
const contactLog = path.join(temp, 'external-contact.log');

await import('node:fs').then(({ mkdirSync }) => mkdirSync(mockBin));
for (const name of ['ssh', 'scp', 'sudo', 'sleep', 'bash']) {
  const file = path.join(mockBin, name);
  writeFileSync(file, `#!/bin/sh\nprintf '%s\\n' '${name}' >> "$OAI_TUI_CONTACT_LOG"\nexit 99\n`);
  chmodSync(file, 0o755);
}

const baseEnv = {
  ...process.env,
  OAI_TUI_ISOLATED_TEST: '1',
  OAI_TUI_CONTACT_LOG: contactLog,
  PATH: `${mockBin}:${process.env.PATH || ''}`,
};

function run(args = [], input = '') {
  return spawnSync(process.execPath, [tui, ...args], {
    cwd: repo,
    env: baseEnv,
    input,
    encoding: 'utf8',
    timeout: 5000,
  });
}

function combined(result) {
  return `${result.stdout || ''}\n${result.stderr || ''}`;
}

let passed = 0;
function test(name, fn) {
  fn();
  passed += 1;
  process.stdout.write(`ok ${passed} - ${name}\n`);
}

try {
  const imported = await import(pathToFileURL(tui));
  const api = imported.tuiTestApi;

  test('DU and backhaul builders cover every supported combination', () => {
    for (const du of ['minipc', 'pi', 'jetson']) {
      for (const profile of ['ethernet', 'wifiGre', 'quectelWg']) {
        const config = api.buildLabConfigForDu(du, profile);
        assert.equal(config.backhaulProfile, profile);
        assert.match(config.duRuntimeConf, new RegExp(`${du}-(ethernet|wifi-gre|quectel-wg)-runtime\\.conf$`));
      }
    }
    assert.throws(() => api.buildLabConfigForDu('invalid'), /Unknown DU config/);
  });

  test('transport parsers fail closed when QMI fields are absent', () => {
    assert.deepEqual(api.parseQmiSettings('pdu_stable_connected=0'), {
      ip: '', gateway: '', prefix: '32', mtu: '', stableConnected: false,
    });
    assert.deepEqual(api.parseRouteDevSrc('10.0.0.1 dev wwan0 src 10.0.0.2'), { dev: 'wwan0', src: '10.0.0.2' });
    assert.equal(api.maskIpv4ToPrefix('255.255.255.0'), '24');
  });

  test('evidence sanitization redacts IMSIs and long key-like values', () => {
    const secret = ['00101', '01234', '56789'].join('');
    const keyLike = 'A1B2'.repeat(8);
    const sanitized = api.sanitizeCapture(`imsi=${secret} key=${keyLike}`);
    assert.doesNotMatch(sanitized, new RegExp(secret));
    assert.doesNotMatch(sanitized, new RegExp(keyLike));
    assert.match(sanitized, /<redacted>/);
  });

  test('help is complete and does not contact external commands', () => {
    const result = run(['--help']);
    assert.equal(result.status, 0, combined(result));
    for (const flag of ['--env=', '--du=', '--backhaul=', '--doctor', '--status', '--logs', '--verify', '--start-ethernet', '--rollback-caged-quectel']) {
      assert.match(result.stdout, new RegExp(flag.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
    }
  });

  test('invalid DU, backhaul, unknown flags, and multiple actions return non-zero', () => {
    for (const args of [
      ['--du=invalid'],
      ['--backhaul=invalid'],
      ['--unknown'],
      ['--status', '--logs'],
    ]) {
      const result = run(args);
      assert.notEqual(result.status, 0, `${args.join(' ')} unexpectedly passed\n${combined(result)}`);
      assert.doesNotMatch(combined(result), /PASS:/);
    }
  });

  test('all CLI action paths dispatch through the isolated mock adapter', () => {
    for (const flag of [
      '--doctor', '--verify', '--start-ethernet', '--start-wifi-gre', '--start-quectel-wg',
      '--start-mono', '--start-caged-quectel', '--validate-caged-quectel',
      '--rollback-caged-quectel', '--status', '--logs',
    ]) {
      const result = run(['--du=serber-minipc', '--backhaul=ethernet', flag]);
      assert.equal(result.status, 0, `${flag}\n${combined(result)}`);
      assert.match(result.stdout, new RegExp(`dispatch=${flag}`));
      assert.match(result.stdout, /ssh=mocked prompts=scripted sleeps=mocked external_commands=blocked/);
      assert.doesNotMatch(result.stdout, /PASS:/);
    }
  });

  test('mocked prerequisite failure is non-zero and cannot print PASS', () => {
    const result = spawnSync(process.execPath, [tui, '--start-quectel-wg'], {
      cwd: repo,
      env: { ...baseEnv, OAI_TUI_TEST_FAIL_ACTION: '1' },
      encoding: 'utf8',
      timeout: 5000,
    });
    assert.notEqual(result.status, 0, combined(result));
    assert.match(combined(result), /No PASS claimed/);
    assert.doesNotMatch(combined(result), /PASS:/);
  });

  test('scripted interactive menu can exit cleanly with mocked status discovery', () => {
    const result = run([], 'y\n13\n');
    assert.equal(result.status, 0, combined(result));
    assert.match(result.stdout, /OAI CU\/DU Lab Demo Console/);
  });

  test('scripted input exhaustion and invalid menu input fail closed', () => {
    for (const input of ['y\n', 'y\n99\n']) {
      const result = run([], input);
      assert.notEqual(result.status, 0, combined(result));
      assert.match(combined(result), /Scripted input exhausted/);
      assert.doesNotMatch(combined(result), /PASS:/);
    }
  });

  test('menu, stop, PWS, validation, and rollback dispatch remain reachable in source', () => {
    for (const marker of [
      "value: 'start-split'", "value: 'start-mono'", "value: 'start-caged-quectel'",
      "value: 'validate-caged-quectel'", "value: 'pws'", "value: 'status'",
      "value: 'logs'", "value: 'stop-all'", "--rollback-caged-quectel",
    ]) assert.ok(source.includes(marker), `missing dispatch marker: ${marker}`);
  });

  test('operator success text cannot claim full PASS from machine-side gates alone', () => {
    assert.doesNotMatch(source, /printSuccess\(['"`]PASS:/);
    assert.match(source, /phone-visible PWS, registration, PDU session, internet, and throughput/);
    assert.match(source, /No phone-service PASS claimed/);
  });

  test('portable environment overrides cover hosts, paths, logs, and SSH options', () => {
    for (const marker of [
      'process.env.MINIPC_HOST', 'process.env.JETSON_HOST', 'process.env.CU_CN_DIR',
      'process.env.CU_OAI_DIR', 'process.env.DU_OAI_DIR', 'process.env.CU_ETH_CONF',
      "duPathOverride('DU_ETH_CONF'", 'process.env.MONO_OAI_DIR', 'process.env.LAB_SSH_OPTS',
    ]) assert.ok(source.includes(marker), `missing environment override: ${marker}`);
    assert.match(source, /process\.env\[key\] === undefined/);
    assert.match(source, /Private environment file is required/);
    assert.deepEqual(api.parseEnvFile([
      'export CU_HOST=professor@cu.example',
      'QUECTEL_APN="lab#private"',
      'DU_HOST=professor@du.example # local note',
    ].join('\n')), {
      CU_HOST: 'professor@cu.example',
      QUECTEL_APN: 'lab#private',
      DU_HOST: 'professor@du.example',
    });
  });

  test('Every Jetson transport keeps the validated downlink MCS ceiling', () => {
    assert.match(source, /duLabel === 'serber-jetson' \? '28' : '18'/);
  });

  test('Jetson access radio removes the receive attenuation that caused UE churn', () => {
    assert.match(source, /JETSON_ATT_RX \|\| '0'/);
    assert.match(source, /s\/\(att_rx/);
  });

  test('caged Quectel generation receives the selected DU paths and Jetson RF profile', () => {
    for (const marker of [
      'OAI_TUI_SELECTED_CONFIG=1', 'DU_PROD_CONF=', 'DU_QUECTEL_CONF=',
      'ACCESS_ATT_TX=', 'ACCESS_ATT_RX=', "process.env.JETSON_ATT_TX || '3'",
      "process.env.JETSON_ATT_RX || '0'", 'num_recv_frames=64,num_send_frames=64',
      "'DL_MAX_MCS=28'", "'UL_MIN_MCS=5'",
    ]) assert.ok(source.includes(marker), `missing selected Quectel generator marker: ${marker}`);
  });

  test('Jetson Quectel launch applies high-rate USB tuning and pinned DU execution', () => {
    assert.match(source, /await tuneSelectedDuForB210HighRate\(minipc, dir\)/);
    assert.match(source, /selectedDuLauncher\(\)/);
    assert.match(source, /selectedDuStartExtraArgs\(\)/);
    assert.match(source, /duLabel === 'serber-jetson' \? '' : '--continuous-tx'/);
    assert.match(source, /ping -c 4 -W 2 \$\{WG_CU_IP\}/);
  });

  test('mutating operator sessions are protected by an exclusive stale-safe lock', () => {
    for (const marker of [
      'OPERATOR_LOCK_DIR', 'acquireOperatorLock', 'releaseOperatorLock',
      'Another OAI lab operator console is active', 'processIsAlive',
    ]) assert.ok(source.includes(marker), `missing operator lock marker: ${marker}`);
    assert.match(source, /if \(process\.argv\.includes\('--logs'\)\)[\s\S]+acquireOperatorLock\(\);[\s\S]+--start-ethernet/);
  });

  test('Quectel launch restores kernel modules and excludes ModemManager', () => {
    assert.match(source, /ensureQuectelWireGuardPrerequisites/);
    for (const marker of ['cdc_wdm', 'qmi_wwan', 'wireguard', 'ModemManager.service', 'qmicli', 'socat', 'tcpdump']) {
      assert.ok(source.includes(marker), `missing Quectel prerequisite marker: ${marker}`);
    }
  });

  test('Quectel phone throughput is guarded by donor/access cell identity', () => {
    assert.match(source, /checkPhoneAccessCell/);
    for (const marker of ['phone_access_cell', 'phone_donor_cell', 'quectel_donor_cell', 'throughput cannot be attributed']) {
      assert.ok(source.includes(marker), `missing topology gate marker: ${marker}`);
    }
  });

  test('isolated suite made no external-process or network contact', () => {
    assert.equal(existsSync(contactLog), false, 'a sentinel external command was invoked');
  });

  api.close();
  process.stdout.write(`# ${passed} static tests passed; external/network contact count=0\n`);
} finally {
  rmSync(temp, { recursive: true, force: true });
}
