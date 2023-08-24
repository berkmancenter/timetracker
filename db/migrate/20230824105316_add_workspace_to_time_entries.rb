class AddWorkspaceToTimeEntries < ActiveRecord::Migration[7.0]
  def change
    default_workspace = Workspace.create(name: 'Default Workspace')
    add_reference :time_entries, :workspace, null: false, foreign_key: true, default: default_workspace.id
    change_column_default :time_entries, :workspace_id, from: default_workspace.id
  end
end
