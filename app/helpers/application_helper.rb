# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def clean_username(username)
    username.gsub(/\.law\.harvard\.edu|\.harvard\.edu/, '')
  end
end
