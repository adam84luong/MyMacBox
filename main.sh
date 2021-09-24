run() {
  # preparing tmate command
  local sockPath="/tmp/tmate.sock"
  
  local tmateCmdBase="tmate -S $sockPath"
  local namedSessionCmd="-k $TMAK"
  
  local echo 'set +e' >/tmp/tmate.bashrc
  local setDefaultCmd="set-option -g default-command \"bash --rcfile /tmp/tmate.bashrc\" \\;"
  
  # start tmate
  tmateWeb=""
  tmateSSH=""
  createNewSession "$tmateCmdBase" "$namedSessionCmd" "$setDefaultCmd"
  
  # convert to seconds
  timeToAlive=$((TIME_TO_ALIVE*60))
  interval=300
  tickCounter=0
  
  echo "Entering main loop"
  while [ $tickCounter -lt $timeToAlive ]; do
    echo "Fetching connection strings"
    
    tmateSSH="$(bash -lc "${tmateCmdBase} display -p '#{tmate_ssh}'")"
    tmateWeb="$(bash -lc "${tmateCmdBase} display -p '#{tmate_web}'")"
    
    if [ $tmateWeb == "" ] && [ $tmateSSH == "" ]; then
      createNewSession "$tmateCmdBase" "$namedSessionCmd" "$setDefaultCmd"
    fi
    
    echo "Web shell: ${tmateWeb}"
    echo "SSH: ${tmateSSH}"
    
    sleep $interval
    
    echo "Timelapsed => $((tickCounter+=interval)) seconds"
  done
}

createNewSession() {
  local tmateCmdBase=$1
  local namedSessionCmd=$2
  local setDefaultCmd=$3
  
  local newSessionCmd="${tmateCmdBase} ${namedSessionCmd} ${setDefaultCmd} new-session -d"
  local waitTmateReadyCmd="${tmateCmdBase} wait tmate-ready"
  
  echo "Creating new session"
  
  echo "${newSessionCmd}"
  bash -lc "${newSessionCmd}"

  echo "${waitTmateReadyCmd}"
  bash -lc "${waitTmateReadyCmd}"

  echo "Created new session successfully"
}
