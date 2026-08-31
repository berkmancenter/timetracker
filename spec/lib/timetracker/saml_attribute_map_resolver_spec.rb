require 'rails_helper'

RSpec.describe Timetracker::SamlAttributeMapResolver do
  describe '#attribute_map' do
    around do |example|
      original_email_attribute = ENV['DEVISE_SAML_EMAIL_ATTRIBUTE']
      original_member_of_attribute = ENV['DEVISE_SAML_MEMBER_OF_ATTRIBUTE']
      ENV['DEVISE_SAML_EMAIL_ATTRIBUTE'] = 'customEmail'
      ENV['DEVISE_SAML_MEMBER_OF_ATTRIBUTE'] = 'customMemberOf'

      example.run
    ensure
      ENV['DEVISE_SAML_EMAIL_ATTRIBUTE'] = original_email_attribute
      ENV['DEVISE_SAML_MEMBER_OF_ATTRIBUTE'] = original_member_of_attribute
    end

    it 'maps common and configured SAML attributes to user attributes' do
      attribute_map = described_class.new(nil).attribute_map

      expect(attribute_map['mail']).to eq('email')
      expect(attribute_map['customEmail']).to eq('email')
      expect(attribute_map['givenName']).to eq('first_name')
      expect(attribute_map['sn']).to eq('last_name')
      expect(attribute_map['displayName']).to eq('display_name')
      expect(attribute_map['memberOf']).to eq('member_of')
      expect(attribute_map['customMemberOf']).to eq('member_of')
    end
  end
end
