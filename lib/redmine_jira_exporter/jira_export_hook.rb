module RedmineJIRAExporter
  class JIRAExportHook < Redmine::Hook::ViewListener

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

      if ::RedmineJIRAExporter.settings[:project_map].nil?
        Rails.logger.error "jira_export_hook: project_map hash not in settings.yaml. View hook aborting."
        return ''
      end
      jira_project = ::RedmineJIRAExporter.settings[:project_map][project.name]

      if jira_project.nil?
        Rails.logger.error "jira_export_hook: JIRA export enabled for Redmine project #{project.name}, but no entry in project_map from settings.yaml. View hook aborting."
        return ''
      end

      if issue.nil?
        Rails.logger.error "jira_export_hook: No issue in context. View hook aborting."
        return ''
      end

      unless issue.has_attribute? :jira_url
        Rails.logger.error "jira_export_hook: Issue objects do not have the jira_url column. A database migration may be required. View hook aborting."
        return ''
      end

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
