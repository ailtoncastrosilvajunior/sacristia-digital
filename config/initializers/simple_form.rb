# frozen_string_literal: true

SimpleForm.setup do |config|
  config.wrappers :default, class: "form-group" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: "block text-sm font-medium text-stone-700 mb-1"
    b.use :input, class: "form-input"
    b.use :error, wrap_with: { tag: "p", class: "mt-1 text-sm text-red-600" }
    b.use :hint, wrap_with: { tag: "p", class: "mt-1 text-sm text-stone-500" }
  end

  config.default_wrapper = :default
  config.boolean_style = :nested
  config.button_class = "btn"
  config.error_notification_tag = :div
  config.error_notification_class = "error_notification"
  config.browser_validations = true
  config.boolean_label_class = "checkbox"
end
