module RedmineJIRAExporter
  class << self
    attr_accessor :settings
  end
end

require 'redmine_jira_exporter/jira_export_hook'
