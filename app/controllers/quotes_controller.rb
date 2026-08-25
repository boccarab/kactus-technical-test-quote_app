class QuotesController < ApplicationController
  before_action :set_quote, only: %i[show edit update destroy publish archive]
  before_action :ensure_published_quote, only: :show
  before_action :ensure_draft_quote, only: :destroy

  def index
    @quotes = Quote.where(status: %i[draft published]).order(updated_at: :desc)
  end

  def show
  end

  def new
    @quote = Quote.new
  end

  def edit
  end

  def create
    @quote = Quote.new(quote_params)

    if @quote.save
      redirect_to @quote, notice: "Quote was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @quote.update(quote_params)
      redirect_to @quote, notice: "Quote was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quote.destroy!

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Quote was successfully destroyed."
        render turbo_stream: [
          turbo_stream.remove(@quote),
          turbo_stream.update("toaster", partial: "shared/toaster")
        ]
      end
      format.html { redirect_to quotes_path, notice: "Quote was successfully destroyed.", status: :see_other }
    end
  end

  def publish
    update_status(:published, "Quote was successfully published.")
  end

  def archive
    update_status(:archived, "Quote was successfully archived.")
  end

  private

  def set_quote
    @quote = Quote.find(params[:id])
  end

  def quote_params
    params.expect(quote: %i[name identifier])
  end

  def ensure_draft_quote
    return if @quote.status_draft?

    render plain: "Only draft quotes can be deleted.", status: :unprocessable_entity
  end

  def ensure_published_quote
    head :not_found unless @quote.status_published?
  end

  def update_status(status, notice)
    if @quote.update(status: status)
      redirect_to @quote, notice: notice
    else
      redirect_to @quote, alert: @quote.errors.full_messages.to_sentence
    end
  end
end
