CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Tests", "bin/rails test"
  step "Autoload", "bin/rails zeitwerk:check"
end
