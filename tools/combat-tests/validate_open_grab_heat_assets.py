from pathlib import Path
import sys,subprocess
script=Path(__file__).with_name('validate_contact_repairs.py')
subprocess.run([sys.executable,str(script)],check=True)
