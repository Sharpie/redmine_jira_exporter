module RedmineJIRAExporter
  class JIRAExportListener < Redmine::Hook::ViewListener

    def view_issues_show_details_bottom context = {}
      user = User.current

      return '' unless user.allowed_to? :view_jira_exports, context[:project]

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
