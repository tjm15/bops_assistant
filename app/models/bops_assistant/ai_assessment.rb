module BopsAssistant
  class AiAssessment < ApplicationRecord
    self.table_name = "assistant_ai_assessments"
    belongs_to :planning_application, optional: true, class_name: "::PlanningApplication"
  end
end
