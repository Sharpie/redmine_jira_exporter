require 'redmine_jira_exporter'

# Redmine doesn't have an obvious way to do per-project settings. So, as a
# workaround we load from a local `settings.yaml` file.
RedmineJIRAExporter.settings = YAML.load_file File.join(File.dirname(__FILE__), 'settings.yaml') rescue nil


if RedmineJIRAExporter.settings.nil?
  Rails.logger.error "jira_export_plugin: Failed to load settings file: #{File.join(File.dirname(__FILE__))}"
else
  # The File.basename hackery is so we can rename the plugin directory to
  # something like `redmine_zzz_jira_exporter` this causes all plugin hooks to be
  # fired last which puts content at the end of views instead of in the middle.
  Redmine::Plugin.register File.basename(File.dirname(__FILE__)).intern do
    name 'Redmine JIRA Exporter plugin'
    author 'Charlie Sharpsteen'
    description 'This plugin exports selected issues from Redmine to JIRA.'
    version '0.2.0'

    project_module :jira_export do
      permission :view_jira_exports, {:jira_export => :view}
      permission :create_jira_exports, {:jira_export => :create}
    end
  end
end
