from pathlib import Path
import importlib.util,tempfile,unittest
ROOT=Path(__file__).resolve().parents[2];spec=importlib.util.spec_from_file_location('release',ROOT/'tools/Build-ReleaseRuntime.py');release=importlib.util.module_from_spec(spec);spec.loader.exec_module(release)
class ReleaseRuntimeTests(unittest.TestCase):
 def test_script_filter_keeps_adjacent_native_models_and_quoted_braces(self):
  text='module Base { model ProjectYakuza_EmptyHand { mesh = Empty, } model ProjectYakuza_BeerCrate { attachment prop { value = "}" } } model Katana { mesh = Native, } }'
  result=release.named_blocks(text);self.assertIn('model Katana { mesh = Native, }',result);self.assertIn('ProjectYakuza_EmptyHand',result);self.assertNotIn('BeerCrate',result)
 def test_nested_scene_and_numeric_metadata_filters_preserve_retained_values(self):
  text='data={["moves"]={["knife"]={value="a}b"},["crate"]={nested={1,2}}},["leads"]={["CrateHit.wav"]=25,["KatanaHit.wav"]=100},["lastBicycle"]=true}'
  result=release.keyed(text);self.assertIn('["knife"]={value="a}b"}',result);self.assertIn('["KatanaHit.wav"]=100',result);self.assertNotIn('crate',result);self.assertNotIn('Bicycle',result)
 def test_plain_sources_and_native_media_keep_exact_bytes(self):
  with tempfile.TemporaryDirectory()as folder:
   mod=Path(folder)/'ReleaseFixture';names={'42/mod.info':b'id=Test','42/media/lua/shared/Test.lua':b'return true','42/media/anims_X/Bob/ProjectYakuza_DD_KnifeHeat.x':b'original native motion','42/media/models_X/Static/ProjectYakuza_BeerCrate.x':b'original custom model'};files={}
   for name,data in names.items():
    p=mod/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data);files[name]=p
   result=release.release_files(mod,files);self.assertEqual(len(result),3)
   for name,p in result.items():self.assertEqual(p.read_bytes(),names[name]);self.assertEqual(p,files[name])
   self.assertTrue(files['42/media/models_X/Static/ProjectYakuza_BeerCrate.x'].exists())
 def test_missing_style_boundary_fails_before_distribution(self):
  with self.assertRaises(AssertionError):release.transform('42/media/lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua','return true')
if __name__=='__main__':unittest.main()
