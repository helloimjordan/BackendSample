# Generated by Django 4.0.3 on 2022-04-01 22:08

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0007_alter_player_team'),
    ]

    operations = [
        migrations.CreateModel(
            name='IncidentReport',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('port', models.IntegerField(choices=[(80, 'Port80'), (443, 'Port443'), (3389, 'Port3389'), (3306, 'Port3306'), (25, 'Port25')])),
            ],
        ),
    ]
