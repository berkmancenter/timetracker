class PeriodsController < ApplicationController
  before_action :set_period, except: %i[index upsert delete]
  before_action :authenticate_user_json!

  PERIOD_PUBLIC_FIELDS = {
    only: %i[id timesheet_id name from to],
    include: {
      timesheet: { only: %i[id name] }
    }
  }.freeze

  # GET /timesheets/:timesheet_id/periods
  # Returns all periods for the current user
  def index
    timesheet = Timesheet.find(params[:timesheet_id])
    periods = Period.timesheet_periods(timesheet)

    render json: periods.as_json(PERIOD_PUBLIC_FIELDS), status: :ok
  end

  # GET /timesheets/:timesheet_id/periods/:id
  # Returns a specific period
  def show
    return render_unauthorized unless user_can_manage_timesheet?(@period.timesheet)

    render json: @period.as_json(PERIOD_PUBLIC_FIELDS), status: :ok
  end

  # POST /timesheets/:timesheet_id/periods/upsert
  # Creates or updates a period
  def upsert
    period = find_or_initialize_period

    return render_bad_request if period.timesheet.nil?
    return render_unauthorized unless user_can_manage_timesheet?(period.timesheet)

    if period.save
      render json: { period: period.as_json(PERIOD_PUBLIC_FIELDS) }, status: :ok
    else
      render_bad_request(period.errors.full_messages.join(', '))
    end
  end

  # POST /timesheets/:timesheet_id/periods/delete
  # Deletes periods
  def delete
    periods_ids = params[:periods]

    return render_bad_request('No periods selected.') unless periods_ids&.any?
    return render_unauthorize if unauthorized_periods?(periods_ids) && !superadmin?

    Period.where(id: periods_ids).destroy_all
    render json: { message: 'ok' }, status: :ok
  end

  # GET /timesheets/:timesheet_id/periods/:id/credits
  # Returns the credits for a period
  def credits
    return render_unauthorized unless user_can_manage_timesheet?(@period.timesheet)

    users = load_users_with_roles(@period.timesheet)
    credits = build_credits(users, @period)

    render json: {
      period: @period.as_json(PERIOD_PUBLIC_FIELDS),
      credits: credits
    }, status: :ok
  end

  # POST /timesheets/:timesheet_id/periods/:id/credits
  # Sets the credits for a period
  def set_credits
    return render_unauthorized unless user_can_manage_timesheet?(@period.timesheet)
    return render_bad_request('No users or credits selected.') unless params[:credits]&.any?

    new_credits = build_new_credits(params[:credits], @period)
    @period.credits = new_credits.compact
    @period.save

    render json: @period.credits, status: :ok
  end

  # GET /timesheets/:timesheet_id/periods/:id/stats
  # Returns the stats for a period
  def stats
    return render_unauthorized unless user_can_manage_timesheet?(@period.timesheet)

    stats = @period.get_stats
    return render_stats_csv(stats) if params[:csv]

    render json: {
      period: @period,
      stats: stats
    }, status: :ok
  end

  # POST /timesheets/:timesheet_id/periods/:id/clone
  # Clones a period with its credits
  def clone
    return render_unauthorized unless user_can_manage_timesheet?(@period.timesheet)

    cloned_period = clone_period(@period)
    if cloned_period.save
      render json: { period: cloned_period.as_json(PERIOD_PUBLIC_FIELDS) }, status: :ok
    else
      render_bad_request(cloned_period.errors.full_messages.join(', '))
    end
  end

  private

  def set_period
    @period = Period.find(params[:id])
  end

  def period_params
    params.require(:period).permit(:id, :name, :timesheet_id, :from, :to)
  end

  def render_stats_csv(stats)
    columns = ['username', 'email', 'credits', 'total_hours', 'should_hours', 'balance', 'balance_percent']

    csv_string = CSV.generate do |csv|
      csv << columns
      stats.each do |record|
        line = columns.collect { |col| record[col].to_s.chomp }
        csv << line
      end
    end

    send_data(
      csv_string,
      type: 'application/octet-stream',
      filename: "#{@period.name.parameterize}-statistics-#{Time.now.to_formatted_s(:number)}.csv"
    )
  end

  def find_or_initialize_period
    if period_params[:id]
      Period.find(period_params[:id]).tap do |period|
        period.assign_attributes(period_params)
      end
    else
      Period.new(period_params)
    end
  end

  def unauthorized_periods?(periods_ids)
    Period.where(id: periods_ids).any? { |p| !p.timesheet.admin?(current_user) }
  end

  def load_users_with_roles(timesheet)
    timesheet.users.select('
      users.id,
      users.email,
      users.username,
      users.superadmin,
      ARRAY_AGG(users_timesheets.role) AS roles
    ').group(:id).order(:username)
  end

  def build_credits(users, period)
    users.map do |user|
      {
        user_id: user.id,
        username: user.username,
        admin: period.timesheet.admin?(user),
        email: user.email,
        roles: user.roles,
        credit_amount: Credit.where(user: user, period: period).first&.amount || 0.00
      }
    end
  end

  def build_new_credits(credits_params, period)
    new_credits_values = extract_new_credits_values(credits_params, period.timesheet.users.pluck(:id))

    existing_and_new_credits = period.credits.each_with_object([]) do |existing_credit, collection|
      if new_credits_values.key?(existing_credit.user_id)
        value = new_credits_values[existing_credit.user_id]
        next if existing_credit.amount.to_d == value.to_d

        existing_credit.amount = value
        new_credits_values.delete(existing_credit.user_id)
      end
      collection << existing_credit
    end

    new_credits_values.each do |user_id, value|
      existing_and_new_credits << Credit.new(
        user_id: user_id,
        period: period,
        amount: value.to_d
      )
    end

    existing_and_new_credits
  end

  def extract_new_credits_values(credits_params, timesheet_user_ids)
    credits_params.each_with_object({}) do |credit_data, new_credits_values|
      user_id = credit_data['user_id'].to_i
      credit_amount = credit_data['credit_amount'].to_d

      next if !credit_data['credit_amount'].present? || credit_amount == 0.0 || !timesheet_user_ids.include?(user_id)

      new_credits_values[user_id] = credit_amount
    end
  end

  def clone_period(original_period)
    original_period.dup.tap do |cloned_period|
      cloned_period.name = "#{original_period.name} clone"
      cloned_period.credits = original_period.credits.map(&:dup)
    end
  end
end
