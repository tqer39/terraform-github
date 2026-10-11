"""開発依存の glob 互換性と深い入力の拒否を検証する。"""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

PROJECT = Path(__file__).resolve().parents[1]


class BracesTests(unittest.TestCase):
    def node(self, script):
        result = subprocess.run(
            ["node", "--input-type=module", "-e", """
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const require = createRequire(process.cwd() + '/package.json');
const cliRequire = createRequire(require.resolve('markdownlint-cli2'));
const mmRequire = createRequire(cliRequire.resolve('micromatch'));
const braces = mmRequire('braces');
""" + script], cwd=PROJECT, text=True, capture_output=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_normal_brace_patterns_keep_expected_results(self):
        self.node(r"""
assert.deepEqual(braces('*.{md,markdown}'), ['*.(md|markdown)']);
assert.deepEqual(braces.expand('a/{b,{c,d}}/{1..3}'), [
  'a/b/1', 'a/b/2', 'a/b/3', 'a/c/1', 'a/c/2', 'a/c/3',
  'a/d/1', 'a/d/2', 'a/d/3'
]);
assert.deepEqual(braces.expand('{03..01}'), ['03', '02', '01']);
assert.deepEqual(braces.expand('{a,a,b}', { nodupes: true }), ['a', 'b']);
assert.equal(braces.stringify(braces.parse('a/{b,c}')), 'a/{b,c}');
const escaped = String.raw`\{`.repeat(200) + 'x' + String.raw`\}`.repeat(200);
assert.doesNotThrow(() => braces.compile(escaped));
""")

    def test_deep_strings_are_rejected_before_stack_exhaustion(self):
        self.node("""
for (const [open, close] of [['{', '}'], ['(', ')'], ['{(', ')}']]) {
  const nesting = open.length;
  const allowed = open.repeat(100 / nesting) + 'x' + close.repeat(100 / nesting);
  const excessive = open.repeat(101) + 'x' + close.repeat(101);
  const attack = open.repeat(2000) + 'x' + close.repeat(2000);
  for (const operation of ['parse', 'compile', 'expand', 'stringify']) {
    assert.doesNotThrow(() => braces[operation](allowed));
    for (const pattern of [excessive, attack]) {
      assert.throws(() => braces[operation](pattern), {
        name: 'SyntaxError', message: /exceeds max depth/
      });
    }
  }
}
assert.throws(() => braces.compile('{'.repeat(101) + 'x' + '}'.repeat(101),
  { maxDepth: Infinity }), /exceeds max depth/);
""")

    def test_direct_ast_traversal_is_also_bounded(self):
        self.node("""
const tree = () => {
  let node = { type: 'text', value: 'x' };
  for (let i = 0; i < 2000; i++) node = { type: 'brace', nodes: [node] };
  return { type: 'root', nodes: [node] };
};
for (const operation of ['compile', 'expand', 'stringify']) {
  assert.throws(() => braces[operation](tree()), {
    name: 'RangeError', message: /AST depth .*exceeds max depth/
  });
}
""")

    def test_both_consumers_resolve_the_guarded_package(self):
        self.node("""
const rulesRequire = createRequire(require.resolve('rulesync'));
const globRequire = createRequire(rulesRequire.resolve('globby'));
const rulesMmRequire = createRequire(globRequire.resolve('micromatch'));
assert.equal(rulesMmRequire.resolve('braces'), mmRequire.resolve('braces'));
assert.equal(mmRequire('braces/package.json').name, '@dieub/braces-depth-guard');
const { globby } = await import(cliRequire.resolve('globby'));
const files = await globby(['docs/rules/*.{md,markdown}', '!**/project.md']);
assert.deepEqual(files.sort(), [
  'docs/rules/coding-standards.md', 'docs/rules/development.md',
  'docs/rules/documentation.md'
]);
const hostile = '{'.repeat(2000) + 'x' + '}'.repeat(2000);
assert.throws(() => cliRequire('micromatch').braceExpand(hostile), /exceeds max depth/);
await assert.rejects(globby(hostile), /exceeds max depth/);
""")

    def markdownlint(self, *args):
        return subprocess.run(
            ["pnpm", "exec", "markdownlint-cli2", *map(str, args)], cwd=PROJECT,
            env=dict(os.environ, NO_COLOR="1"), text=True, capture_output=True,
            timeout=20)

    def test_markdown_lint_fix_and_unfixable_errors(self):
        with tempfile.TemporaryDirectory(dir=PROJECT) as temp:
            path = Path(temp) / "ordinary file.md"
            path.write_text("#Title\n")
            failed = self.markdownlint(path)
            self.assertNotEqual(failed.returncode, 0, failed.stdout + failed.stderr)
            fixed = self.markdownlint("--fix", path)
            self.assertEqual(fixed.returncode, 0, fixed.stdout + fixed.stderr)
            self.assertEqual(path.read_text(), "# Title\n")
            path.write_text("# Title\n\n<script>bad</script>\n")
            failed = self.markdownlint("--fix", path)
            self.assertNotEqual(failed.returncode, 0, failed.stdout + failed.stderr)
            self.assertIn("MD033", failed.stdout + failed.stderr)

    def test_external_filename_does_not_exhaust_stack(self):
        with tempfile.TemporaryDirectory(dir=PROJECT) as temp:
            path = Path(temp) / ("{" * 110 + "x" + "}" * 110 + ".md")
            path.write_text("# Title\n")
            result = self.markdownlint("--fix", path)
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("exceeds max depth", result.stdout + result.stderr)
            self.assertNotIn("Maximum call stack", result.stdout + result.stderr)
            self.assertEqual(path.read_text(), "# Title\n")


if __name__ == "__main__":
    unittest.main()
