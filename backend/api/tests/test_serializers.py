
"""
from django.test import Test

from ..serializers import IncidentReportSerializer 
from .factories import IncidentReportFactory

class IncidentReportSerializer(TestCase):
	def test_model_fields(self):
		Serializer data atches the Comany object for each field
		incidentreport = IncidentReport()
		for field_name in [
			'id', 'port', 'system', 'event_type', 'created_at', 'team'
		]:
			self.assertEqual(
				serializer.data[field_name],
				getattr(incidentreport, field_name)
			)
"""