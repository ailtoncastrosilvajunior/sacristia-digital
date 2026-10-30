# frozen_string_literal: true

class LotePagamentoEsportulaEvento < ApplicationRecord
  belongs_to :lote_pagamento_esportula
  belongs_to :evento_escala
end
