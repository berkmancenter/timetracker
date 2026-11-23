require 'rails_helper'

RSpec.describe Timetracker::SamlMemberOfValidator do
  FakeSamlAttributes = Struct.new(:values) do
    def value_by_saml_attribute_key(key)
      values[key]
    end
  end

  FakeSamlResponse = Struct.new(:mapped_values, :attributes) do
    def attribute_value_by_resource_key(key)
      mapped_values[key.to_s] || mapped_values[key.to_sym]
    end
  end

  around do |example|
    original_required_member_of = ENV['DEVISE_SAML_REQUIRED_MEMBER_OF']
    original_member_of_attribute = ENV['DEVISE_SAML_MEMBER_OF_ATTRIBUTE']

    example.run
  ensure
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = original_required_member_of
    ENV['DEVISE_SAML_MEMBER_OF_ATTRIBUTE'] = original_member_of_attribute
  end

  it 'allows login when no memberOf requirement is configured' do
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = ''

    expect(described_class.new(saml_response).valid?).to eq(true)
  end

  it 'allows login when memberOf contains the required value' do
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = 'university:some:group'

    response = saml_response(member_of: ['university:some:group', 'university:other:group'])

    expect(described_class.new(response).valid?).to eq(true)
  end

  it 'rejects login when memberOf does not contain the required value' do
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = 'university:some:group'

    response = saml_response(member_of: ['university:other:group'])

    expect(described_class.new(response).valid?).to eq(false)
  end

  it 'checks configured memberOf attribute names' do
    ENV['DEVISE_SAML_MEMBER_OF_ATTRIBUTE'] = 'groups'
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = 'university:some:group'

    response = saml_response(raw_attributes: { 'groups' => ['university:some:group'] })

    expect(described_class.new(response).valid?).to eq(true)
  end

  it 'allows semicolon-separated required values' do
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = 'university:first:group;university:second:group'

    response = saml_response(member_of: ['university:second:group'])

    expect(described_class.new(response).valid?).to eq(true)
  end

  it 'allows required values separated by new lines, also written as \n' do
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = "university:first:group\\nuniversity:second:group\nuniversity:third:group"

    expect(described_class.new(saml_response(member_of: ['university:second:group'])).valid?).to eq(true)
    expect(described_class.new(saml_response(member_of: ['university:third:group'])).valid?).to eq(true)
  end

  it 'ignores spaces around the values' do
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = '  university:some:group ; '

    response = saml_response(member_of: [' university:some:group  '])

    expect(described_class.new(response).valid?).to eq(true)
  end

  it 'accepts a single memberOf value that is not a list' do
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = 'university:some:group'

    expect(described_class.new(saml_response(member_of: 'university:some:group')).valid?).to eq(true)
  end

  it 'checks the default memberOf attribute names when none are configured' do
    ENV['DEVISE_SAML_MEMBER_OF_ATTRIBUTE'] = nil
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = 'university:some:group'

    response = saml_response(raw_attributes: { 'urn:mace:dir:attribute-def:memberOf' => ['university:some:group'] })

    expect(described_class.new(response).valid?).to eq(true)
  end

  it 'rejects login when there are no memberOf values' do
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = 'university:some:group'

    expect(described_class.new(saml_response).valid?).to eq(false)
  end

  it 'works with a response that has no raw attributes' do
    ENV['DEVISE_SAML_REQUIRED_MEMBER_OF'] = 'university:some:group'
    response = double('SAML response')
    allow(response).to receive(:attribute_value_by_resource_key).with(:member_of).and_return(['university:some:group'])

    expect(described_class.new(response).valid?).to eq(true)
  end

  def saml_response(member_of: nil, raw_attributes: {})
    FakeSamlResponse.new(
      { member_of: member_of },
      FakeSamlAttributes.new(raw_attributes)
    )
  end
end
