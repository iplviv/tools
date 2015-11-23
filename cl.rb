rd, wr = IO.pipe

cmd = ["git", "clone", "https://github.com/iplviv/gradle-sandbox", "gr2"]
options = { :unsetenv_others => true, :close_others => true,
            :in => "/dev/null", :out => wr }
pid = Process.spawn({}, *cmd, options)
wr.close
while line = rd.gets do
  puts ">>> #{line}"
end
rd.close
wpid, status = Process.waitpid2(pid, 0)
puts "RESULT"
puts "#{wpid} | #{status}"
