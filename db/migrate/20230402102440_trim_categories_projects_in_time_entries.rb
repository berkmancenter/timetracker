class TrimCategoriesProjectsInTimeEntries < ActiveRecord::Migration[7.0]
  def change
    sql = '
      UPDATE
        time_entries
      SET
        category = TRIM(category),
        project = TRIM(project)
    '
    ActiveRecord::Base.connection.execute(sql)
  end
end
