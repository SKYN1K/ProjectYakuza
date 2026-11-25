from pathlib import Path
import importlib.util,tempfile,unittest,zipfile,struct,json
root=Path(__file__).resolve().parents[2];spec=importlib.util.spec_from_file_location('game_package',root/'tools/Build-GamePackage.py');package=importlib.util.module_from_spec(spec);spec.loader.exec_module(package)
class RuntimePackageTests(unittest.TestCase):
 def test_runtime_allowlist_excludes_development_files(self):
  with tempfile.TemporaryDirectory()as folder:
   mod=Path(folder)
   for name,content in {'42/mod.info':'name=Test\nid=Test\nversion=1.0.0','42/media/lua/shared/Test.lua':'return true','docs/provenance.json':'C:/Users/Private/Secret','AGENTS.md':'private instructions','tools/extract.py':'private tooling','templates/style.txt':'template'}.items():
    path=mod/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(content)
   files=package.runtime_files(mod);self.assertEqual(set(files),{'42/mod.info','42/media/lua/shared/Test.lua'});output=mod/'game.zip';package.write_zip(output,'Test',files)
   with zipfile.ZipFile(output)as archive:self.assertEqual(set(archive.namelist()),{'Test/common/','Test/42/mod.info','Test/42/media/lua/shared/Test.lua'})
 def test_only_flat_translation_json_is_runtime_data(self):
  with tempfile.TemporaryDirectory()as folder:
   mod=Path(folder);(mod/'42').mkdir();(mod/'42/mod.info').write_text('id=Test\nversion=1.1\n')
   path=mod/'42/media/lua/shared/Translate/EN/Sandbox.json';path.parent.mkdir(parents=True);path.write_text('{"Sandbox_Test":"Test"}')
   self.assertIn('42/media/lua/shared/Translate/EN/Sandbox.json',package.runtime_files(mod))
   path.write_text('{"Sandbox_Test":{"nested":"unused"}}')
   with self.assertRaises(AssertionError):package.runtime_files(mod)
   path.unlink();path=mod/'42/media/private.json';path.write_text('{}')
   with self.assertRaises(AssertionError):package.runtime_files(mod)
 def test_private_paths_and_tokens_are_rejected(self):
  for text in ['C:/Users/Private/data','E:\\Blender\\Rips','ghp_'+'a'*32,'person@example.test','-----BEGIN OPENSSH PRIVATE KEY-----','AGENTS.md']:
   with self.subTest(text=text[:10]),self.assertRaises(AssertionError):package.scan('42/media/lua/shared/Test.lua',text.encode())
 def test_invalid_file_location_is_rejected(self):
  for name in ['../AGENTS.md','42/media/docs/notes.txt','42/media/tools/helper.txt']:
   with self.subTest(name=name),self.assertRaises(AssertionError):package.scan(name,b'private')
 def test_ogg_comments_are_audited_without_scanning_compressed_samples_as_email(self):
  vendor=b'original encoder';header=b'\x03vorbis'+struct.pack('<I',len(vendor))+vendor
  package.scan('42/media/sound/test.ogg',header+struct.pack('<I',0)+b'compressed@example.test')
  comment=b'ARTIST=person@example.test';tagged=header+struct.pack('<II',1,len(comment))+comment
  with self.assertRaises(AssertionError):package.scan('42/media/sound/test.ogg',tagged)
 def test_every_registered_sound_and_sandbox_control_has_a_readable_label(self):
  import re
  media=root/'combat/ProjectYakuza/42/media';labels=json.loads((media/'lua/shared/Translate/EN/GameSound.json').read_text(encoding='utf-8'));sounds=set();categories=set()
  for path in(media/'scripts').glob('*.txt'):
   text=path.read_text();sounds.update(re.findall(r'\bsound\s+(ProjectYakuza_\w+)\s*\{',text));categories.update(re.findall(r'\bcategory\s*=\s*(ProjectYakuza[^,\s]+)',text))
  for key in ['GameSound_'+name for name in sounds]+['GameSound_Category_'+name for name in categories]:self.assertIn(key,labels);self.assertNotIn('ProjectYakuza_',labels[key])
  sandbox=json.loads((media/'lua/shared/Translate/EN/Sandbox.json').read_text(encoding='utf-8'))
  for key in re.findall(r'\btranslation\s*=\s*(\w+)',(media/'sandbox-options.txt').read_text()):self.assertIn('Sandbox_'+key,sandbox);self.assertIn('Sandbox_'+key+'_tooltip',sandbox)
 def test_control_labels_keep_persistent_ids_and_remove_obsolete_entries(self):
  import re
  media=root/'combat/ProjectYakuza/42/media';labels=json.loads((media/'lua/shared/Translate/EN/UI.json').read_text(encoding='utf-8'));binding=(media/'lua/shared/ProjectYakuza/Bindings.lua').read_text();ids=re.findall(r'\{id="(\w+)",name=',binding)
  for name in ids:
   for prefix in ['Bind','Key']:self.assertIn('UI_ProjectYakuza_'+prefix+'_'+name,labels);self.assertNotIn('disabled',labels['UI_ProjectYakuza_'+prefix+'_'+name])
  self.assertNotIn('UI_ProjectYakuza_Bind_throw',labels)
if __name__=='__main__':unittest.main()
