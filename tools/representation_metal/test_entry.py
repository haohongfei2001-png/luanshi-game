from entry_config import project_config
import unittest
class EntryTests(unittest.TestCase):
    def test_replace_main_preserve_settings(self):
        p='config_version=5\n[application]\nconfig/name="original"\nrun/main_scene="res://game.tscn"\n[rendering]\nfoo=1\n'
        x=project_config(p)
        self.assertIn('config/name="original"',x)
        self.assertEqual(x.count('run/main_scene='),1)
        self.assertIn('[rendering]\nfoo=1\n',x)
        self.assertEqual(project_config(x),x)
    def test_missing_application_fails(self):
        with self.assertRaises(ValueError):project_config('[display]\na=1\n')
if __name__=='__main__':unittest.main()
