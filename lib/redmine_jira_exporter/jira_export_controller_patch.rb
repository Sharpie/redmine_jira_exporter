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
      unless project.module_enabled?(:jira_export) and not jira_project.nil?
        Rails.logger.error "jira_export_controller: JIRA export enabled for redmine project #{project.name}, but no entry in project_map from settings.yaml" if jira_project.nil?
        return false
      end

      client = Net::HTTP.new jira_baseurl.host, jira_baseurl.port
      client.use_ssl = true

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

      # TODO: Error handling!
      resp = client.request request
      jira_id = JSON.load(resp.body)['key']

      remote_link_data = {
        'application' => {
          'name' => 'Puppet Labs Redmine'
        },
        'relationship' => 'clones',
        'object' => {
          'url'   => url_for(@issue),
          'title' => "(##{@issue.id}) #{@issue.subject}",
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

      # TODO: Error handling!
      resp = client.request request

      @issue.jira_url = File.join(jira_baseurl.to_s, 'browse', jira_id)
      @issue.save

      return true

    end
  end
end

IssuesController.send :include, RedmineJiraExporter::JiraExportControllerPatch
# Skip the authorize function as we have some specific issue/project
# interaction to take care of.
IssuesController.send :skip_before_filter, :authorize, :only => [:export_to_jira]
