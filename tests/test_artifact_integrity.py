"""Static artifact tests (no SQL Server/Talend execution). Run: python -m unittest discover -s tests -v"""
import unittest, zipfile, re, base64, io
from pathlib import Path
from lxml import etree as ET
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
class ArtifactIntegrity(unittest.TestCase):
    def test_six_true_talend_screenshots(self):
        screenshots=list((ROOT/'assets/talend-screenshots').glob('j_*.png'))
        self.assertEqual(len(screenshots),6)
        for p in screenshots:
            with Image.open(p) as im:
                self.assertGreater(im.width, 800)
                self.assertGreater(im.height, 500)
                im.verify()
    def test_sanitized_job_designs(self):
        zip_path=ROOT/'talend/CityBike_Talend_Sanitized_Job_Designs.zip'
        with zipfile.ZipFile(zip_path) as z:
            items=[n for n in z.namelist() if '/process/' in n and n.endswith('.item')]
            self.assertEqual(len(items),6)
            for n in z.namelist():
                if n.endswith('.item'):
                    xml=ET.fromstring(z.read(n))
                    for el in xml.iter():
                        if el.tag.endswith('contextParameter'):
                            self.assertFalse(el.get('value',''), n)
                        if el.tag.endswith('elementParameter'):
                            prop=(el.get('name') or '').upper()
                            if prop in ('PASS','PASSWORD','HOST','SERVER','USER','LOGIN','PORT','DBNAME','DATABASE','SCHEMA_DB','DB_SCHEMA','URL','JDBC_URL','ADDITIONALPARAMS'):
                                v=(el.get('value') or '').lstrip()
                                self.assertTrue(not v or v.startswith(('context.','((String)context.','globalMap.get(')), (n,prop))
    def test_project_sql_assets_present(self):
        for p in ['sql/source/citybike_source_pg.sql','sql/source/citybike_changes_pg.sql','sql/setup/citybike_dw_skeleton_mssql.sql','sql/validation/acceptance_checks.sql','sql/analytics/business_questions.sql']:
            self.assertTrue((ROOT/p).is_file(),p)
    def test_expected_not_reported_as_observed(self):
        readme=(ROOT/'README.md').read_text(encoding='utf8')
        self.assertIn('not reproduced SQL results', readme)
        self.assertIn('not proof of successful execution', readme)
if __name__=='__main__':unittest.main()
