class Api::V1::DocumentsController < ApplicationController
  include Pundit

  def create
    @doc = Document.new(body: params[:body])
    authorize @doc, :create?
    @doc.save!

    render json: @doc, status: :created
  rescue Pundit::NotAuthorizedError
    render json: { error: 'You are not authorized to create a document' }, status: :unauthorized
  end

  def index
    @docs = Document.all
    render json: @docs
  end

  def update
    @doc = Document.find(params[:id])
    authorize @doc, :update?
    @doc.update!(document_params)
    render json: @doc
  rescue Pundit::NotAuthorizedError
    render json: { error: 'You are not authorized to create a document' }, status: :unauthorized
  end

  def destroy
    @doc = Document.find(params[:id])
    authorize @doc, :destroy?
    @doc.destroy
    render status: :no_content
  rescue Pundit::NotAuthorizedError
    render json: { error: 'You are not authorized to create a document' }, status: :unauthorized
  end

  private

  # Using a private method to encapsulate the permissible parameters
  # is just a good pattern since you'll be able to reuse the same
  # permit list between create and update. Also, you can specialize
  # this method with per-user checking of permissible attributes.
  def document_params
    params.require(:document).permit(:body)
  end
end
