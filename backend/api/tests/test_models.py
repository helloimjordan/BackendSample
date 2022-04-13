"""
from django.test import TestCase

from ..models import IncidentReport
from .factories import IncidentReportFactory

class IncidentReportTestCase(TestCase):
	def test_str(self):
		Test for string representation
		incidentreport = IncidentReport()
		self.assertEqual(str(incidentreport), incidentreport.port)
"""""