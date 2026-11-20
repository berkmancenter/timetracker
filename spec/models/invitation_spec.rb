require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe 'associations' do
    it { should belong_to(:timesheet) }
    it { should belong_to(:sender).class_name('User') }
    it { should belong_to(:used_by).class_name('User').optional }
  end

  describe 'validations' do
    it { should validate_presence_of(:sender) }
    it { should validate_inclusion_of(:itype).in_array(%w[single multi]) }
  end

  describe 'attributes' do
    it { should have_db_column(:used).of_type(:boolean).with_options(default: false) }
    it { should have_db_column(:itype).of_type(:string).with_options(default: 'single') }

    it 'sets a default expiration when one is not supplied' do
      invitation = build(:invitation, expiration: nil)

      invitation.validate

      expect(invitation.expiration).to be_within(1.second).of(Time.current + Invitation::DEFAULT_EXPIRATION)
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      context 'on create' do
        it 'generates a unique code' do
          invitation = build(:invitation)
          invitation.save
          expect(invitation.code).not_to be_blank
          expect(Invitation.where(code: invitation.code).count).to eq(1)
        end
      end

      context 'on update' do
        it 'does not regenerate the code' do
          invitation = create(:invitation)
          original_code = invitation.code
          invitation.update(itype: 'multi')
          expect(invitation.code).to eq(original_code)
        end
      end
    end
  end

  describe '#redeemable_by?' do
    let(:recipient) { create(:user, email: 'recipient@example.com') }

    it 'accepts an unexpired invitation for its recipient' do
      invitation = create(:invitation, email: recipient.email, used_by: nil)

      expect(invitation.redeemable_by?(recipient)).to be(true)
    end

    it 'rejects used, expired, and wrong-recipient invitations' do
      used = create(:invitation, email: recipient.email, used: true)
      expired = create(:invitation, email: recipient.email, expiration: 1.minute.ago)
      wrong_recipient = create(:invitation, email: 'other@example.com')

      expect(used.redeemable_by?(recipient)).to be(false)
      expect(expired.redeemable_by?(recipient)).to be(false)
      expect(wrong_recipient.redeemable_by?(recipient)).to be(false)
    end
  end
end
