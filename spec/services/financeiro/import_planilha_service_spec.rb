# frozen_string_literal: true

require "rails_helper"

RSpec.describe Financeiro::ImportPlanilhaService do
  it "bloqueia reimportação após migração concluída" do
    FinanceiroConfiguracao.marcar_migrado!
    path = Rails.root.join("tmp/test-import.xlsx")
    File.write(path, "dummy")

    expect do
      described_class.call(path.to_s)
    end.to raise_error(Financeiro::ImportPlanilhaService::ImportBlockedError)
  ensure
    File.delete(path) if File.exist?(path)
  end
end
