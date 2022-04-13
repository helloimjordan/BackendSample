# Generated by Django 4.0.3 on 2022-04-04 23:03

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0020_alter_incidentreport_port_and_more'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='incidentreport',
            name='port',
        ),
        migrations.RemoveField(
            model_name='incidentreport',
            name='system',
        ),
        migrations.AddField(
            model_name='incidentreport',
            name='location',
            field=models.TextField(choices=[('80', 'P80'), ('443', 'P443'), ('3389', 'P3389'), ('3306', 'P3306'), ('25', 'P25'), ('syslog', 'Syslog'), ('kern.log', 'Kernlog'), ('auth.log', 'Authlog'), ('dpkg.log', 'Dpkg')], default='80'),
        ),
    ]
