from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.http import HttpRequest
from .models import Player, Team, IncidentReport, MainWaterfallGraph
from django.contrib.auth.models import User
from django.db.models import Count

class PlayerInLine(admin.StackedInline):
    model = Player
    can_delete = False
    extra = 0
    verbose_name_plural = "Players"

class IncidentReportInLine(admin.TabularInline):
    model = IncidentReport
    extra = 0
   
class UserAdmin(BaseUserAdmin):
    inlines = (PlayerInLine, )

class TeamAdmin(admin.ModelAdmin):
    list_display = ("name", "honey_pot_ip", "score", "number_of_players",)
    inlines = (PlayerInLine, IncidentReportInLine, )

    def number_of_players(self, obj):
        return obj.number_of_players
    
    def get_queryset(self, request: HttpRequest):
        queryset = super().get_queryset(request)
        queryset = queryset.annotate(number_of_players=Count("players"))
        return queryset
        
@admin.register(IncidentReport)
class IncidentReportAdmin(admin.ModelAdmin):
    readonly_fields = ("created_at",)
    fields = ("created_at", "team", "location", "tactic", "event_type", "attack_time",)
    list_display = ("id", "team", "location", "tactic", "created_at", "attack_time",)
    search_fields = ("team", "location", "tactic", "attack_time", "created_at",)

class PlayerAdmin(admin.ModelAdmin):
    list_display = ("user", "team",)

@admin.register(MainWaterfallGraph)
class MainWaterfallGraphAdmin(admin.ModelAdmin):
    readonly_fields = ("created_at",)
    fields = ("created_at", "row",)
    list_display = ("created_at",)

admin.site.unregister(User)
admin.site.register(User, UserAdmin)
admin.site.register(Team, TeamAdmin)
admin.site.register(Player, PlayerAdmin)