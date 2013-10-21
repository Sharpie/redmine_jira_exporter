module RedmineJiraExporter
  class << self
    attr_accessor :settings
  end
end

require 'redmine_jira_exporter/issue_view_hook'
require 'redmine_jira_exporter/controller_patch'
