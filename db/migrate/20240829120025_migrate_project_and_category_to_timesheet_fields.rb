class MigrateProjectAndCategoryToTimesheetFields < ActiveRecord::Migration[7.1]
  def up
    # Step 1: Iterate through each Timesheet and create corresponding TimesheetField records
    Timesheet.find_each do |timesheet|
      project_field = TimesheetField.create!(
        input_type: 'text',
        machine_name: 'project',
        title: 'Project',
        order: 1,
        metadata: {},
        timesheet: timesheet,
        popular: true,
        list: true,
        access_key: 'p',
      )

      category_field = TimesheetField.create!(
        input_type: 'text',
        machine_name: 'category',
        title: 'Category',
        order: 2,
        metadata: {},
        timesheet: timesheet,
        popular: true,
        list: true,
        access_key: 'c',
      )

      description_field = TimesheetField.create!(
        input_type: 'long_text',
        machine_name: 'description',
        title: 'Description',
        order: 3,
        metadata: {},
        timesheet: timesheet,
        access_key: 'd',
      )

      # Step 2: Migrate data to timesheet_fields_data_item for each Timesheet
      time_entries = TimeEntry.where(timesheet_id: timesheet.id)
      time_entries.find_each do |time_entry|
        if time_entry.project.present?
          TimesheetFieldDataItem.create!(
            field_id: project_field.id,
            time_entry_id: time_entry.id,
            value: time_entry.project,
            value_json: []
          )
        end

        if time_entry.category.present?
          TimesheetFieldDataItem.create!(
            field_id: category_field.id,
            time_entry_id: time_entry.id,
            value: time_entry.category,
            value_json: []
          )
        end

        if time_entry.description.present?
          TimesheetFieldDataItem.create!(
            field_id: description_field.id,
            time_entry_id: time_entry.id,
            value: time_entry.description,
            value_json: []
          )
        end
      end
    end

    # Step 3: Remove the old columns from time_entries
    remove_column :time_entries, :project
    remove_column :time_entries, :category
    remove_column :time_entries, :description
  end

  def down
    # Step 1: Recreate the old project, category, and description columns
    add_column :time_entries, :project, :string, limit: 100
    add_column :time_entries, :category, :string, limit: 100
    add_column :time_entries, :description, :text

    # Step 2: Restore project, category, and description data for each Timesheet
    Timesheet.find_each do |timesheet|
      project_field = TimesheetField.find_by(machine_name: 'project', timesheet: timesheet)
      category_field = TimesheetField.find_by(machine_name: 'category', timesheet: timesheet)
      description_field = TimesheetField.find_by(machine_name: 'description', timesheet: timesheet)

      if project_field
        TimesheetFieldDataItem.where(field_id: project_field.id).find_each do |data|
          time_entry = TimeEntry.find_by(id: data.time_entry_id)
          time_entry.update(project: data.value) if time_entry
        end
      end

      if category_field
        TimesheetFieldDataItem.where(field_id: category_field.id).find_each do |data|
          time_entry = TimeEntry.find_by(id: data.time_entry_id)
          time_entry.update(category: data.value) if time_entry
        end
      end

      if description_field
        TimesheetFieldDataItem.where(field_id: description_field.id).find_each do |data|
          time_entry = TimeEntry.find_by(id: data.time_entry_id)
          time_entry.update(description: data.value) if time_entry
        end
      end

      # Step 3: Clean up timesheet_fields_data_item
      TimesheetFieldDataItem.where(field_id: [project_field&.id, category_field&.id, description_field&.id]).delete_all if project_field && category_field && description_field
      # Step 4: Clean up timesheet_fields
      TimesheetField.where(machine_name: ['project', 'category', 'description'], timesheet: timesheet).destroy_all
    end
  end
end
