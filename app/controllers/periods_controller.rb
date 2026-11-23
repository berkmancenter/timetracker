class PeriodsController < ApplicationController
  before_action :authenticate_user_json!
  before_action :set_period, except: %i[index upsert delete]

  PERIOD_PUBLIC_FIELDS = {
    only: %i[id timesheet_id name from to],
    include: {
      timesheet: { only: %i[id name] },
      custom_fields: {
        only: %i[id machine_name title order input_type popular list access_key access_value]
      }
    }
  }.freeze

  # GET /timesheets/:timesheet_id/periods
  # Returns all periods for the current user
  def index
    timesheet = find_timesheet
    return render_bad_request if timesheet.nil?
    return render_unauthorized unless user_can_manage_timesheet?(timesheet)

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
    timesheet = find_timesheet
    return render_bad_request if timesheet.nil?
    return render_unauthorized unless user_can_manage_timesheet?(timesheet)

    period = find_or_initialize_period(timesheet)

    return render_bad_request if period.nil?

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
    return render_unauthorized if unauthorized_periods?(periods_ids) && !superadmin?

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

  # POST /timesheets/:timesheet_id/periods/:id/set_credits
  # Sets the credits for a period
  def set_credits
    return render_unauthorized unless user_can_manage_timesheet?(@period.timesheet)
    return render_bad_request('No users or credits selected.') unless params[:credits]&.any?

    ActiveRecord::Base.transaction do
      validate_credit_users!(params[:credits], @period)
      update_credits!(params[:credits], @period)
      save_custom_field_data(params[:credits], @period)
    end

    render json: @period.credits.reload, status: :ok
  rescue ActiveRecord::RecordInvalid => error
    render_bad_request(error.record.errors.full_messages.join(', ').presence || error.message)
  end

  # GET /timesheets/:timesheet_id/periods/:id/stats
  # Returns the stats for a period
  def stats
    return render_unauthorized unless user_can_manage_timesheet?(@period.timesheet)

    stats = @period.get_stats(params[:user_ids])
    return render_stats_csv(stats) if params[:csv]

    render json: {
      period: @period.as_json(PERIOD_PUBLIC_FIELDS),
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
    @period = find_timesheet&.periods&.includes(:custom_fields)&.find_by(id: params[:id])
    render_bad_request if @period.nil?
  end

  def find_timesheet
    identifier = params[:timesheet_id].to_s
    return Timesheet.find_by(id: identifier) if identifier.match?(/\A\d+\z/)

    Timesheet.find_by(uuid: identifier)
  end

  def period_params
    params.require(:period).permit(
      :id, :name, :from, :to,
      custom_fields_attributes: %i[id title access_key input_type popular list order _destroy]
    )
  end

  def find_or_initialize_period(timesheet)
    if period_params[:id]
      timesheet.periods.find_by(id: period_params[:id])&.tap do |period|
        period.assign_attributes(period_params.except(:id))
      end
    else
      timesheet.periods.new(period_params)
    end
  end

  def render_stats_csv(stats)
    # Start with standard columns
    columns = ['username', 'email', 'credits', 'total_hours', 'should_hours', 'balance', 'balance_percent']

    # Add custom field columns if they exist
    if @period.custom_fields.any?
      @period.custom_fields.each do |field|
        columns << "custom_field_#{field.id}"
      end
    end

    csv_string = CSV.generate do |csv|
      # Create a header row with appropriate titles for custom fields
      header_row = columns.map do |col|
        if col.start_with?('custom_field_')
          field_id = col.gsub('custom_field_', '').to_i
          @period.custom_fields.find { |f| f.id == field_id }&.title || col
        else
          col
        end
      end
      csv << header_row.map { |value| csv_safe_cell(value) }

      # Add data rows
      stats.each do |record|
        line = columns.map { |col| csv_safe_cell(record[col]) }
        csv << line
      end
    end

    send_data(
      csv_string,
      type: 'application/octet-stream',
      filename: "#{@period.name.parameterize}-statistics-#{Time.now.to_formatted_s(:number)}.csv"
    )
  end

  def unauthorized_periods?(periods_ids)
    timesheet_ids = Period.where(id: periods_ids).distinct.pluck(:timesheet_id)
    return false if timesheet_ids.empty?

    admin_timesheet_ids = UsersTimesheet.where(
      user: current_user,
      timesheet_id: timesheet_ids,
      role: 'admin'
    ).pluck(:timesheet_id)

    (timesheet_ids - admin_timesheet_ids).any?
  end

  def load_users_with_roles(timesheet)
    timesheet.users.select('
      users.id,
      users.email,
      users.first_name,
      users.last_name,
      users.username,
      users.superadmin,
      ARRAY_AGG(users_timesheets.role) AS roles
    ').group(:id).order(:username)
  end

  def save_custom_field_data(credits_params, period)
    fields = period.custom_fields.to_a
    return unless fields.any?

    custom_field_ids = fields.map(&:id)
    users_by_id = period.timesheet.users.where(id: credits_params.map { |data| data['user_id'].to_i }).index_by(&:id)

    credits_params.each do |credit_data|
      user_id = credit_data['user_id'].to_i
      user = users_by_id.fetch(user_id)

      # Extract custom field values
      custom_field_ids.each do |field_id|
        field_key = "custom_field_#{field_id}"
        next unless credit_data.key?(field_key)

        value = credit_data[field_key]

        # Find or initialize the custom field data item
        data_item = CustomFieldDataItem.find_or_initialize_by(
          custom_field_id: field_id,
          owner: user
        )

        # Update the value
        data_item.value = value
        data_item.save!
      end
    end
  end

  def build_credits(users, period)
    custom_field_data = {}
    fields = period.custom_fields.to_a
    user_list = users.to_a
    user_ids = user_list.map(&:id)
    credits_by_user_id = period.credits.where(user_id: user_ids).pluck(:user_id, :amount).to_h

    if fields.any?
      field_ids = fields.map(&:id)

      CustomFieldDataItem.where(custom_field_id: field_ids, owner_type: 'User', owner_id: user_ids)
        .each do |item|
          custom_field_data[item.owner_id] ||= {}
          custom_field_data[item.owner_id][item.custom_field_id] = item.value
        end
    end

    user_list.map do |user|
      user_custom_fields = {}

      if fields.any? && custom_field_data[user.id]
        fields.each do |field|
          user_custom_fields["custom_field_#{field.id}"] = custom_field_data[user.id][field.id] || ''
        end
      end

      {
        user_id: user.id,
        username: user.username,
        admin: user.superadmin? || Array(user.roles).include?('admin'),
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        roles: user.roles,
        credit_amount: credits_by_user_id[user.id] || 0.00
      }.merge(user_custom_fields)
    end
  end

  def update_credits!(credits_params, period)
    existing_by_user_id = period.credits.index_by(&:user_id)
    updates_by_user_id = {}

    credits_params.each do |credit_data|
      next unless credit_data.key?('credit_amount')

      user_id = credit_data['user_id'].to_i
      updates_by_user_id[user_id] = parse_credit_amount!(credit_data['credit_amount'], period)
    end

    updates_by_user_id.each do |user_id, amount|
      existing_credit = existing_by_user_id[user_id]

      if amount.zero?
        existing_credit&.destroy!
      elsif existing_credit
        existing_credit.update!(amount: amount) if existing_credit.amount.to_d != amount
      else
        period.credits.create!(user_id: user_id, amount: amount)
      end
    end
  end

  # Blank means no credit (0). Text like "abc" is rejected, String#to_d would
  # make it 0 and remove the credit without telling.
  def parse_credit_amount!(raw_amount, period)
    return 0.to_d if raw_amount.blank?

    amount = BigDecimal(raw_amount.to_s.strip)
    return amount if amount.finite?

    raise ArgumentError
  rescue ArgumentError, TypeError
    period.errors.add(:credits, 'must be numbers')
    raise ActiveRecord::RecordInvalid.new(period)
  end

  def validate_credit_users!(credits_params, period)
    requested_user_ids = credits_params.map { |credit_data| credit_data['user_id'].to_i }.uniq
    valid_user_ids = period.timesheet.users.where(id: requested_user_ids).pluck(:id)
    return if (requested_user_ids - valid_user_ids).empty?

    period.errors.add(:credits, 'contain users outside this timesheet')
    raise ActiveRecord::RecordInvalid.new(period)
  end

  def clone_period(original_period)
    original_period.dup.tap do |cloned_period|
      cloned_period.name = "#{original_period.name} clone"
      cloned_period.credits = original_period.credits.map(&:dup)

      if original_period.custom_fields.any?
        cloned_period.custom_fields = original_period.custom_fields.map(&:dup)
        cloned_period.custom_fields.each_with_index do |custom_field, index|
          custom_field.machine_name = "#{custom_field.machine_name}_clone_#{original_period.id}_#{index}"
        end
      end
    end
  end
end
