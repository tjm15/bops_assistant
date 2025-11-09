class CreateAssistantTables < ActiveRecord::Migration[7.0]
  def change
    create_table :assistant_ai_assessments do |t|
      t.integer :planning_application_id, index: true
      t.string  :stage
      t.string  :status
      t.jsonb   :outputs_json, default: {}
      t.string  :model_ref
      t.integer :latency_ms
      t.timestamps
    end

    create_table :assistant_ai_evidences do |t|
      t.references :ai_assessment, null: false, index: true
      t.string  :kind
      t.string  :label
      t.string  :source_uri
      t.string  :source_pointer
      t.text    :snippet
      t.float   :score
      t.text    :rationale
      t.timestamps
    end
  end
end
