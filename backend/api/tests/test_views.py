"""
from django.tests import TestCase
from django.urls import reverse
from rest_framework import status

from .factories import IncidentReportFactory, UserFactory

class IncidentReportViewSetTestCase(TestCase):
	def test_post(self):
		POST to create an incident report
		data = {
			'port' = '80',
			'system' = 'syslog',
			'event_type' = 'Attack',
			'tactic' = 'Reconnaissance'
			'created_at' = 'timestamp'
			'team' = 'admin'
		}
		self.assertEqual(IncidentReport.objects.count(), 0)
		response = self.client.post(data=data)
		self.assertEqual(response.statis_code, status.HTTP_201_CREATED)
		self.assertEqual(IncidentReport.objects.count(), 1)
		incidentreport = IncidentReport.objects.all().first())
		for field_name in data.keys():
			self.assertEqual(gettattr(incidentreport, fieldname), data[field_name])
"""