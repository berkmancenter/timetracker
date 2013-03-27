# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  protect_from_forgery # :secret => '8884fd422a761676cb1a65b799ad4d2f'

  before_filter :is_authenticated

  def get_active_users
    unless session["#{@session_user.id}_active_users"].blank?
      return session["#{@session_user.id}_active_users"]
    else
      return [@session_user]
    end
  end

  protected

  def render_csv(param)
    param[:filebase] = param[:filebase].blank? ? param[:model].to_s.tableize : param[:filebase]

    if param[:columns].blank? 
      param[:columns] = param[:model].columns.collect{|c| c.name}
    end
    csv_string = FasterCSV.generate do |csv|
      csv << param[:columns]
      param[:objects].each do |record|
        line = param[:columns].collect{|col| record[col].to_s.chomp}
        csv << line
      end
    end
    send_data(csv_string,
              :type => 'application/octet-stream',
              :filename => "#{param[:filebase]}-#{Time.now.to_s(:number)}.csv")
  end

  def is_authenticated
    authenticate_or_request_with_http_basic 'Time Tracking' do |user_name, password|
     u = User.authenticate(user_name,password)
     if u.blank?
      return false
     else
      @session_user = u
     end
    end
  end

  def is_admin
    @session_user.superadmin
  end

end
