class RenameTimeEntryIdToItemId < ActiveRecord::Migration[7.2]
  def change
    rename_column :custom_field_data_items, :time_entry_id, :item_id
  end
end
