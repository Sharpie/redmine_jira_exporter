module RedmineJiraExporter
  class IssueViewHook < Redmine::Hook::ViewListener

    def view_issues_show_details_bottom context = {}
      user = User.current
      issue = context [:issue]
      project = context[:project]

      # Attempt to log allthethings that can go wrong
      if project.nil?
        Rails.logger.error "jira_export_hook: No project in context for issue #{issue.id}. View hook aborting."
        return ''
      end

      # JIRA Export not enabled for this project. Bail out.
      return '' unless project.module_enabled? :jira_export
      return '' unless user.allowed_to? :view_jira_exports, project

      if RedmineJiraExporter.settings[:project_map].nil?
        Rails.logger.error "jira_export_hook: project_map hash not in settings.yaml. View hook aborting."
        return ''
      end
      jira_project = RedmineJiraExporter.settings[:project_map][project.name]

      if jira_project.nil?
        Rails.logger.debug "jira_export_hook: JIRA export enabled for Redmine project #{project.name}, but no entry in project_map from settings.yaml."
      end

      if issue.nil?
        Rails.logger.error "jira_export_hook: No issue in context. View hook aborting."
        return ''
      end

      unless issue.has_attribute? :jira_key
        Rails.logger.error "jira_export_hook: Issue objects do not have the jira_key column. A database migration may be required. View hook aborting."
        return ''
      end

      context[:jira_issue_url] = File.join(RedmineJiraExporter.settings[:jira_baseurl], 'browse', issue.jira_key) if issue.jira_key?
      context[:jira_export_available] = (not jira_project.nil?) && (not issue.closed?) && user.allowed_to?(:create_jira_exports, project)
      context[:jira_project] = jira_project if context[:jira_export_available]
      render context, :partial => 'issues/jira_export'
    end

    # Shamelessly ripped from lib/redmine/hooks.rb render_on
    def render context, options = {}
      if context[:hook_caller].respond_to?(:render)
        context[:hook_caller].send(:render, {:locals => context}.merge(options))
      elsif context[:controller].is_a?(ActionController::Base)
        context[:controller].send(:render_to_string, {:locals => context}.merge(options))
      else
        raise "Cannot render #{self.name} hook from #{context[:hook_caller].class.name}"
      end
    end

  end
end
