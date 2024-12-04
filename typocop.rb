# script.rb

require 'base64'

encoded_typo_outputs = ENV['ENCODED_TYPO_OUTPUTS'] || ''

if encoded_typo_outputs.empty?
  puts 'No typo output.'
else
  typos = Base64.decode64(encoded_typo_outputs).split("\n")
  typos.each do |typo|
    puts "Typo: #{typo}"
  end
end
