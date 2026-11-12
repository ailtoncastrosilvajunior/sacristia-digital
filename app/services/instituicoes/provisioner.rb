# frozen_string_literal: true

module Instituicoes
  # Cria instituição + vínculo de plano (console/rake). Não substitui super-admin web (Fase D).
  class Provisioner
    Result = Struct.new(:instituicao, :plano, :created, keyword_init: true)

    def self.call(slug:, nome:, plano_codigo:, **attrs)
      new(slug: slug, nome: nome, plano_codigo: plano_codigo, **attrs).call
    end

    def initialize(slug:, nome:, plano_codigo:, tipo: "comunidade", nome_curto: nil, slogan_rodape: nil,
                   nome_recibos: nil, admin_email: nil, admin_password: nil, admin_nome: "Administrador")
      @slug = slug.to_s.downcase.strip
      @nome = nome.to_s.strip
      @plano_codigo = plano_codigo.to_s.strip
      @tipo = tipo
      @nome_curto = nome_curto
      @slogan_rodape = slogan_rodape
      @nome_recibos = nome_recibos
      @admin_email = admin_email
      @admin_password = admin_password
      @admin_nome = admin_nome
    end

    def call
      raise ArgumentError, "slug inválido" unless @slug.match?(/\A[a-z0-9-]+\z/)
      raise ArgumentError, "nome obrigatório" if @nome.blank?

      plano = Plano.find_by!(codigo: @plano_codigo)
      created = false

      inst = Instituicao.find_or_initialize_by(slug: @slug)
      if inst.new_record?
        created = true
        inst.assign_attributes(
          nome: @nome,
          tipo: @tipo,
          nome_curto: @nome_curto.presence || @nome,
          slogan_rodape: @slogan_rodape,
          nome_recibos: @nome_recibos.presence || @nome,
          ativa: true,
          assinatura_status: "ativa"
        )
        inst.save!
      end

      unless inst.instituicao_plano_vigente
        now = Time.current
        InstituicaoPlano.create!(
          instituicao: inst,
          plano: plano,
          vigencia_inicio: now,
          modulos_vigencia_inicio: now,
          preco_mensal_centavos: plano.preco_mensal_centavos,
          recursos_snapshot: plano.recursos,
          status: "vigente"
        )
      end

      criar_admin!(inst) if @admin_email.present?

      Result.new(instituicao: inst, plano: plano, created: created)
    end

    private

    def criar_admin!(inst)
      senha = @admin_password.presence || SecureRandom.hex(8)
      user = User.find_or_initialize_by(instituicao_id: inst.id, email: @admin_email.downcase.strip)
      user.assign_attributes(
        nome: @admin_nome,
        perfis: %w[admin],
        password: senha,
        password_confirmation: senha
      )
      user.save!
      $stdout.puts "[instituicoes:provision] Admin: #{user.email} (senha #{@admin_password.present? ? 'informada' : senha})"
    end
  end
end
