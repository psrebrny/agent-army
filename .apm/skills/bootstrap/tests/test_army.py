"""Offline regression tests for read-only monorepo Army discovery."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import army


class RepositoryContextTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve() / 'repo'
        self.root.mkdir()
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        self.plugin = self.root / 'plugins' / 'vento'
        self.cwd = self.plugin / 'src'
        self.cwd.mkdir(parents=True)

    def profile(self, owner, suffix='.agent', config=True):
        directory = owner / '.agent-army'
        (directory / 'agents').mkdir(parents=True, exist_ok=True)
        (directory / 'agents' / f'agent-army-tester{suffix}').write_text('---\nname: tester\n---\nLOCAL TESTER\n')
        if config:
            (directory / 'config.json').write_text(json.dumps({
                'version': 3, 'package': {'version': army.lib.PACKAGE_VERSION},
                'quality': {'test': {'cwd': 'plugins/vento', 'argv': ['yarn', 'test']}},
            }))
        return directory

    def test_nested_profile_keeps_git_root_and_quality_cwd(self):
        directory = self.profile(self.plugin)
        result = army.locate(self.cwd, 'codex')
        self.assertEqual(result['repo_root'], str(self.root))
        self.assertEqual(result['army_root'], str(self.plugin))
        self.assertEqual(result['profile_dir'], str(directory))
        self.assertEqual(result['roles']['tester']['contract_path'], str(directory / 'agents/agent-army-tester.agent'))
        self.assertEqual(result['quality']['test']['cwd'], 'plugins/vento')

    def test_nearest_profile_wins_without_merging_parent_roles(self):
        root_profile = self.profile(self.root)
        (root_profile / 'agents/agent-army-parent-only.agent').write_text('parent')
        self.profile(self.plugin)
        result = army.locate(self.cwd, 'claude')
        self.assertEqual(result['army_root'], str(self.plugin))
        self.assertNotIn('parent-only', result['roles'])

    def test_root_does_not_pick_a_descendant_or_sibling(self):
        self.profile(self.plugin)
        sibling = self.root / 'plugins/other'
        sibling.mkdir()
        for cwd in (self.root, sibling):
            self.assertEqual(army.locate(cwd, None)['profile'], 'baseline')

    def test_explicit_selection_from_root_and_profile_directory(self):
        directory = self.profile(self.plugin)
        for selected in (Path('plugins/vento'), Path('plugins/vento/.agent-army'), directory):
            self.assertEqual(army.locate(self.root, None, selected)['army_root'], str(self.plugin))

    def test_legacy_contracts_without_supported_metadata_are_not_ignored(self):
        directory = self.profile(self.plugin, '.agent.md', config=False)
        for raw in (None, '{broken', '{"version": 99}', '{"version": []}', '{"version": {}}'):
            if raw is not None:
                (directory / 'config.json').write_text(raw)
            result = army.locate(self.cwd, None)
            self.assertEqual(result['roles']['tester']['source'], 'specialized')
            self.assertTrue(result['roles']['tester']['contract_path'].endswith('.agent.md'))
            self.assertIsNotNone(result['metadata_diagnostic'])
            self.assertIsNone(result['quality'])

    def test_duplicate_contracts_fail_instead_of_guessing(self):
        directory = self.profile(self.plugin)
        (directory / 'agents/agent-army-tester.agent.md').write_text('other')
        with self.assertRaises(ValueError):
            army.locate(self.cwd, None)

    def test_explicit_missing_or_cross_repository_profile_fails(self):
        outside = self.root.parent / 'other'
        self.profile(outside)
        for selected in (self.root / 'missing', outside):
            with self.assertRaises(ValueError):
                army.locate(self.root, None, selected)

    def test_symlink_escape_fails(self):
        outside = self.root.parent / 'outside'
        self.profile(outside)
        (self.plugin / '.agent-army').symlink_to(outside / '.agent-army', target_is_directory=True)
        with self.assertRaises(ValueError):
            army.locate(self.cwd, None)

    def test_role_and_metadata_symlink_escape_fail(self):
        directory = self.profile(self.plugin)
        external = self.root.parent / 'external'
        external.write_text('{}')
        for target in (directory / 'config.json', directory / 'agents/agent-army-tester.agent'):
            original = target.read_text()
            target.unlink()
            target.symlink_to(external)
            with self.assertRaises(ValueError):
                army.locate(self.cwd, None)
            target.unlink()
            target.write_text(original)

    def test_nested_git_checkout_is_not_the_parent_team(self):
        self.profile(self.root)
        subprocess.run(['git', 'init', '-q', str(self.plugin)], check=True)
        result = army.locate(self.cwd, None)
        self.assertEqual(result['repo_root'], str(self.plugin))
        self.assertEqual(result['profile'], 'baseline')
        self.profile(self.plugin)
        with self.assertRaises(ValueError):
            army.locate(self.root, None, self.plugin)

    def test_profile_symlink_into_owner_contained_checkout_fails(self):
        foreign = self.plugin / 'vendor/foreign'
        foreign.mkdir(parents=True)
        subprocess.run(['git', 'init', '-q', str(foreign)], check=True)
        self.profile(foreign)
        (self.plugin / '.agent-army').symlink_to(foreign / '.agent-army', target_is_directory=True)
        with self.assertRaises(ValueError):
            army.locate(self.cwd, None)
        with self.assertRaises(ValueError):
            army.locate(self.root, None, self.plugin)

    def test_metadata_and_contract_links_into_embedded_checkout_fail(self):
        directory = self.profile(self.plugin)
        foreign = directory / 'foreign'
        foreign.mkdir()
        subprocess.run(['git', 'init', '-q', str(foreign)], check=True)
        target = foreign / 'payload'
        target.write_text('{}')
        for path in (directory / 'config.json', directory / 'agents/agent-army-tester.agent'):
            original = path.read_text()
            path.unlink()
            path.symlink_to(target)
            with self.assertRaises(ValueError):
                army.locate(self.cwd, None)
            path.unlink()
            path.write_text(original)

    def test_outside_git_fails_without_writes(self):
        with self.assertRaises(ValueError):
            army.locate(self.root.parent, None)
        self.assertFalse((self.root.parent / '.agent-army').exists())

    def test_scoped_models_and_stores_do_not_leak_from_parent(self):
        parent = self.profile(self.root)
        nested = self.profile(self.plugin)
        (parent / 'stores.json').write_text('{}')
        (self.root / 'AGENTS.md').write_text('root instructions')
        config = nested / 'config.json'
        data = json.loads(config.read_text())
        data['model_routing'] = {'strategy': 'inherit'}
        config.write_text(json.dumps(data))
        result = army.locate(self.cwd, 'claude')
        self.assertIsNone(result['roles']['tester']['model'])
        self.assertIsNone(result['stores'])
        self.assertEqual(result['agents_md'], str(self.root / 'AGENTS.md'))
        (nested / 'stores.json').write_text('{}')
        self.assertEqual(army.locate(self.cwd, None)['stores'], str(nested / 'stores.json'))

    def test_role_cli_uses_the_same_selection(self):
        self.profile(self.plugin, '.agent.md')
        result = subprocess.run([sys.executable, army.__file__, 'role', 'tester', '--cwd', str(self.root),
                                 '--army-root', 'plugins/vento'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('LOCAL TESTER', result.stdout)

    def test_legacy_role_update_preserves_one_definition(self):
        directory = self.profile(self.plugin, '.agent.md')
        contract = Path(army.locate(self.cwd, None)['roles']['tester']['contract_path'])
        contract.write_text(contract.read_text() + 'UPDATED CONTRACT\n')
        result = army.locate(self.cwd, None)
        self.assertEqual(result['roles']['tester']['contract_path'], str(contract))
        self.assertEqual(len(list((directory / 'agents').glob('agent-army-tester*'))), 1)
        for skill in ('new-agent', 'adapt-army'):
            instructions = Path(army.__file__).parent.parent / skill / 'SKILL.md'
            text = instructions.read_text()
            self.assertIn('specialized `contract_path`', text)
            self.assertIn('preserv', text)
            self.assertIn('duplicate', text)

    def test_profile_from_newer_package_is_not_an_upgrade(self):
        config = self.profile(self.plugin) / 'config.json'
        data = json.loads(config.read_text())
        for version, pending, newer in (('99.0.0', False, True), ('0.0.1', True, False)):
            data['package']['version'] = version
            config.write_text(json.dumps(data))
            result = army.locate(self.cwd, None)
            self.assertEqual((result['upgrade_pending'], result['profile_newer']), (pending, newer))

    def test_root_profile_and_baseline_remain_supported(self):
        self.assertEqual(army.locate(self.cwd, None)['profile'], 'baseline')
        self.assertFalse((self.root / '.agent-army').exists())
        self.profile(self.root)
        self.assertEqual(army.locate(self.cwd, None)['army_root'], str(self.root))


if __name__ == '__main__':
    unittest.main()
