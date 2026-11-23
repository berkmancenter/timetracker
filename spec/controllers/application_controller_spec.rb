require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def bad_request_action
      render_bad_request
    end

    def unauthorized_action
      render_unauthorized
    end
  end

  let(:user) { create(:user) }

  before do
    sign_in user

    @routes.draw do
      get '/bad_request_action', to: 'anonymous#bad_request_action'
      get '/unauthorized_action', to: 'anonymous#unauthorized_action'
    end
  end

  describe 'render_bad_request' do
    it 'returns a JSON response with status :bad_request' do
      get :bad_request_action
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ 'message' => 'Bad request' })
    end
  end

  describe 'render_unauthorized' do
    it 'returns a JSON response with status :unauthorized' do
      get :unauthorized_action
      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq({ 'message' => 'Unauthorized' })
    end
  end

  describe 'CSV formula neutralization' do
    it 'neutralizes formula-like strings' do
      expect(controller.send(:csv_safe_cell, '=1+1')).to eq("'=1+1")
      expect(controller.send(:csv_safe_cell, ' -cmd')).to eq("' -cmd")
    end

    it 'keeps strict negative numeric values as numbers' do
      expect(controller.send(:csv_safe_cell, '-12.50')).to eq('-12.50')
    end

    it 'neutralizes every formula start' do
      ['=SUM(A1)', '+1+1', '-1+1', '@SUM(A1)', "\tcmd", "\rcmd", "  =1"].each do |value|
        expect(controller.send(:csv_safe_cell, value)).to eq("'#{value}")
      end
    end

    it 'keeps numbers and plain text' do
      ['12', '+4', '-3.5', '.5', '1e5', '-2E-3', 'Plain text', 'a=b', 'user@example.com'].each do |value|
        expect(controller.send(:csv_safe_cell, value)).to eq(value)
      end
    end

    it 'turns other values into text without a trailing new line' do
      expect(controller.send(:csv_safe_cell, nil)).to eq('')
      expect(controller.send(:csv_safe_cell, 12.5)).to eq('12.5')
      expect(controller.send(:csv_safe_cell, Date.new(2026, 11, 20))).to eq('2026-11-20')
      expect(controller.send(:csv_safe_cell, "text\n")).to eq('text')
    end
  end
end
