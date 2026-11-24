class ShowDescriptionFieldsInTable < ActiveRecord::Migration[8.1]
  # The entries list showed the "description" field always, also when
  # "Show in table" was off (the old migration made it like that). Now the list
  # follows "Show in table", so it's turned on to keep the descriptions visible.
  def up
    updated_count = exec_update(<<~SQL.squish)
      UPDATE custom_fields
      SET list = TRUE, updated_at = NOW()
      WHERE customizable_type = 'Timesheet'
        AND machine_name = 'description'
        AND input_type = 'long_text'
        AND list = FALSE
    SQL

    say "Turned on \"Show in table\" for #{updated_count} description fields"
  end

  # We don't know which fields had it off before, so nothing is changed back.
  def down; end
end
