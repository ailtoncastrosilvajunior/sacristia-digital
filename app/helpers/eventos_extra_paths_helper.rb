# frozen_string_literal: true

# Paths do CRUD de eventos extra conforme a área atual (admin ou escala_extra),
# para que as mesmas views sirvam aos dois perfis.
module EventosExtraPathsHelper
  def escala_extra_context?
    controller_path.start_with?("escala_extra")
  end

  # Eventos extra recebem ministros do plantão; escala manual só na competência ordinária.
  def mostrar_escalar_ministros?(evento)
    !escala_extra_context? && !evento.extra?
  end

  def eventos_extra_index_path(*args)
    escala_extra_context? ? escala_extra_eventos_extra_index_path(*args) : admin_eventos_extra_index_path(*args)
  end

  def evento_extra_path(evento, *args)
    escala_extra_context? ? escala_extra_eventos_extra_path(evento, *args) : admin_eventos_extra_path(evento, *args)
  end

  def new_evento_extra_path(*args)
    escala_extra_context? ? new_escala_extra_eventos_extra_path(*args) : new_admin_eventos_extra_path(*args)
  end

  def edit_evento_extra_path(evento, *args)
    escala_extra_context? ? edit_escala_extra_eventos_extra_path(evento, *args) : edit_admin_eventos_extra_path(evento, *args)
  end

  # Link do drawer de detalhes: no admin usa a tela de evento_escala; na escala extra, a action drawer.
  def evento_drawer_path(evento, *args)
    escala_extra_context? ? drawer_escala_extra_eventos_extra_path(evento, *args) : admin_evento_escala_path(evento, *args)
  end

  # Espórtula é visível apenas fora da área do agendador.
  def mostrar_esportula?
    !escala_extra_context?
  end
end
