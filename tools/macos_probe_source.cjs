/* Shared provenance guard for explicit dispatch and one deliberate manifest push.
 * Read-only GitHub API calls; no credentials are persisted or emitted.
 */
const MANIFEST = '.github/probes/native-macos-v06.json';
const KEYS = ['source_run_id', 'source_sha', 'artifact_sha', 'expected_archive_sha256'];

module.exports = async function verifySource({ github, context, core, fs, env = process.env }) {
  let source;
  if (context.eventName === 'push') {
    if (context.ref !== 'refs/heads/main' || !/^[0-9a-f]{40}$/.test(context.payload.before || '') ||
        /^0+$/.test(context.payload.before) || context.payload.deleted) {
      throw new Error('Manifest trigger requires an ordinary push to the existing main branch.');
    }
    const { data: difference } = await github.rest.repos.compareCommitsWithBasehead({
      ...context.repo, basehead: `${context.payload.before}...${context.sha}`
    });
    if (!difference.files?.some(f => f.filename === MANIFEST && f.status !== 'removed')) {
      throw new Error('The exact probe manifest did not change in this push; no probe authorized.');
    }
    source = JSON.parse(fs.readFileSync(MANIFEST, 'utf8'));
    if (!source || Array.isArray(source) || Object.keys(source).sort().join() !== [...KEYS].sort().join()) {
      throw new Error('Probe manifest must contain exactly the four documented source parameters.');
    }
  } else if (context.eventName === 'workflow_dispatch') {
    // Never read the checked-in manifest for a manual run.
    source = {
      source_run_id: env.SOURCE_RUN_ID,
      source_sha: env.SOURCE_SHA,
      artifact_sha: env.ARTIFACT_SHA,
      expected_archive_sha256: env.EXPECTED_ARCHIVE_SHA256
    };
  } else {
    throw new Error('Only explicit dispatch or a deliberate main manifest push is supported.');
  }
  const { source_run_id: runID, source_sha: sha, artifact_sha: artifactSHA,
          expected_archive_sha256: archiveSHA } = source;
  if (!KEYS.every(key => typeof source[key] === 'string') || !/^[1-9]\d*$/.test(runID) ||
      !Number.isSafeInteger(Number(runID)) || !/^[0-9a-f]{40}$/.test(sha) ||
      !/^[0-9a-f]{40}$/.test(artifactSHA) || !/^[0-9a-f]{64}$/.test(archiveSHA)) {
    throw new Error('Require a numeric run ID, full lowercase commit SHAs and inner-ZIP SHA-256.');
  }
  const { data: run } = await github.rest.actions.getWorkflowRun({
    ...context.repo, run_id: Number(runID)
  });
  const { data: workflow } = await github.rest.actions.getWorkflow({
    ...context.repo, workflow_id: run.workflow_id
  });
  if (run.status !== 'completed' || run.conclusion !== 'success' ||
      run.head_sha !== sha || workflow.path !== '.github/workflows/verify.yml' ||
      run.repository?.full_name !== `${context.repo.owner}/${context.repo.repo}` ||
      run.head_repository?.full_name !== run.repository.full_name) {
    throw new Error('Run must be a successful same-repository verify.yml run for the exact SHA.');
  }
  const name = `Luanshi-macOS-${artifactSHA}`;
  const { data: listing } = await github.rest.actions.listWorkflowRunArtifacts({
    ...context.repo, run_id: Number(runID), name
  });
  const matches = listing.artifacts.filter(a => !a.expired && a.name === name &&
    a.workflow_run?.id === run.id && a.workflow_run?.head_sha === sha);
  if (matches.length !== 1) {
    throw new Error('Expected exactly one unexpired artifact tied to this run/head SHA.');
  }
  fs.mkdirSync('mac-graphics-evidence', { recursive: true });
  fs.writeFileSync('mac-graphics-evidence/source.json', JSON.stringify({
    source_head_sha: sha, artifact_checkout_sha: artifactSHA,
    expected_archive_sha256: archiveSHA,
    artifact_id: matches[0].id, artifact_digest: matches[0].digest,
    source_run_id: run.id, source_run_url: run.html_url,
    source_workflow: workflow.path, source_event: run.event,
    probe_event: context.eventName, manifest: context.eventName === 'push' ? MANIFEST : null,
    probe_sha: context.sha, probe_run_id: context.runId
  }, null, 2));
  // No download/app execution step may use unvalidated event inputs directly.
  for (const key of KEYS) core.setOutput(key, source[key]);
  core.setOutput('artifact_name', name);
};
