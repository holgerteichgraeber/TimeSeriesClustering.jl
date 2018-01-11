qstat -u hteich | grep hteich | awk -F'.' '{print $1}' | xargs qdel
