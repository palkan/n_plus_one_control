# frozen_string_literal: true

module NPlusOneControl # :nodoc:
  class Railtie < ::Rails::Railtie # :nodoc:
    initializer "n_plus_one_control.backtrace_cleaner" do
      ActiveSupport.on_load(:active_record) do
        NPlusOneControl.backtrace_cleaner = lambda do |locations|
          ::Rails.backtrace_cleaner.clean(locations)
        end
      end
    end
  end
end
