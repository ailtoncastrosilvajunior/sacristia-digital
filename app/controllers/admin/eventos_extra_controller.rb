# frozen_string_literal: true

module Admin
  class EventosExtraController < Admin::BaseController
    require_instituicao_modulo! :escala_extra
    include EventosExtraCrud
  end
end
