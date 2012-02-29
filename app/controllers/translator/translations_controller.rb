module Translator
  class TranslationsController < ApplicationController
    before_filter :auth

    def locales
      @locales = Translator.locales
      render :layout => Translator.layout_name
    end

    def choose_locale
      if params[:locale].blank?
        flash[:error] = "You must specify a locale!"
        redirect_to :back && return
      end

      @locale = Translator.choose_locale(params[:locale])
      if @locale.present?
        flash[:notice] = "Set your locale to #{@locale}!"
        redirect_to translations_path
      else
        flash[:error] = "Sorry, #{params[:locale]} is not an available locale."
        redirect_to :back
      end
    end

    def index
#      section = params[:key].present? && params[:key] + '.'
#      params[:group] = "application" unless params["group"]
      @sections = Translator.sections
      @keys = Translator.cached_keys
        # TODO: implement search
        #        if params[:search]
        #          @keys = @keys.select {|k|
        #            Translator.locales.any? {|locale| I18n.translate("#{k}", :locale => locale).to_s.downcase.include?(params[:search].downcase)}
        #          }
        #        end
      @keys = paginate(@keys)
      render :layout => Translator.layout_name
    end

    def create
      Translator.current_store[params[:key]] = params[:value]
      redirect_to :back unless request.xhr?
    end

    def destroy
      key = params[:id].gsub('-','.')
      Translator.locales.each do |locale|
        Translator.current_store.destroy_entry(locale.to_s + '.' + key)
      end
      redirect_to :back unless request.xhr?
    end

    private

    def auth
      Translator.auth_handler.bind(self).call if Translator.auth_handler.is_a? Proc
    end

    def paginate(collection)
      @page = params[:page].to_i
      @page = 1 if @page == 0
      @total_pages = (collection.count / 50.0).ceil
      collection[(@page-1)*50..@page*50]
    end
  end
end

