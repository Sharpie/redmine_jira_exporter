class CreateJiraExports < ActiveRecord::Migration
  def up
    add_column :issues, :jira_url, :string
  end

  def down
    remove_column :issues, :jira_url
  end
end
