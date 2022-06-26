module ApplicationHelper
  def format_flash_message(message)
    matched_string = message.to_s.match(/\["(.*)"\]/)
    matched_string ? matched_string[1] : message
  end
end
