module Translator
  module TranslationsHelper

    def group_links
      output = content_tag(:li, link_to_unless_current("Application", translations_group_path("application"), :class => 'button'))
      output += content_tag(:li, link_to_unless_current("Framework", translations_group_path("framework"), :class => 'button'))
      output += content_tag(:li, link_to_unless_current("Deleted", translations_group_path("deleted"), :class => 'button'))
      output.html_safe
    end
  end
end
