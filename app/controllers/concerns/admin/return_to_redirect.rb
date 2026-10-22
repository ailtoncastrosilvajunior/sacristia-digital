# frozen_string_literal: true

module Admin
  module ReturnToRedirect
    extend ActiveSupport::Concern

    private

    def safe_return_to_path(raw = params[:return_to])
      path = raw.to_s.strip
      return nil if path.blank?
      return nil unless path.start_with?("/admin/")
      return nil if path.start_with?("//")

      path
    end

    def redirect_with_return_to(default:, notice: nil, alert: nil)
      dest = safe_return_to_path
      opts = {}
      opts[:notice] = notice if notice.present?
      opts[:alert] = alert if alert.present?
      redirect_to(dest.presence || default, **opts)
    end
  end
end
