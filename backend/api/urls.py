from django.urls import path, include
from .views import ReturnWebTools, UserViewset, IncidentReportViewSet, MainWaterfallGraphViewSet
from rest_framework import routers
from rest_framework.authtoken import views

"""
Django automatic URL routing for user
https://www.django-rest-framework.org/api-guide/routers/
"""
router = routers.DefaultRouter()
router.register("user", UserViewset)

"""
Sequence of url patterns Django looks for when this module loads.
If URL pattern matches, Django imports and calls given view.
https://docs.djangoproject.com/en/4.0/topics/http/urls/
"""
urlpatterns = [
    path("", include(router.urls)),
    path("ir-submissions", IncidentReportViewSet.as_view()),
    path('api-token-auth/', views.obtain_auth_token),
    path('waterfallGraph', MainWaterfallGraphViewSet.as_view()),
    path('web-tools/', ReturnWebTools.as_view()),
]
