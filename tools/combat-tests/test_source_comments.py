import ast
import unittest
from check_source_comments import clean,parts,signature

class SourceComments(unittest.TestCase):
    def test_lua(self):
        source='local a="-- literal";local b=[==[-- data\n]==] -- comment\nreturn a--[=[block]=]..b\n'
        output,count=clean(source,"lua")
        self.assertEqual(count,2)
        self.assertIn('"-- literal"',output)
        self.assertIn('[==[-- data\n]==]',output)
        self.assertEqual(signature(parts(source,"lua")),signature(parts(output,"lua")))
        self.assertEqual(clean(output,"lua")[1],0)
    def test_java(self):
        source='String url="https://host/path"; /* block */ int n=1; // tail\n'
        output,count=clean(source,"c")
        self.assertEqual(count,2)
        self.assertIn('"https://host/path"',output)
        self.assertIn('int n=1;',output)
    def test_python(self):
        source='"""Å module text."""\ndef f():\n    """Ü documentation."""\n    return "# string" # comment\n'
        output,count=clean(source,"python")
        self.assertEqual(count,3)
        self.assertIn('return "# string"',output)
        ast.parse(output)
        self.assertEqual(clean(output,"python")[1],0)
    def test_python_empty_body(self):
        output,count=clean('def f():\n    """Only documentation."""\n',"python")
        self.assertEqual(count,1)
        self.assertIsInstance(ast.parse(output).body[0].body[0],ast.Pass)
    def test_powershell(self):
        output,count=clean("$x='# kept'; <# block #> $y=1 # tail\n","ps1")
        self.assertEqual(count,2)
        self.assertIn("'# kept'",output)
        self.assertIn('$y=1',output)
    def test_xml(self):
        source='<?Owner data?><n><![CDATA[<!-- data -->]]><!-- comment --><x/></n>'
        output,count=clean(source,"xml")
        self.assertEqual(count,1)
        self.assertIn('<?Owner data?>',output)
        self.assertIn('<![CDATA[<!-- data -->]]>',output)
        self.assertNotIn('<!-- comment -->',output)

if __name__=='__main__':unittest.main()
