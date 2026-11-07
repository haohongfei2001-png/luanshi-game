/* Node's built-in test runner; no network or GitHub writes. */
const assert = require('node:assert/strict');
const { test } = require('node:test');
const verifySource = require('../tools/macos_probe_source.cjs');
const manifest = require('../.github/probes/native-macos-v06.json');
const MANIFEST = '.github/probes/native-macos-v06.json';

function fixture(eventName = 'workflow_dispatch') {
  const record = { reads: [], outputs: {}, source: null, apiCalls: [] };
  const context = {
    eventName, ref: 'refs/heads/main', payload: { before: 'a'.repeat(40) },
    repo: { owner: 'haohongfei2001-png', repo: 'luanshi-game' }, sha: 'b'.repeat(40), runId: 9
  };
  const name = 'haohongfei2001-png/luanshi-game';
  const run = {
    id: Number(manifest.source_run_id), status: 'completed', conclusion: 'success',
    head_sha: manifest.source_sha, workflow_id: 1, repository: { full_name: name },
    head_repository: { full_name: name }, event: 'pull_request'
  };
  const artifact = {
    id: 13595636136, name: `Luanshi-macOS-${manifest.artifact_sha}`, expired: false,
    workflow_run: { id: run.id, head_sha: run.head_sha }
  };
  const difference = { files: [{ filename: MANIFEST, status: 'added' }] };
  const workflow = { path: '.github/workflows/verify.yml' };
  const github = { rest: {
    repos: { compareCommitsWithBasehead: async args => { record.apiCalls.push(args); return { data: difference }; } },
    actions: {
      getWorkflowRun: async () => ({ data: run }),
      getWorkflow: async () => ({ data: workflow }),
      listWorkflowRunArtifacts: async () => ({ data: { artifacts: [artifact] } })
    }
  } };
  const env = {
    SOURCE_RUN_ID: manifest.source_run_id, SOURCE_SHA: manifest.source_sha,
    ARTIFACT_SHA: manifest.artifact_sha, EXPECTED_ARCHIVE_SHA256: manifest.expected_archive_sha256
  };
  let contents = JSON.stringify(manifest);
  const fs = {
    readFileSync: path => { record.reads.push(path); return contents; },
    mkdirSync: () => {}, writeFileSync: (_, value) => { record.source = JSON.parse(value); }
  };
  const core = { setOutput: (key, value) => { record.outputs[key] = value; } };
  return { record, context, env, run, artifact, difference, workflow,
    contents: value => { contents = value; }, invoke: () => verifySource({ github, context, core, fs, env }) };
}

test('manual inputs use no manifest and preserve PR head/merge SHA distinction', async () => {
  const f = fixture();
  await f.invoke();
  assert.deepEqual(f.record.reads, []);
  assert.deepEqual(f.record.apiCalls, []);
  assert.equal(f.record.outputs.source_sha, manifest.source_sha);
  assert.equal(f.record.outputs.artifact_sha, manifest.artifact_sha);
  assert.equal(f.record.outputs.expected_archive_sha256, manifest.expected_archive_sha256);
  assert.equal(f.record.outputs.artifact_name, `Luanshi-macOS-${manifest.artifact_sha}`);
  assert.equal(f.record.source.manifest, null);
});

test('deliberate main push reads only the exact manifest and ignores manual env', async () => {
  const f = fixture('push');
  Object.keys(f.env).forEach(key => { f.env[key] = 'ignored'; });
  await f.invoke();
  assert.deepEqual(f.record.reads, [MANIFEST]);
  assert.equal(f.record.outputs.source_run_id, manifest.source_run_id);
  assert.equal(f.record.source.manifest, MANIFEST);
  assert.equal(f.record.source.probe_event, 'push');
  assert.equal(f.record.apiCalls[0].basehead, `${'a'.repeat(40)}...${'b'.repeat(40)}`);
});

for (const [name, mutate] of [
  ['unchanged manifest', f => { f.difference.files = [{ filename: 'README.md', status: 'modified' }]; }],
  ['removed manifest', f => { f.difference.files[0].status = 'removed'; }],
  ['non-main push', f => { f.context.ref = 'refs/heads/other'; }],
  ['branch creation', f => { f.context.payload.before = '0'.repeat(40); }],
  ['branch deletion', f => { f.context.payload.deleted = true; }],
  ['malformed manifest', f => { f.contents('not JSON'); }],
  ['unknown manifest fields', f => { f.contents(JSON.stringify({ ...manifest, other: true })); }],
  ['missing checksum in manifest', f => { const m = { ...manifest }; delete m.expected_archive_sha256; f.contents(JSON.stringify(m)); }],
  ['non-string run ID', f => { f.contents(JSON.stringify({ ...manifest, source_run_id: 42425639702 })); }]
]) {
  test(`reject push: ${name}`, async () => {
    const f = fixture('push'); mutate(f);
    await assert.rejects(f.invoke());
    assert.deepEqual(f.record.outputs, {});
  });
}

for (const [name, mutate] of [
  ['unsupported event', f => { f.context.eventName = 'schedule'; }],
  ['missing manual hash', f => { delete f.env.EXPECTED_ARCHIVE_SHA256; }],
  ['invalid manual hash', f => { f.env.EXPECTED_ARCHIVE_SHA256 = 'X'.repeat(64); }],
  ['unsafe numeric run ID', f => { f.env.SOURCE_RUN_ID = '9999999999999999999'; }],
  ['failed run', f => { f.run.conclusion = 'failure'; }],
  ['wrong head SHA', f => { f.run.head_sha = '0'.repeat(40); }],
  ['wrong workflow', f => { f.workflow.path = '.github/workflows/other.yml'; }],
  ['external fork', f => { f.run.head_repository.full_name = 'outsider/fork'; }],
  ['expired artifact', f => { f.artifact.expired = true; }],
  ['artifact from another run', f => { f.artifact.workflow_run.id = 100; }],
  ['artifact from another source', f => { f.artifact.workflow_run.head_sha = '0'.repeat(40); }],
  ['wrong artifact name', f => { f.artifact.name = 'unrelated'; }]
]) {
  test(`reject source: ${name}`, async () => {
    const f = fixture(); mutate(f);
    await assert.rejects(f.invoke());
    assert.deepEqual(f.record.outputs, {});
  });
}
