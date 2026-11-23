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

    it 'compares the recipient email without case' do
      invitation = create(:invitation, email: 'recipient@example.com', used_by: nil)

      expect(invitation.redeemable_by?(build(:user, email: 'Recipient@Example.COM'))).to be(true)
    end

    it 'accepts an open multi invitation from anyone, also after it was used' do
      invitation = create(:invitation, itype: 'multi', email: nil, used: true)

      expect(invitation.redeemable_by?(recipient)).to be(true)
      expect(invitation.redeemable_by?(create(:user))).to be(true)
    end

    it 'keeps a multi invitation for one email only for this email' do
      invitation = create(:invitation, itype: 'multi', email: recipient.email)

      expect(invitation.redeemable_by?(recipient)).to be(true)
      expect(invitation.redeemable_by?(create(:user))).to be(false)
    end

    it 'rejects an invitation without expiration' do
      invitation = build(:invitation, email: recipient.email, expiration: nil)

      expect(invitation.redeemable_by?(recipient)).to be(false)
    end
  end

  describe 'role' do
    it { should validate_inclusion_of(:role).in_array(%w[admin user]) }

    it 'is user when not given' do
      expect(described_class.new.role).to eq('user')
    end
  end

  describe 'email' do
    it 'is required for a single invitation' do
      invitation = build(:invitation, itype: 'single', email: nil)

      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to include("can't be blank")
    end

    it 'is not required for a multi invitation' do
      expect(build(:invitation, itype: 'multi', email: nil)).to be_valid
    end

    it 'is saved without spaces and in lower case' do
      invitation = create(:invitation, email: "  Person@Example.COM \n")

      expect(invitation.reload.email).to eq('person@example.com')
    end

    it 'is saved as nil when blank' do
      invitation = create(:invitation, itype: 'multi', email: '   ')

      expect(invitation.reload.email).to be_nil
    end
  end

  describe 'code' do
    it 'is generated when not given' do
      invitation = create(:invitation, code: nil)

      expect(invitation.code).to match(/\A[A-Za-z0-9_-]{20,}\z/)
    end

    it 'is kept when given' do
      expect(create(:invitation, code: 'given-code').code).to eq('given-code')
    end

    it 'must be unique' do
      create(:invitation, code: 'same-code')
      duplicate = build(:invitation, code: 'same-code')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:code]).to include('has already been taken')
    end
  end
end
