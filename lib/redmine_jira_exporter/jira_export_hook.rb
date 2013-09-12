module RedmineJIRAExporter
  class JIRAExportListener < Redmine::Hook::ViewListener
    render_on :view_issues_show_details_bottom, :partial => 'issues/jira_export'
  end
end
