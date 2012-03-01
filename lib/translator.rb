require 'translator/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3

module Translator
  class << self
    attr_accessor :auth_handler, :cache_path, :current_store, :framework_keys, :current_locale, :stored_keys
    attr_reader :simple_backend
    attr_writer :layout_name
  end

  @framework_keys = ["date.formats.default", "date.formats.short", "date.formats.long", 
                     "time.formats.default", "time.formats.short", "time.formats.long", "time.am", "time.pm", 
                     "support.array.words_connector", "support.array.two_words_connector", "support.array.last_word_connector", 
                     "errors.format", "errors.messages.inclusion", "errors.messages.exclusion", "errors.messages.invalid", 
                     "errors.messages.confirmation", "errors.messages.accepted", "errors.messages.empty", 
                     "errors.messages.blank", "errors.messages.too_long", "errors.messages.too_short", "errors.messages.wrong_length", 
                     "errors.messages.not_a_number", "errors.messages.not_an_integer", "errors.messages.greater_than", 
                     "errors.messages.greater_than_or_equal_to", "errors.messages.equal_to", "errors.messages.less_than", 
                     "errors.messages.less_than_or_equal_to", "errors.messages.odd", "errors.messages.even", "errors.required", "errors.blank", 
                     "number.format.separator", "number.format.delimiter", "number.currency.format.format", "number.currency.format.unit", 
                     "number.currency.format.separator", "number.currency.format.delimiter", "number.percentage.format.delimiter", 
                     "number.precision.format.delimiter", "number.human.format.delimiter", "number.human.storage_units.format", 
                     "number.human.storage_units.units.byte.one", "number.human.storage_units.units.byte.other", 
                     "number.human.storage_units.units.kb", "number.human.storage_units.units.mb", "number.human.storage_units.units.gb", 
                     "number.human.storage_units.units.tb", "number.human.decimal_units.format", "number.human.decimal_units.units.unit", 
                     "number.human.decimal_units.units.thousand", "number.human.decimal_units.units.million", 
                     "number.human.decimal_units.units.billion", "number.human.decimal_units.units.trillion", 
                     "number.human.decimal_units.units.quadrillion", "datetime.distance_in_words.half_a_minute", 
                     "datetime.distance_in_words.less_than_x_seconds.one", "datetime.distance_in_words.less_than_x_seconds.other", 
                     "datetime.distance_in_words.x_seconds.one", "datetime.distance_in_words.x_seconds.other", 
                     "datetime.distance_in_words.less_than_x_minutes.one", "datetime.distance_in_words.less_than_x_minutes.other", 
                     "datetime.distance_in_words.x_minutes.one", "datetime.distance_in_words.x_minutes.other", 
                     "datetime.distance_in_words.about_x_hours.one", "datetime.distance_in_words.about_x_hours.other", 
                     "datetime.distance_in_words.x_days.one", "datetime.distance_in_words.x_days.other", 
                     "datetime.distance_in_words.about_x_months.one", "datetime.distance_in_words.about_x_months.other", 
                     "datetime.distance_in_words.x_months.one", "datetime.distance_in_words.x_months.other", 
                     "datetime.distance_in_words.about_x_years.one", "datetime.distance_in_words.about_x_years.other", 
                     "datetime.distance_in_words.over_x_years.one", "datetime.distance_in_words.over_x_years.other", 
                     "datetime.distance_in_words.almost_x_years.one", "datetime.distance_in_words.almost_x_years.other", 
                     "datetime.prompts.year", "datetime.prompts.month", "datetime.prompts.day", "datetime.prompts.hour", 
                     "datetime.prompts.minute", "datetime.prompts.second", "helpers.select.prompt", "helpers.submit.create", 
                     "helpers.submit.update", "helpers.submit.submit"]

  def self.setup_backend
    I18n.backend = @simple_backend = I18n::Backend::KeyValue.new(@current_store)
  end

  def self.locales
    @simple_backend.available_locales
  end

  def self.current_locale
    @current_locale || I18n.default_locale || :en
  end

  def self.choose_locale(locale_choice)
    @current_locale = locales.detect{|l| l == locale_choice.to_sym }
  end

  def self.cached_keys_filepath
    FileUtils.mkdir_p File.join(@cache_path, current_locale.to_s)
    @cached_keys_filepath = File.join(@cache_path, current_locale.to_s, 'cached_keys.json')
  end

  def self.locale_keys
    Translator.current_store.keys("#{Translator.current_locale.to_s}.*").uniq
  end

  def self.locale_cache_key
    "i18n.cache.#{Translator.current_locale}.keys"
  end

  def self.cached_keys
    Translator.current_store.smembers(Translator.locale_cache_key)
  end

  def self.cache_keys!
    Translator.current_store.del(Translator.locale_cache_key)
    Translator.current_store.sadd(Translator.locale_cache_key, Translator.locale_keys)
  end

  def self.store_keys_to_file!
    # Load all the keys for the current locale, stripping off the locale part
    Translator.locale_keys.map do |k|
      k.sub(/^#{Translator.current_locale.to_s}\./, '')
    end.uniq
    File.open(Translator.cached_keys_filepath, 'w') do |f|
      f.puts ActiveSupport::JSON.encode(locale_keys)
    end
  end

  def self.load_cached_keys_from_file(force = false)
    # Check if the cache file exists...
    if File.exists?(Translator.cached_keys_filepath)
      # decode the cached json
      @cached_keys = ActiveSupport::JSON.decode(File.read(Translator.cached_keys_filepath))
    end
    @cached_keys || []
  end

  def self.keys_for_strings(options = {})
    @simple_backend.available_locales

    keys = Translator.cached_keys

    if options[:filter]
      keys = keys.select {|k| k[0, options[:filter].size] == options[:filter]}
    end

    case options[:group].to_s
    when "framework"
      keys = keys.select {|k| @framework_keys.include?(k) }
    when "application"
      keys -= @framework_keys
    end

    keys || []
  end

  def self.sections
    ["countries", "disciplines", "events", "irms", "literals", "medals", "month_names", "organizations", "phases", "qualification_codes", "qualification_notes", "stages", "time_formats", "units"]
    # TODO: port this code
    # Translator.cached_keys(:group => params[:group]).map {|k| k = k.scan(/^[a-z0-9\-_]*\./)[0]; k ? k.gsub('.', '') : false}.select{|k| k}.uniq.sort
  end
  def self.layout_name
    @layout_name || "translator"
  end

  private

  def self.flatten_keys(current_key, hash, dest_hash)
    hash.each do |key, value|
      full_key = [current_key, key].compact.join('.')
      if value.kind_of?(Hash)
        flatten_keys full_key, value, dest_hash
      else
        dest_hash[full_key] = value
      end
    end
    hash
  end
end

