class PeriodsController < ApplicationController
  before_action :set_period, except: %i[index upsert delete]
  before_action :authenticate_user_json!

  PERIOD_PUBLIC_FIELDS = {
    only: %i[id timesheet_id name from to],
    include: {
      timesheet: { only: %i[id name] }
    }
  }.freeze

  def index
    periods = Period.user_periods(current_user)

    render json: periods.as_json(PERIOD_PUBLIC_FIELDS), status: :ok
  end

  def show
    generic_unauthorized_response and return unless @period.timesheet.admin?(current_user)

    render json: @period.as_json(PERIOD_PUBLIC_FIELDS), status: :ok
  end

  def upsert
    if period_params[:id]
      period = Period.find(period_params['id'])

      generic_unauthorized_response and return unless period.timesheet.admin?(current_user)

      period.assign_attributes(period_params)
    else
      period = Period.new(period_params)
    end

    if period.save
      render json: { period: period.as_json(PERIOD_PUBLIC_FIELDS) }, status: :ok
    else
      render json: { message: period.errors.full_messages.join(', ') }, status: :bad_request
    end
  end

  def delete
    periods_ids = params[:periods]

    unauth = false
    Period.where(id: periods_ids).each do |p|
      unauth = true unless p.timesheet.admin?(current_user)
    end
    generic_unauthorized_response and return if unauth

    if periods_ids&.any?
      Period.where(id: periods_ids).destroy_all

      render json: { message: 'ok' }, status: :ok
    else
      render json: { message: 'No periods selected.' }, status: :bad_request
    end
  end

  def credits
    generic_unauthorized_response and return unless @period.timesheet.admin?(current_user)

    users = @period.timesheet.users.select('
      users.id,
      users.email,
      users.username,
      users.superadmin,
      ARRAY_AGG(users_timesheets.role) AS roles
    ').group(:id).order(:username)

    credits = users.map do |user|
      {
        user_id: user.id,
        username: user.username,
        admin: @period.timesheet.admin?(user),
        email: user.email,
        roles: user.roles,
        credit_amount: Credit.where(user: user, period: @period)&.first&.amount || 0.00
      }
    end

    render json: {
      period: @period.as_json(PERIOD_PUBLIC_FIELDS),
      credits: credits
    }, status: :ok
  end

  def set_credits
    generic_unauthorized_response and return unless @period.timesheet.admin?(current_user)

    unless params[:credits]&.any?
      render json: { message: 'No users or credits selected.' }, status: :bad_request
      return
    end

    new_credits_values = {}

    timesheet_user_ids = @period.timesheet.users.pluck(:id)

    params[:credits].each do |credit_data|
      user_id = credit_data['user_id'].to_i

      next if !credit_data['credit_amount'].present? || credit_data['credit_amount'].to_d == 0.0.to_d || !timesheet_user_ids.include?(user_id)

      new_credits_values[user_id] = credit_data['credit_amount']
    end

    new_credits = []

    @period.credits.each do |existing_credit|
      user_id = existing_credit.user_id

      if new_credits_values.key?(user_id)
        value = new_credits_values[user_id]

        next if existing_credit.amount.to_d == value.to_d

        existing_credit.amount = value
        new_credit = existing_credit
        new_credits_values.delete(user_id)
      else
        new_credit = existing_credit
      end

      new_credits << new_credit
    end

    new_credits_values.each do |user_id, value|
      new_credit = Credit.new(
        user_id: user_id,
        period: @period,
        amount: value.to_d
      )

      new_credits << new_credit
    end

    @period.credits = new_credits
    @period.save

    render json: @period.credits, status: :ok
  end

  def stats
    generic_unauthorized_response and return unless @period.timesheet.admin?(current_user)

    stats = @period.get_stats

    render_stats_csv(stats) and return if params[:csv]

    render json: {
      period: @period,
      stats: stats
    }, status: :ok
  end

  def clone
    generic_unauthorized_response and return unless @period.timesheet.admin?(current_user)

    cloned_period = @period.dup
    cloned_period.name << ' clone'

    cloned_credits = @period.credits.map(&:dup)
    cloned_period.credits = cloned_credits

    if cloned_period.save
      render json: { period: @period.as_json(PERIOD_PUBLIC_FIELDS) }, status: :ok
    else
      render json: { message: @period.errors.full_messages.join(', ') }, status: :bad_request
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
end
