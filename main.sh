# utility function
createNewSession() {
  local tmateCmdBase="$1"
  local namedSessionCmd="$2"
  local setDefaultCmd="$3"
  
  local newSessionCmd="${tmateCmdBase} ${namedSessionCmd} ${setDefaultCmd} new-session -d"
  local waitTmateReadyCmd="${tmateCmdBase} wait tmate-ready"
  
  echo "Creating new session"
  
  echo "${newSessionCmd}"
  bash -lc "${newSessionCmd}"

  echo "${waitTmateReadyCmd}"
  bash -lc "${waitTmateReadyCmd}"
  
  tmateSSH="$(bash -lc "${tmateCmdBase} display -p '#{tmate_ssh}'")"
  tmateWeb="$(bash -lc "${tmateCmdBase} display -p '#{tmate_web}'")"
  
  echo "Created new session successfully"
  
  bash -lc "${tmateCmdBase} ls"
}

# main script
run() {
  # preparing tmate command
  local sockPath="/tmp/tmate.sock"
  local tmateBashPath="/tmp/tmate.bashrc"

  echo 'set +e' >"$tmateBashPath"
  local setDefaultCmd="set-option -g default-command \"bash --rcfile $tmateBashPath\" \\;"
  
  local tmateCmdBase="tmate -S $sockPath"
  local namedSessionCmd="-k $TMAK"
  
  # start tmate
  tmateWeb=""
  tmateSSH=""
  createNewSession "$tmateCmdBase" "$namedSessionCmd" "$setDefaultCmd"
  
  # convert to seconds
  timeToAlive=$((TIME_TO_ALIVE*60))
  interval=300
  tickCounter=0
  
  echo "$timeToAlive"
  
  echo "Entering main loop"
  while [ $tickCounter -lt $timeToAlive ]; do
    echo "Fetching connection strings"
    
    echo "Web shell: ${tmateWeb}"
    echo "SSH: ${tmateSSH}"
    
    if [ "$tmateWeb" == "" -a "$tmateSSH" == "" ]; then
      # createNewSession "$tmateCmdBase" "$namedSessionCmd" "$setDefaultCmd"
      echo 
    fi
    
    sleep $interval
    
    echo "Timelapsed => $((tickCounter+=interval)) seconds"
  done
}

# execute
run
