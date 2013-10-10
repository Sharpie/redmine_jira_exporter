require 'net/http'
require 'uri'
require 'json'

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

      if post_to_jira
        flash[:notice] = 'Issue successfully exported to JIRA.'
      else
        flash[:warning] = 'Failed to export issue to JIRA.'
      end

      # Need to use this instead of `redirect_to`. Otherwise changes don't show
      # up until the view is reloaded.
      redirect_back_or_default :action => 'show', :id => @issue
    end

    private

    def post_to_jira
      jira_api_path = 'rest/api/2'
      project = @issue.project

      return false unless project.module_enabled?(:jira_export)

      if @issue.jira_url?
        Rails.logger.warn "jira_export_controller: Issue already exported to #{@issue.jira_url}"
        return false
      end

      if @issue.closed?
        Rails.logger.warn "jira_export_controller: Issue ##{@issue.id} is closed, not exporting."
        return false
      end

      jira_baseurl = URI.parse ::RedmineJIRAExporter.settings[:jira_baseurl]
      jira_username = ::RedmineJIRAExporter.settings[:jira_username]
      jira_password = ::RedmineJIRAExporter.settings[:jira_password]
      if jira_baseurl.nil? or jira_username.nil? or jira_password.nil?
        Rails.logger.error "jira_export_controller: JIRA URL and credentials not supplied in settings.yaml"
        return false
      end

      if ::RedmineJIRAExporter.settings[:project_map].nil?
        Rails.logger.error "jira_export_controller: project_map hash not in settings.yaml"
        return false
      end

      jira_project = ::RedmineJIRAExporter.settings[:project_map][project.name]
      if jira_project.nil?
        Rails.logger.error "jira_export_controller: JIRA export enabled for redmine project #{project.name}, but no entry in project_map from settings.yaml" if jira_project.nil?
        return false
      end

      client = Net::HTTP.new jira_baseurl.host, jira_baseurl.port
      client.use_ssl = jira_baseurl.scheme == 'https'

      issue_data = {
        "fields" => {
          "project" =>
          {
            "key" => jira_project
          },
          "summary" => @issue.subject,
          "description" => @issue.description,
          "issuetype" => {
            "name" => "Bug"
          }
        }
      }

      request = Net::HTTP::Post.new File.join(jira_baseurl.request_uri, jira_api_path, 'issue')
      request.basic_auth jira_username, jira_password
      request.body = issue_data.to_json
      request['content-type'] = 'application/json'

      resp = client.request request
      unless resp.kind_of? Net::HTTPSuccess
        Rails.logger.error "jira_export_controller: JIRA issue creation failed with code: #{resp.code}"
        return false
      end
      jira_id = JSON.load(resp.body)['key']

      # At this point, the ticket has been created in JIRA, so save the URL to
      # the database
      @issue.jira_url = File.join(jira_baseurl.to_s, 'browse', jira_id)
      @issue.save

      # Also persist a new Journal entry to trigger email notifications.
      journal_note = <<-EOF
Redmine Issue [##{@issue.id}](#{url_for(@issue)}) has been migrated to JIRA:

  <#{@issue.jira_url}>
        EOF
      @issue.init_journal(User.current, journal_note).save

      # Add remote links for this issue and each issue linked to it or from it.
      @issue.relations.map{|r| [r.issue_to, r.issue_from]}.flatten.uniq.each do |i|

        remote_link_data = {
          'application' => {
            'name' => 'Puppet Labs Redmine'
          },
          'relationship' => ( (i.id == @issue.id) ? 'clones' : 'relates to' ),
          'object' => {
            'url'   => url_for(i),
            'title' => "(##{i.id}) #{i.subject}",
            'icon'  => {
              'url16x16' => 'http://projects.puppetlabs.com/favicon.ico',
              'title'    => 'Redmine'
            }
          }
        }

        request = Net::HTTP::Post.new File.join(jira_baseurl.request_uri, jira_api_path, 'issue', jira_id, 'remotelink')
        request.basic_auth jira_username, jira_password
        request.body = remote_link_data.to_json
        request['content-type'] = 'application/json'

        resp = client.request request
        unless resp.kind_of? Net::HTTPSuccess
          Rails.logger.error "jira_export_controller: JIRA issue crosslinking failed with code: #{resp.code}"
          # Don't return false, because at this point there is an exported ticket
          # in JIRA.
        end

      end # End big ugly issue loop

      return true

    end
  end
end

IssuesController.send :include, RedmineJiraExporter::JiraExportControllerPatch
# Skip the authorize function as we have some specific issue/project
# interaction to take care of.
IssuesController.send :skip_before_filter, :authorize, :only => [:export_to_jira]
