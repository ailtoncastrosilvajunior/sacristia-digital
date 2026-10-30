# frozen_string_literal: true

namespace :esportulas do
  desc "Recalcula modo/destinatário de espórtula nos eventos (exceto manual e já pagos)"
  task backfill_destinatarios: :environment do
    scope = EventoEscala.nao_cancelados.where.not(sacerdote_id: nil)
    total = 0
    scope.find_each do |evento|
      next if evento.esportula_destinatario_manual?
      next if evento.esportula_paga?

      cb = EsportulaDestinatarioResolver.infer_calendario_para(evento)
      attrs = EsportulaDestinatarioResolver.new(evento, calendario_base: cb).compute_attributes
      cols = attrs.merge(updated_at: Time.current)
      cols[:calendario_base_id] = cb.id if cb && evento.calendario_base_id.blank?
      evento.update_columns(cols)
      total += 1
    end
    puts "Atualizados #{total} eventos."
  end
end
