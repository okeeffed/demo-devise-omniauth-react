require 'rails_helper'

RSpec.describe DocumentsController, type: :controller do
  describe 'GET #index' do
    let(:subject) { build(:document) }

    context 'successful responses' do
      login_admin

      it 'creates a post when user is authorized' do
        post :create, params: { body: subject.body }

        expect(response.status).to eq(201)
        expect(response.parsed_body['body']).to eq(subject.body)
      end
    end

    context 'unsuccessful responses' do
      login_user

      it 'returns unauthorized when user is unauthorized to create a document' do
        post :create, params: { body: subject.body }

        expect(response.status).to eq(401)
      end
    end
  end

  describe 'GET #show' do
    # ... TODO
  end

  describe 'POST #create' do
    # ... TODO
  end
end
