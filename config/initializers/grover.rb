# frozen_string_literal: true

grover_launch_args = [
  "--no-sandbox",
  "--disable-setuid-sandbox",
  "--disable-dev-shm-usage"
]

chrome_path = ENV["PUPPETEER_EXECUTABLE_PATH"].presence ||
              ENV["GROVER_CHROME_PATH"].presence
%w[/usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome].each do |path|
  chrome_path ||= path if File.executable?(path)
end

Grover.configure do |config|
  config.options = {
    launch_args: grover_launch_args,
    wait_until: "load",
    timeout: 90_000,
    **(chrome_path ? { executable_path: chrome_path } : {})
  }
end
