ulimit -n
ulimit -Hn
cat /proc/self/limits | grep "open files"
