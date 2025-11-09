module BopsAssistant
  class CallbacksController < ApplicationController
    skip_before_action :verify_authenticity_token
    def create
      head :no_content
    end
  end
end
