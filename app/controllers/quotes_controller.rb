class QuotesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_quote_not_found

  before_action :set_quote, only: %i[show edit update destroy publish archive]
  before_action :ensure_published_quote, only: :show
  before_action :ensure_draft_quote, only: %i[edit update destroy]

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
      redirect_to quotes_path, notice: "Le devis a été créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @quote.update(quote_params)
      redirect_to quotes_path, notice: "Le devis a été mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quote.destroy!

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Le devis a été supprimé."
        render turbo_stream: [
          turbo_stream.remove(@quote),
          turbo_stream.update("toaster", partial: "shared/toaster")
        ]
      end
      format.html { redirect_to quotes_path, notice: "Le devis a été supprimé.", status: :see_other }
    end
  end

  def publish
    update_status(:published, "Le devis a été publié.")
  end

  def archive
    update_status(:archived, "Le devis a été archivé.")
  end

  private

  def set_quote
    @quote = Quote.find(params[:id])
  end

  def quote_params
    params.require(:quote).permit(:name, :status, quote_items_attributes: %i[id name quantity unit_price vat _destroy])
  end

  def ensure_draft_quote
    return if @quote.status_draft?

    render plain: "Only draft quotes can be deleted.", status: :unprocessable_entity
  end

  def ensure_published_quote
    raise ActiveRecord::RecordNotFound unless @quote.status_published?
  end

  def render_quote_not_found
    render :not_found, status: :not_found
  end

  def update_status(status, notice)
    if @quote.update(status: status)
      redirect_to @quote, notice: notice
    else
      redirect_to @quote, alert: @quote.errors.full_messages.to_sentence
    end
  end
end
