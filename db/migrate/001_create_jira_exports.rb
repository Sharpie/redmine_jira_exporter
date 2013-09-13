class CreateJiraExports < ActiveRecord::Migration
  def change
    create_table :jira_exports do |t|
      t.integer :issue_id
      t.string :jira_url
    end
  end
end
