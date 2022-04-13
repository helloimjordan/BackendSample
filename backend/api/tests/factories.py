'''
from factory import DjangoModelFactory, Faker
from ..models import IncidentReport

class IncidentReportFactory(DjangoModelFactory):
	port = Faker('port')
	system = Faker('log')
	event_type = Faker('type')
	tactic = Faker('text')
	created_at = Faker('time')
	team_id = Faker('id')

	class Meta:
		model = IncidentReport



'''