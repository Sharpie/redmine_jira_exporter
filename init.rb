require_dependency 'redmine_jira_exporter/jira_export_hook'

Redmine::Plugin.register :redmine_jira_exporter do
  name 'Redmine JIRA Exporter plugin'
  author 'Charlie Sharpsteen'
  description 'This plugin exports selected issues from Redmine to JIRA.'
  version '0.0.1'
end
