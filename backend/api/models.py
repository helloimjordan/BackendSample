from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
# Create your models here.

class Team(models.Model):
    name = models.CharField(max_length=60, blank=False, unique=True)
    honey_pot_ip = models.GenericIPAddressField(unique=True)
    score = models.IntegerField(default=0)
    team_password = models.CharField(max_length=100, blank=False)

    def __str__(self) -> str:
        return f"{self.name}"

class Player(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    team = models.ForeignKey(Team, on_delete=models.SET_DEFAULT, default=None, blank=True, null=True, related_name="players")

    def __str__(self) -> str:
        return self.user.username

class IncidentReport(models.Model):

    class Location(models.TextChoices):
        P80 = '80'
        P443 = '443'
        P3389 = '3389'
        P3306 = '3306'
        P25 = '25'
        SYSLOG = 'syslog'
        KERNLOG = 'kern.log'
        AUTHLOG = 'auth.log'
        DPKG = 'dpkg.log'

    class EventType(models.TextChoices):
        ATTACK = "Attack"
        ANOMALY = "Anomaly"
    
    class Tactic(models.TextChoices):
        RECONNAISSANCE = "Reconnaissance"
        RESOURCE_DEVELOPMENT = "Resource Development"
        INITIAL_ACCESS = "Initial Access"
        EXECUTION = "Execution"
        PERSISTENCE = "Persistence"
        PRIVILEGE_ESCALATION = "Privilege Escalation"
        DEFENSE_EVASION = "Defense Evasion"
        CREDENTIAL_ACCESS = "Credential Access"
        DISCOVERY = "Discovery"
        LATERAL_MOVEMENT = "Lateral Movement"
        COLLECTION = "Collection"
        COMMAND_AND_CONTROL = "Command and Control"
        EXFILTRATION = "Exfiltration"
        IMPACT = "Impact"
    

    created_at = models.DateTimeField(auto_now_add=True)
    location = models.TextField(choices=Location.choices, blank=False, default=Location.P80)
    tactic = models.CharField(max_length= 70,choices=Tactic.choices, default=Tactic.COLLECTION)
    team =  models.ForeignKey(Team, on_delete=models.CASCADE, blank=False)
    event_type = models.CharField(max_length=70, choices=EventType.choices, default=EventType.ANOMALY)   
    attack_time = models.DateTimeField(default=timezone.now)
    
    def __str__(self):
        template = '{0.location} {0.event_type} {0.tactic} {0.attack_time}'
        return template.format(self)


class MainWaterfallGraph(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    row = models.JSONField(blank=False)