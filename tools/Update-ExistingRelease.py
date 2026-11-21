from pathlib import Path
import argparse,hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]

def checked_run(args):
 result=subprocess.run(args,capture_output=True)
 if result.returncode:raise RuntimeError(result.stderr.decode('utf-8','replace'))
 return result.stdout

def api(gh,repo,method,path,data=None):
 args=[gh,'api','--method',method,'repos/'+repo+path]
 if data is not None:args+=['--input','-']
 result=subprocess.run(args,input=json.dumps(data).encode('utf-8')if data is not None else None,capture_output=True)
 if result.returncode:raise RuntimeError(result.stderr.decode('utf-8','replace'))
 return json.loads(result.stdout)if result.stdout.strip()else None

def verify_assets(assets,archives):
 actual={a['name']:a for a in assets}
 for archive in archives:
  asset=actual.get(archive.name);assert asset and asset['state']=='uploaded','New archive is not uploaded: '+archive.name
  assert asset['size']==archive.stat().st_size,'New archive size differs: '+archive.name
  assert asset['digest']=='sha256:'+hashlib.sha256(archive.read_bytes()).hexdigest(),'New archive digest differs: '+archive.name

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--gh',required=True);parser.add_argument('--repo',required=True);parser.add_argument('--tag',required=True);parser.add_argument('--commit',required=True);parser.add_argument('--expected-release-id',type=int,required=True);parser.add_argument('--expected-tag-sha',required=True);parser.add_argument('--notes',type=Path,required=True);parser.add_argument('--archive',type=Path,action='append',required=True);args=parser.parse_args()
 assert re.fullmatch(r'v\d+(?:\.\d+){0,2}',args.tag)and re.fullmatch(r'[0-9a-f]{40}',args.commit)
 gh=str(Path(args.gh).resolve());archives=[p.resolve()for p in args.archive];assert len(archives)==2 and len({p.name for p in archives})==2 and all(p.is_file()and p.suffix=='.zip'for p in archives)
 release=api(gh,args.repo,'GET','/releases/tags/'+args.tag);assert release['id']==args.expected_release_id,'Selected release changed'
 tag=api(gh,args.repo,'GET','/git/ref/tags/'+args.tag);assert tag['object']['sha']==args.expected_tag_sha,'Selected tag changed'
 backup=ROOT/'tools/release-update-backups'/(args.tag+'-'+args.commit+'.json');backup.parent.mkdir(parents=True,exist_ok=True)
 if not backup.exists():backup.write_text(json.dumps({'release':release,'tag':tag},indent=2),encoding='utf-8')
 for asset in release['assets']:
  candidates=[ROOT/'dist'/asset['name'],ROOT/'tools/release-update-backups'/args.tag/asset['digest'].removeprefix('sha256:')/asset['name']]
  assert any(old.is_file()and 'sha256:'+hashlib.sha256(old.read_bytes()).hexdigest()==asset['digest']for old in candidates),'Previous archive is not backed up locally: '+asset['name']
 checked_run([gh,'release','upload',args.tag,*map(str,archives),'--repo',args.repo,'--clobber'])
 uploaded=api(gh,args.repo,'GET','/releases/tags/'+args.tag);verify_assets(uploaded['assets'],archives)
 tag=api(gh,args.repo,'GET','/git/ref/tags/'+args.tag);assert tag['object']['sha']==args.expected_tag_sha,'Selected tag changed during upload'
 api(gh,args.repo,'PATCH','/git/refs/tags/'+args.tag,{'sha':args.commit,'force':True})
 api(gh,args.repo,'PATCH','/releases/'+str(args.expected_release_id),{'name':args.tag,'body':args.notes.read_text(encoding='utf-8-sig'),'target_commitish':args.commit,'make_latest':'true'})
 names={p.name for p in archives}
 for asset in release['assets']:
  if asset['name']not in names:api(gh,args.repo,'DELETE','/releases/assets/'+str(asset['id']))
 final=api(gh,args.repo,'GET','/releases/tags/'+args.tag);verify_assets(final['assets'],archives);assert {a['name']for a in final['assets']}==names
 assert api(gh,args.repo,'GET','/git/ref/tags/'+args.tag)['object']['sha']==args.commit
 print(json.dumps({'url':final['html_url'],'releaseIdPreserved':final['id']==args.expected_release_id,'tag':args.tag,'commit':args.commit,'assets':[{'name':a['name'],'digest':a['digest']}for a in final['assets']]}))
if __name__=='__main__':main()
