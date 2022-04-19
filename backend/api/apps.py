from django.apps import AppConfig

"""
AppConfig subclass to be loaded automatically in INSTALLED_APPS
https://docs.djangoproject.com/en/3.2/ref/applications/#configuring-applications
"""
class ApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'api'


