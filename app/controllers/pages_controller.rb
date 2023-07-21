# frozen_string_literal: true

class PagesController < ApplicationController
  def index
    @pages = Page.all
  end

  def show
    @page = Page.find(params[:id])
  end

  def new
    @page = Page.new
  end

  def edit
    @page = Page.find(params[:id])
  end

  def create
    @page = Page.new(page_params)

    if @page.save
      message = @page.user_message || 'Page was successfully created.'
      redirect_to page_path(@page), notice: message
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @page = Page.find(params[:id])

    if @page.update(page_params)
      message = @page.user_message || 'Page was successfully updated.'
      redirect_to page_path(@page), notice: message
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @page = Page.find(params[:id])

    if @page.destroy
      message = @page.user_message || 'Page was successfully destroyed.'
      redirect_to pages_root_path, notice: message
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def page_params
    params.require(:page).permit(:title, :content, :domain)
  end
end
