import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export async function verifyMaintenanceAccess({ token, repository, fetchImpl = fetch }) {
  if (!token || !/^[A-Za-z0-9][A-Za-z0-9-]*\/(?!\.{1,2}$)[A-Za-z0-9_.-]+$/.test(repository ?? '')) {
    throw new Error('Missing token or invalid repository');
  }
  const headers = {
    Authorization: `Bearer ${token}`,
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };
  const read = async (path) => {
    const response = await fetchImpl(`https://api.github.com${path}`, {
      headers,
      redirect: 'error',
      signal: AbortSignal.timeout(15000),
    });
    if (!response.ok) throw new Error(`App access check failed: HTTP ${response.status}`);
    return response.json();
  };
  const scope = await read('/installation/repositories?per_page=100');
  if (scope.total_count !== 1 || scope.repositories?.length !== 1
      || scope.repositories[0].full_name !== repository) {
    throw new Error('App token must target exactly the current repository');
  }
  const target = await read(`/repos/${repository}`);
  if (target.full_name !== repository) throw new Error('Unexpected repository');
  await read(`/repos/${repository}/git/ref/heads/main`);
  await read(`/repos/${repository}/pulls?per_page=1`);
  for (const path of ['permissions', 'secrets']) {
    const response = await fetchImpl(`https://api.github.com/repos/${repository}/actions/${path}`, {
      headers,
      redirect: 'error',
      signal: AbortSignal.timeout(15000),
    });
    const denial = await response.json();
    if (response.status !== 403 || response.headers.get('x-ratelimit-remaining') === '0'
        || denial.message !== 'Resource not accessible by integration') {
      throw new Error(`Expected an explicit denial of ${path} access`);
    }
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    await verifyMaintenanceAccess({ token: process.env.GH_TOKEN, repository: process.env.GITHUB_REPOSITORY });
    console.log('Maintenance App repository scope and permission boundaries verified.');
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
