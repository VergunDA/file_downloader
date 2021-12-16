# frozen_string_literal: true

module Messages

  private

  def invalid_url_message(url)
    "URL #{url} is invalid"
  end

  def out_of_space_message(url)
    "Unable to load File from #{url}. Low disk space"
  end

  def file_too_large_message(url)
    "Unable to load File from #{url}. File is too large"
  end

  def file_too_small_message(url)
    "Unable to load File from #{url}. File is too small"
  end

  def invalid_content_type_message(url)
    "Unable to load File from #{url}. Invalid content type"
  end

  def headers_invalid_message(url)
    "Unable to load File from #{url}. Headers are invalid"
  end

  def timeout_error_message(url)
    "Unable to load File from #{url}. Connection fails"
  end

  def file_is_unavailable_message(url)
    "Unable to load File from #{url}. File is unavailable"
  end

  def error_message(url, error)
    "Unable to load File from #{url}. #{error}"
  end
end
