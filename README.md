# Redmine JIRA Exporter

This is a simple Redmine plugin for self-service export of tickets to JIRA using v2 of the JIRA REST API.

## Caveat Utilitor

This plugin was developed for Redmine 2.2.1 runing under Rails 3.2.11.
It is alpha software and no guarentees are made as to usability or fitness for a particular purpose.

## Installation

Clone this repository into the `plugins` directory of your Redmine instance.
You may want to change the name such that this plugin appears last in an alphabetical sort:

    git clone https://github.com/Sharpie/redmine_jira_exporter redmine_zzz_jira_exporter

This will ensure the JIRA export banner appears on tickets below any custom fields added by other plugins.

Copy the `setting.yaml.example` file to `settings.yaml` and uncomment the data.
Edit as you see fit.

Stop Redmine and add the `jira_key` column to the issues table using the rake migration:

    rake redmine:plugins:migrate NAME=redmine_jira_exporter RAILS_ENV=production

Adjust the `NAME` argument if you supplied a different name for the plugin when cloning.

## Uninstallation

Stop Redmine and remove the `jira_key` column:

    rake redmine:plugins:migrate NAME=redmine_jira_exporter VERSION=0 RAILS_ENV=production

Remove the exporter from the `plugins` directory.
