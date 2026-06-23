require 'rails_helper'

RSpec.describe Timetracker::SamlAttributeMapResolver do
  describe '#attribute_map' do
    around do |example|
      original_email_attribute = ENV['DEVISE_SAML_EMAIL_ATTRIBUTE']
      ENV['DEVISE_SAML_EMAIL_ATTRIBUTE'] = 'customEmail'

      example.run
    ensure
      ENV['DEVISE_SAML_EMAIL_ATTRIBUTE'] = original_email_attribute
    end

    it 'maps common and configured SAML attributes to user attributes' do
      attribute_map = described_class.new(nil).attribute_map

      expect(attribute_map['mail']).to eq('email')
      expect(attribute_map['customEmail']).to eq('email')
      expect(attribute_map['givenName']).to eq('first_name')
      expect(attribute_map['sn']).to eq('last_name')
      expect(attribute_map['displayName']).to eq('display_name')
    end
  end
end
