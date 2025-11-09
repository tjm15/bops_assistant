module BopsAssistant
  module AssistantHelper
    def assistant_markdown(md)
      return "" if md.blank?
      Kramdown::Document.new(md, input: 'GFM').to_html.html_safe
    end
  end
end
