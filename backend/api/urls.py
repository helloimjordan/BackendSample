from django.urls import path, include
from .views import ReturnWebTools, UserViewset, IncidentReportViewSet, MainWaterfallGraphViewSet
from rest_framework import routers
from rest_framework.authtoken import views

router = routers.DefaultRouter()
router.register("user", UserViewset)
#router.register("web-tools", send_webtool_info, basename="tools")
# router.register("team", TeamViewSet, basename="Team")

urlpatterns = [
    path("", include(router.urls)),
    path("ir-submissions", IncidentReportViewSet.as_view()),
    path('api-token-auth/', views.obtain_auth_token),
    path('waterfallGraph', MainWaterfallGraphViewSet.as_view()),
    path('web-tools/', ReturnWebTools.as_view()),
]
