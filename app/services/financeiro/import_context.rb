# frozen_string_literal: true

module Financeiro
  module ImportContext
    module_function

    def active?
      Thread.current[:financeiro_importacao_ativa] == true
    end

    def run
      Thread.current[:financeiro_importacao_ativa] = true
      yield
    ensure
      Thread.current[:financeiro_importacao_ativa] = false
    end
  end
end
