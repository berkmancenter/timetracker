require 'rails_helper'

RSpec.describe CustomField, type: :model do
  describe 'validations' do
    it { should validate_length_of(:access_key).is_at_most(1) }
  end
end