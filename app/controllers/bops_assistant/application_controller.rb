module BopsAssistant
  class ApplicationController < ::ApplicationController
    before_action :ensure_enabled!

    private

    def ensure_enabled!
      head :forbidden unless ENV.fetch("ENABLE_BOPS_ASSISTANT", "false") == "true"
    end
  end
end
