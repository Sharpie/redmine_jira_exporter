# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  post '/issues/:id/export_to_jira',   :to => 'issues#export_to_jira'
end
