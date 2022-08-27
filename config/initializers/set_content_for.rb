module ActionView
  module Helpers
    module CaptureHelper
      def set_content_for(name, content = nil, &)
        @view_flow.content.delete name
        content_for(name, content, &)
      end
    end
  end
end
