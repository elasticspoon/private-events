module ActionView
  module Helpers
    module CaptureHelper
      def set_content_for(name, content = nil, &block)
        @view_flow.content.delete name
        content_for(name, content, &block)
      end
    end
  end
end
