# This file will extract tables from the given directory.
class TableExtractor
  def extract_tables(pages_directory)
    tables = []

    Dir.glob("#{pages_directory}/*.json").each do |file|
      data = JSON.parse(File.read(file))

      pages = data.select { |block| block['BlockType'] == 'PAGE' }
      pages.each do |page|
        tables.concat(extract_tables_from_page(page, data))
      end
    end

    tables
  end

  def print_tables(tables, output_file_path)
    sorted_tables = tables.sort_by { |table| table[:page].to_i }
    output = ""

    sorted_tables.each do |table|
      output += "\n" * 3
      output += "#{table[:info]}\n"

      rows = table[:cells].map { |cell| cell[:location]["R"] }.uniq.sort
      columns = table[:cells].map { |cell| cell[:location]["C"] }.uniq.sort

      rows.each do |row|
        cells_in_row = table[:cells].select { |cell| cell[:location]["R"] == row }
        row_output = columns.map do |col|
          cell = cells_in_row.find { |c| c[:location]["C"] == col }
          text = cell ? cell[:text] : ""
          text = "\"#{text}\"" if text.empty?
          text
        end.join(",")
        output += "#{row_output}\n"
      end
    end

    if output_file_path
      File.open(output_file_path, 'w') { |file| file.write(output) }
    else
      puts output
    end
  end

  private

  def extract_tables_from_page(page, data)
    table_blocks = page['Children'].map { |id| find_block_by_id(id, data) }.select { |block| block['BlockType'] == 'TABLE' }
    table_blocks.map.with_index { |table, index| build_table(table, data, index, table_blocks.count) }
  end

  def build_table(table, data, index, tables_count)
    table_info = "Page: #{table['Page']} -- Table: #{index + 1} of #{tables_count}"

    cells = table['Children'].map { |id| find_block_by_id(id, data) }.select { |block| block['BlockType'] == 'CELL' }
    { id: table['Id'], info: table_info, cells: cells.map { |cell| build_cell(cell, data) }, page: table['Page'] }
  end

  def build_cell(cell, data)
    words = cell['Children'].map { |id| find_block_by_id(id, data) }.map { |word| word['Text'] }.join(' ')
    { location: cell['CellLocation'], text: words }
  end

  def find_block_by_id(id, data)
    block = data.find { |block| block['Id'] == id }
    unless block
      puts "Warning: Block with ID #{id} not found."
    end
    block
  end
end
