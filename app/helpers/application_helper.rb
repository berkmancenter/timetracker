# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def clean_username(username)
    username&.gsub(/\.law\.harvard\.edu|\.harvard\.edu/, '')
  end

  def icon_bool(value)
    class_name = 'timetracker-icon'

    if value
      image_tag('yes.svg', class: class_name)
    else
      image_tag('no.svg', class: class_name)
    end
  end
end
