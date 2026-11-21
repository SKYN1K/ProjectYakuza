import importlib.util
import ast
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('content_upload', ROOT / 'tools/Upload-WorkshopContent.py')
uploader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(uploader)


class ContentUploadTests(unittest.TestCase):
    def staged(self, root):
        mod = root / 'Contents/mods/Test/42'
        (mod / 'media/lua/shared').mkdir(parents=True)
        (mod / 'mod.info').write_text('name=Test\nid=Test\nversion=1.0.1\n', encoding='utf-8')
        (mod / 'media/lua/shared/Test.lua').write_text('return true\n', encoding='utf-8')
        (root / 'workshop.txt').write_text('id=3843019266\ndescription=Do not replace this\n', encoding='utf-8')

    def test_dry_run_never_initializes_steam(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.staged(root)
            with patch.object(uploader, 'upload', side_effect=AssertionError('Upload must be explicit')):
                uploader.main(['--workshop-folder', str(root)])
            self.assertIn('Do not replace this', (root / 'workshop.txt').read_text(encoding='utf-8'))

    def test_wrong_item_and_extra_files_are_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.staged(root)
            with self.assertRaises(ValueError):
                uploader.prepare(root, 123)
            (root / 'Contents/notes.txt').write_text('local notes', encoding='utf-8')
            with self.assertRaises(ValueError):
                uploader.prepare(root)

    def test_existing_item_is_required(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.staged(root)
            (root / 'workshop.txt').write_text('id=0\n', encoding='utf-8')
            with self.assertRaises(ValueError):
                uploader.prepare(root)

    def test_page_metadata_setters_cannot_be_bound(self):
        tree = ast.parse((ROOT / 'tools/Upload-WorkshopContent.py').read_text(encoding='utf-8'))
        setters = {node.args[0].value for node in ast.walk(tree) if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and node.func.id == 'function' and node.args and isinstance(node.args[0], ast.Constant) and str(node.args[0].value).startswith('SteamAPI_ISteamUGC_Set')}
        self.assertEqual(setters, {'SteamAPI_ISteamUGC_SetItemContent'})

    def test_update_only_sets_content_and_optional_change_note(self):
        calls = []
        def start(ugc, app, item):
            calls.append(('start', ugc, app, item))
            return 10
        def content(ugc, handle, path):
            calls.append(('content', ugc, handle, path))
            return True
        def submit(ugc, handle, note):
            calls.append(('submit', ugc, handle, note))
            return 20
        self.assertEqual(uploader.begin_update(start, content, submit, 1, 3843019266, Path('Contents'), None), (10, 20))
        self.assertEqual([c[0] for c in calls], ['start', 'content', 'submit'])
        self.assertEqual(calls[0][2:], (108600, 3843019266))
        self.assertIsNone(calls[-1][-1])
        calls.clear()
        uploader.begin_update(start, content, submit, 1, 3843019266, Path('Contents'), 'Fixes')
        self.assertEqual(calls[-1][-1], b'Fixes')


if __name__ == '__main__':
    unittest.main()
