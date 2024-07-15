require 'json'

class App
  def initialize(pages_directory, options = {})
    @pages_directory = pages_directory
    @options = {
    }.merge!(options)
    @extractor = TableExtractor.new
  end

  def run_script
    tables = @extractor.extract_tables(@pages_directory)
    @extractor.print_tables(tables)
  end
end
