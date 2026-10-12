# frozen_string_literal: true

module Liturgia
  # Busca a liturgia do dia na fonte principal (Canção Nova), confere com uma segunda
  # fonte e grava como RASCUNHO. Nada chega ao ministro sem validação do administrador.
  class SincronizarService
    # Parte do texto da fonte menor que precisa existir na maior (as fontes diferem em
    # cabeçalhos e respostas litúrgicas, mas o corpo da leitura deve coincidir).
    LIMITE_SEMELHANCA = 0.97

    Resposta = Struct.new(:liturgia_dia, :status, :mensagem, keyword_init: true) do
      def ok?
        status.in?(%i[criada atualizada ignorada])
      end
    end

    def self.call(data, forcar: false)
      new(data, forcar: forcar).call
    end

    def initialize(data, forcar: false)
      @data = data.to_date
      @forcar = forcar
    end

    def call
      registro = LiturgiaDia.find_or_initialize_by(data: @data)
      if registro.persisted? && registro.validada? && !@forcar
        return Resposta.new(liturgia_dia: registro, status: :ignorada, mensagem: "Já validada; não sobrescrita.")
      end

      principal = CancaoNovaClient.buscar(@data)
      conferencia = buscar_conferencia

      novo = registro.new_record?
      registro.assign_attributes(
        titulo: principal.titulo,
        cor: normalizar_cor(principal.cor),
        leituras: principal.leituras,
        fonte: CancaoNovaClient::NOME,
        fonte_url: principal.url,
        leituras_conferencia: conferencia&.leituras || [],
        fonte_conferencia: conferencia ? UpApiClient::NOME : nil,
        divergencias: comparar(principal, conferencia),
        buscado_em: Time.current,
        status: "rascunho",
        validado_por: nil,
        validado_em: nil
      )
      registro.save!
      Resposta.new(liturgia_dia: registro, status: novo ? :criada : :atualizada)
    rescue Erro, ActiveRecord::RecordInvalid => e
      Resposta.new(liturgia_dia: registro, status: :erro, mensagem: e.message)
    end

    private

    def buscar_conferencia
      UpApiClient.buscar(@data)
    rescue Erro
      nil
    end

    def normalizar_cor(cor)
      return cor if cor.blank?

      LiturgiaDia::CORES.find { |c| sem_acento(c).first(4) == sem_acento(cor).first(4) } || cor
    end

    def comparar(principal, conferencia)
      return ["Segunda fonte indisponível: leituras sem conferência automática."] if conferencia.nil?

      avisos = []
      if principal.cor.present? && conferencia.cor.present? &&
         sem_acento(principal.cor).first(4) != sem_acento(conferencia.cor).first(4)
        avisos << "Cor litúrgica difere: #{principal.cor} × #{conferencia.cor}."
      end

      a = agrupar(principal.leituras)
      b = agrupar(conferencia.leituras)
      (a.keys | b.keys).each do |chave|
        la = a[chave]
        lb = b[chave]
        rotulo = LiturgiaDia::TIPOS_LEITURA[chave.first] || chave.first.to_s.humanize
        if la.nil? || lb.nil?
          avisos << "#{rotulo}: presente apenas em #{la ? 'Canção Nova' : 'segunda fonte'}."
          next
        end
        if normalizar_ref(la["referencia"], chave.first) != normalizar_ref(lb["referencia"], chave.first)
          avisos << "#{rotulo}: referência difere (#{la['referencia']} × #{lb['referencia']})."
        end
        s = semelhanca(la["texto"], lb["texto"])
        avisos << "#{rotulo}: texto com #{(s * 100).round}% de coincidência entre as fontes." if s < LIMITE_SEMELHANCA
      end
      avisos
    end

    def agrupar(leituras)
      contagem = Hash.new(0)
      leituras.each_with_object({}) do |l, mapa|
        mapa[[l["tipo"], contagem[l["tipo"]] += 1]] = l
      end
    end

    # Remove espaços, títulos entre parênteses ("(Bodas de Caná)") e o refrão "(R. ...)".
    # Para salmos compara só o número do salmo (a 2ª fonte costuma omitir os versículos).
    def normalizar_ref(ref, tipo)
      r = sem_acento(ref.to_s).gsub(/\((?!\d)[^)]*\)/, "").gsub(/\s+/, "")
      r = r[/\A[a-z]*\d+/].to_s if tipo == "salmo"
      r
    end

    def semelhanca(x, y)
      pa = palavras(x)
      pb = palavras(y)
      return 0.0 if pa.empty? || pb.empty?

      (pa & pb).size.to_f / [pa.size, pb.size].min
    end

    def palavras(txt)
      sem_acento(txt.to_s).gsub(/[^a-z\s]/, " ").split.uniq
    end

    def sem_acento(txt)
      I18n.transliterate(txt.to_s).downcase
    end
  end
end
