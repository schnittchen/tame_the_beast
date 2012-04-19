notification :growl

cli_options = `cat $HOME/.rspec .rspec 2>/dev/null`.gsub("\n", ' ')
guard 'rspec', :version => 2, :cli => cli_options do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end
