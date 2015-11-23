require 'timeout'

rd, wr = IO.pipe
input = "/dev/null"
output = wr
cmd = ["git", "clone", "https://github.com/iplviv/gradle-sandbox", "gr2", "--recursive"]
options = { :unsetenv_others => true, :close_others => true, :in => input, :out => output }
begin
  pid = Process.spawn({}, *cmd, options)
  wr.close
  all = ''
  res = Timeout::timeout(0) {
    while line = rd.gets do
      all += "\t"+line
    end
  }
  wpid, status = Process.waitpid2(pid, 0)
  puts "rv=#{all}"
  puts "status=#{status}"
rescue Timeout::Error
  puts "GitHub permission denied"
  rd.close
end
