import assert from 'node:assert/strict';
import { test } from 'node:test';
import { verifyMaintenanceAccess } from '../.github/scripts/verify_maintenance_app.mjs';

const repository = 'owner/example';
function responses(overrides = {}) {
  const data = {
    '/installation/repositories?per_page=100': { total_count: 1, repositories: [{ full_name: repository }] },
    [`/repos/${repository}`]: { full_name: repository, permissions: { push: false, admin: false } },
    [`/repos/${repository}/git/ref/heads/main`]: { ref: 'refs/heads/main' },
    [`/repos/${repository}/pulls?per_page=1`]: [],
    [`/repos/${repository}/actions/permissions`]: { message: 'Resource not accessible by integration' },
    [`/repos/${repository}/actions/secrets`]: { message: 'Resource not accessible by integration' },
    ...overrides,
  };
  return async (url, options) => {
    assert.equal(options.redirect, 'error');
    assert.equal(options.headers.Authorization, 'Bearer synthetic');
    assert.equal(new URL(url).origin, 'https://api.github.com');
    const path = url.slice('https://api.github.com'.length);
    assert.ok(Object.hasOwn(data, path));
    const value = data[path];
    if (value instanceof Response) return value;
    return Response.json(value, { status: /\/actions\/(permissions|secrets)$/.test(path) ? 403 : 200 });
  };
}
const verify = (overrides) => verifyMaintenanceAccess({ token: 'synthetic', repository, fetchImpl: responses(overrides) });

test('code/PR access is accepted only with the exact repository and Secrets denial', async () => {
  await verify();
});

test('other and additional repositories are rejected', async () => {
  for (const scope of [
    { total_count: 1, repositories: [{ full_name: 'owner/other' }] },
    { total_count: 2, repositories: [{ full_name: repository }, { full_name: 'owner/other' }] },
    { total_count: 101, repositories: [{ full_name: repository }] },
  ]) {
    await assert.rejects(verify({ '/installation/repositories?per_page=100': scope }), /exactly/);
  }
});

test('admin access is rejected even when user-role flags are missing', async () => {
  await assert.rejects(verify({
    [`/repos/${repository}`]: { full_name: repository },
    [`/repos/${repository}/actions/permissions`]: Response.json({ enabled: true }),
  }), /permissions access/);
});

test('App authorization uses API probes instead of the repository user-role flags', async () => {
  await verify({ [`/repos/${repository}`]: { full_name: repository } });
  await assert.rejects(verify({ [`/repos/${repository}/git/ref/heads/main`]: Response.json({}, { status: 403 }) }), /403/);
});

test('Secrets access is rejected even when the secret list is empty', async () => {
  await assert.rejects(verify({ [`/repos/${repository}/actions/secrets`]: Response.json({ secrets: [] }) }), /secrets access/);
});

test('rate limits, missing endpoints and unexpected denials cannot pass as permission checks', async () => {
  for (const response of [
    Response.json({ message: 'API rate limit exceeded' }, { status: 403 }),
    Response.json({ message: 'Resource not accessible by integration' }, { status: 403, headers: { 'x-ratelimit-remaining': '0' } }),
    Response.json({ message: 'Not Found' }, { status: 404 }),
  ]) {
    await assert.rejects(verify({ [`/repos/${repository}/actions/secrets`]: response }), /secrets access/);
  }
});

test('failed PR reads and network failures stop verification', async () => {
  await assert.rejects(verify({ [`/repos/${repository}/pulls?per_page=1`]: Response.json({}, { status: 401 }) }), /401/);
  await assert.rejects(verifyMaintenanceAccess({ token: 'synthetic', repository, fetchImpl: async () => { throw new Error('offline'); } }), /offline/);
});

test('missing credentials and malformed repository paths fail before sending requests', async () => {
  for (const args of [{ repository }, { token: 'synthetic', repository: '../other' }]) {
    await assert.rejects(verifyMaintenanceAccess({ ...args, fetchImpl: () => assert.fail('must not send request') }), /Missing/);
  }
});
