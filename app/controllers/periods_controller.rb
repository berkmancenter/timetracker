class PeriodsController < ApplicationController
  before_action :set_period, only: [:show, :edit, :update, :destroy, :credits, :set_credits, :stats]
  before_action :is_admin

  layout 'admin'

  def index
    @periods = Period.all
  end

  def new
    @period = Period.new
  end

  def create
    @period = Period.new(period_params)

    if @period.save
      redirect_to periods_url, notice: 'Period was successfully created.'
    else
      flash.now[:error] = @period.errors.full_messages.join(', ')
      render :new
    end
  end

  def update
    if @period.update(period_params)
      redirect_to periods_url, notice: 'Period was successfully updated.'
    else
      flash.now[:error] = @period.errors.full_messages.join(', ')
      render :edit
    end
  end

  def destroy
    @period.destroy
    redirect_to periods_url, notice: 'Period was successfully destroyed.'
  end

  def credits
    @users = User.order(:username)
    @credits = @users.map do |user|
      {
        user: user,
        amount: Credit.where(user: user, period: @period)&.first&.amount || 0.00
      }
    end
  end

  def set_credits
    new_credits_values = {}

    params[:period][:amount].each do |user_id, value|
      next if !value.present? || value.to_d == 0.0.to_d

      new_credits_values[user_id.to_i] = value
    end

    existing_credits = @period.credits.where(user: new_credits_values.keys)

    new_credits = []
    new_credits_values.each do |user_id, value|
      existing_credit = existing_credits.select { |credit| credit.user_id == user_id.to_i }.first
      unless existing_credit.nil?
        existing_credit.amount = value
        new_credit = existing_credit
      else
        new_credit = Credit.new(
          user_id: user_id,
          period: @period,
          amount: value.to_d
        )
      end

      new_credits << new_credit
    end

    @period.credits = new_credits
    @period.save

    redirect_to credits_period_url(@period), notice: 'Credits have been set.'
  end

  def stats
    @stats = @period.get_stats
  end

  private

  def set_period
    @period = Period.find(params[:id])
  end

  def period_params
    params.require(:period).permit(:name, :from, :to)
  end
end
