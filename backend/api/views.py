from django.http import HttpRequest
from rest_framework import viewsets, mixins
from rest_framework.generics import CreateAPIView, ListCreateAPIView
from .models import IncidentReport, Player, Team, MainWaterfallGraph
from .serializers import IncidentReportSerializer, UserSerializer, MainWaterfallGraphSerializer
from rest_framework.response import Response
from rest_framework.decorators import api_view
from django.contrib.auth.models import User
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication
from rest_framework.authtoken.models import Token
from rest_framework.authtoken.views import ObtainAuthToken



class UserViewset(viewsets.ModelViewSet):
	queryset = User.objects.all()
	serializer_class = UserSerializer 


class IncidentReportViewSet(CreateAPIView):
	authentication_classes = [TokenAuthentication, ]
	permission_classes = [IsAuthenticated]
	serializer_class = IncidentReportSerializer
	query_set = IncidentReport.objects.all()


# class TeamViewSet(viewsets.ModelViewSet):
# 	# queryset = Team.objects.f
# 	# authentication_classes = [TokenAuthentication, ]
# 	# permission_classes = [IsAuthenticated]
# 	serializer_class = TeamSerializer

# 	def get_queryset(self):
# 		player = Player.objects.filter(user=self.request.user)
# 		return

class MainWaterfallGraphViewSet(ListCreateAPIView):
	queryset = MainWaterfallGraph.objects.all()
	serializer_class = MainWaterfallGraphSerializer

	def get_queryset(self):
		#latest_12_rows = MainWaterfallGraph.objects.order_by("created_at")[:12:-1]
		latest_12_rows = {"row":{"p80":"0","p443":"1","p3389":"0","p3306":"1","p25":"0","syslog":"1","kernlog":"0","authlog":"1","dpkglog":"0"}}                                                                                                           
		return latest_12_rows


class ReturnWebTools(ObtainAuthToken):
	def post(self, request, *args, **kwargs):
		response = super(ReturnWebTools, self).post(request, *args, **kwargs)
		token = Token.objects.get(key=response.data['token'])
		player_id = token.user_id
		honeypot_ip = Team.objects.get(pk=player_id).honey_pot_ip		
		protocols = ['http://','https://']
		data = {
		'current user id':2,
		'honeypot_ip': protocols[1]+honeypot_ip+':64297',
		'splunk':protocols[0]+honeypot_ip+':8010',
		'wazuh':protocols[1]+honeypot_ip+':5601',
		'nessus':protocols[1]+honeypot_ip+':8840',
		'velociraptor':protocols[1]+honeypot_ip+':8889'
		}

		return Response(data=data)
