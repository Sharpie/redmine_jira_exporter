class CreateJiraExports < ActiveRecord::Migration
  def up
    add_column :issues, :jira_key, :string
  end

  def down
    remove_column :issues, :jira_key
  end
end
