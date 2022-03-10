class Api::V1::ExampleController < ApplicationController
  respond_to :json

  def index
    render json: { message: 'Hello World' }
  end
end
