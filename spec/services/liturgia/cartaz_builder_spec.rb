# frozen_string_literal: true

require "rails_helper"

RSpec.describe Liturgia::CartazBuilder do
  describe "LinhaEscala#ministros_celula" do
    it "agrupa ministros com separador |" do
      linha = described_class::LinhaEscala.new(
        horario: "07:00",
        presidente: "Pe. Marcos",
        ministros: %w[Clediana Alda]
      )
      expect(linha.ministros_celula).to eq("Clediana | Alda")
    end
  end
end
