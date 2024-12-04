# script.rb

changed_file_list = ENV['CHANGED_FILE_LIST'] || ''

if changed_file_list.empty?
  puts 'No files changed.'
else
  files = changed_file_list.split
  files.each do |file|
    puts "Changed file: #{file}"
  end
end
