module BopsAssistant
  class AiEvidence < ApplicationRecord
    self.table_name = "assistant_ai_evidences"
    belongs_to :ai_assessment, class_name: "BopsAssistant::AiAssessment"
  end
end
