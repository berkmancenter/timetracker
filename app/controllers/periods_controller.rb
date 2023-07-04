class PeriodsController < ApplicationController
  before_action :set_period, except: [:index, :upsert, :delete]
  before_action :is_admin

  layout 'admin'

  def index
    periods = Period.all

    render json: periods, status: :ok
  end

  def show
    render json: @period, status: :ok
  end

  def upsert
    if period_params[:id]
      period = Period.find(period_params['id'])
      period.assign_attributes(period_params)
    else
      period = Period.new(period_params)
    end

    if period.save
      render json: { entry: period }, status: :ok
    else
      render json: { message: period.errors.full_messages.join(', ') }, status: :bad_request
    end
  end

  def delete
    periods_ids = params[:periods]

    if periods_ids&.any?
      Period.where(id: periods_ids).destroy_all

      render json: { message: 'ok' }, status: :ok
    else
      render json: { message: 'No periods selected.' }, status: :bad_request
    end
  end

  def credits
    users = User.order(:username)
    credits = users.map do |user|
      {
        user_id: user.id,
        username: user.username,
        superadmin: user.superadmin,
        email: user.email,
        credit_amount: Credit.where(user: user, period: @period)&.first&.amount || 0.00
      }
    end

    render json: {
      period: @period,
      credits: credits
    }, status: :ok
  end

  def set_credits
    unless params[:credits].any?
      render json: { message: 'No users or credits selected.' }, status: :bad_request
      return
    end

    new_credits_values = {}

    params[:credits].each do |credit_data|
      next if !credit_data['credit_amount'].present? || credit_data['credit_amount'].to_d == 0.0.to_d

      new_credits_values[credit_data['user_id'].to_i] = credit_data['credit_amount']
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
    stats = @period.get_stats

    render json: {
      period: @period,
      stats: stats
    }, status: :ok
  end

  private

  def set_period
    @period = Period.find(params[:id])
  end

  def period_params
    params.require(:period).permit(:id, :name, :from, :to)
  end
end
