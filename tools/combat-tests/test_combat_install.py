from pathlib import Path
import importlib.util,tempfile,unittest

root=Path(__file__).resolve().parents[2];spec=importlib.util.spec_from_file_location('combat_install',root/'tools/Install-CombatUpdate.py');installer=importlib.util.module_from_spec(spec);spec.loader.exec_module(installer)

class CombatInstallTests(unittest.TestCase):
 def prepare(self,folder):
  base=Path(folder);mod=base/'source';game=base/'Zomboid';backup=base/'backup';stage=base/'package'
  for name,data in {'42/mod.info':b'name=Project Yakuza\nid=ProjectYakuza\nversion=1.2.3\n','42/media/lua/shared/Test.lua':b'return true'}.items():
   for destination in [mod/name,stage/'Contents/mods/ProjectYakuza'/name]:destination.parent.mkdir(parents=True,exist_ok=True);destination.write_bytes(data)
  (stage/'preview.png').write_bytes(b'supplied preview');(stage/'workshop.txt').write_bytes(b'version=1\ntitle=Project Yakuza\nvisibility=private\n')
  return mod,game,backup,stage
 def test_archives_shadowing_stages_preserves_item_id_and_verifies_runtime(self):
  with tempfile.TemporaryDirectory()as folder:
   mod,game,backup,stage=self.prepare(folder);old=game/'Workshop/ProjectYakuza-v1.0.0';payload=old/'Contents/mods/ProjectYakuza'
   for destination in [payload/'42/mod.info',game/'mods/ProjectYakuza/42/mod.info']:destination.parent.mkdir(parents=True,exist_ok=True);destination.write_bytes(b'id=ProjectYakuza\nversion=1.0.0\n')
   (old/'workshop.txt').write_bytes(b'version=1\nid=123456\ntitle=Existing item\n');(old/'preview.png').write_bytes(b'old preview')
   obsolete=game/'mods/ProjectYakuza/42/media/lua/shared/Old.lua';obsolete.parent.mkdir(parents=True);obsolete.write_bytes(b'return false')
   other=game/'Workshop/OtherMod/Contents/mods/Other';other.mkdir(parents=True);(other/'keep.txt').write_bytes(b'unchanged')
   report=installer.install(mod,'1.2.3',game,backup,stage)
   self.assertEqual(report['backedUp'],2);self.assertEqual(len(report['archivedWorkshopStages']),1);self.assertTrue(report['verified']);self.assertFalse(old.exists());self.assertEqual((backup/'workshop/ProjectYakuza-v1.0.0/preview.png').read_bytes(),b'old preview')
   self.assertEqual((backup/'replaced/42/media/lua/shared/Old.lua').read_bytes(),b'return false');self.assertFalse(obsolete.exists());self.assertEqual((other/'keep.txt').read_bytes(),b'unchanged')
   current=game/'Workshop/ProjectYakuza-v1.2.3';self.assertIn(b'id=123456',(current/'workshop.txt').read_bytes())
   again=installer.install(mod,'1.2.3',game,backup,stage);self.assertEqual(again['written'],0);self.assertEqual(again['backedUp'],0);self.assertEqual(again['archivedWorkshopStages'],[])
 def test_mixed_mod_stage_rejected_before_install(self):
  with tempfile.TemporaryDirectory()as folder:
   mod,game,backup,stage=self.prepare(folder);old=game/'Workshop/Old/Contents/mods';payload=old/'ProjectYakuza/42';payload.mkdir(parents=True);(payload/'mod.info').write_text('id=ProjectYakuza\n');(old/'AnotherMod').mkdir()
   with self.assertRaises(AssertionError):installer.install(mod,'1.2.3',game,backup,stage)
   self.assertFalse((game/'mods').exists());self.assertTrue(payload.exists())
 def test_backup_inside_loadable_game_cache_rejected(self):
  with tempfile.TemporaryDirectory()as folder:
   mod,game,backup,stage=self.prepare(folder)
   with self.assertRaises(AssertionError):installer.install(mod,'1.2.3',game,game/'Workshop/backup',stage)
 def test_conflicting_workshop_ids_preserve_originals(self):
  with tempfile.TemporaryDirectory()as folder:
   mod,game,backup,stage=self.prepare(folder)
   for name,item in [('Old1',123),('Old2',456)]:
    old=game/'Workshop'/name;payload=old/'Contents/mods/ProjectYakuza/42';payload.mkdir(parents=True);(payload/'mod.info').write_text('id=ProjectYakuza\n');(old/'workshop.txt').write_text('id='+str(item)+'\n')
   with self.assertRaises(AssertionError):installer.install(mod,'1.2.3',game,backup,stage)
   self.assertFalse(backup.exists());self.assertEqual(len(list((game/'Workshop').iterdir())),2)

if __name__=='__main__':unittest.main()
