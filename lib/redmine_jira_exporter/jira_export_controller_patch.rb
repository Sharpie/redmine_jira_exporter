module RedmineJiraExporter
  module JiraExportControllerPatch

    def export_to_jira
      # FIXME: This should be a before_filter
      find_issue # <-- populates @issue
      project = @issue.project

      unless User.current.allowed_to? :create_jira_exports, project
        deny_access
        return
      end

      # TODO: Encase this in Issue.transaction
      @issue.jira_url = 'https://jira6-public.puppetlabs.com/browse/TEST-13'
      @issue.save
      flash[:notice] = 'Issue successfully exported to JIRA.'

      # Need to use this instead of `redirect_to`. Otherwise changes don't show
      # up until the view is reloaded.
      redirect_back_or_default :action => 'show', :id => @issue
    end

  end
end

IssuesController.send :include, RedmineJiraExporter::JiraExportControllerPatch
# Skip the authorize function as we have some specific issue/project
# interaction to take care of.
IssuesController.send :skip_before_filter, :authorize, :only => [:export_to_jira]
