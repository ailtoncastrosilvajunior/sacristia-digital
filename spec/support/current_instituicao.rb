# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    Current.instituicao = Instituicao.find_by!(slug: "facedecristo")
  end

  config.after do
    Current.reset
  end
end
