from django.shortcuts import get_object_or_404
from rest_framework.serializers import ModelSerializer
from rest_framework import serializers
from .models import IncidentReport, MainWaterfallGraph, Team
from django.contrib.auth.models import User


"""
Incident report serializer 
"""
class IncidentReportSerializer(ModelSerializer):
	class Meta:
		model = IncidentReport
		fields = (
			'id', "location", 'tactic','team','attack_time', 'attack_time',
		)

"""
User serializer
"""
class UserSerializer(serializers.ModelSerializer):
	class Meta:
		model = User
		fields = ("username", "password",)

		
"""
Waterfall graph serialzer - data is curled from admin honeypot
"""
class MainWaterfallGraphSerializer(serializers.ModelSerializer):
	ip = serializers.CharField(write_only=True)
	class Meta:
		model = MainWaterfallGraph
		fields = ("row", "ip",)

	def create(self, validated_data):
		row_activity_bin_str = validated_data["row"]
		incoming_req_ip = validated_data["ip"]

		# Check to see if incoming request has valid ip in body
		if not Team.objects.filter(honey_pot_ip=incoming_req_ip).exists():
			raise serializers.ValidationError("ip not allowed")
		# Maps indexes of a string to a port or log, ordered by how the its done in
		# the frontend from left to right
		try:
			row_map = {
				"p80": row_activity_bin_str[0],
				"p443": row_activity_bin_str[1],
				"p3389": row_activity_bin_str[2],
				"p3306": row_activity_bin_str[3],
				"p25": row_activity_bin_str[4],
				"syslog": row_activity_bin_str[5],
				"kernlog": row_activity_bin_str[6],
				"authlog": row_activity_bin_str[7],
				"dpkglog": row_activity_bin_str[8],
			}
		except IndexError:
			raise serializers.ValidationError("Error orccured indexing string to dic")

		return MainWaterfallGraph.objects.create(row=row_map)
