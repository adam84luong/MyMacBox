# main script
startMyBox() {
  # preparing tmate command
  local sockPath="/tmp/tmate.sock"
  local tmateBashPath="/tmp/tmate.bashrc"

  echo 'set +e' >"$tmateBashPath"
  local setDefaultCmd="set-option -g default-command \"bash --rcfile $tmateBashPath\" \\;"
  
  local tmateCmdBase="tmate -S $sockPath"
  local namedSessionCmd="-k $TMAK -n mytmate"
  
  # start tmate
  tmateWeb=""
  tmateSSH=""
  sessionName=""
  createNewSession "$tmateCmdBase" "$namedSessionCmd" "$setDefaultCmd"
  
  # convert to seconds
  timeToAlive=$((TIME_TO_ALIVE*60))
  # seconds
  interval=60
  tickCounter=0
  
  echo "timeToAlive in seconds => $timeToAlive"

  local tmateLsResult=""
  
  echo "Entering main loop"
  while [ $tickCounter -lt $timeToAlive ]; do
    # Check if the session exists, discarding output
    # We can check $? for the exit status (zero for success, non-zero for failure)
    # bash -lc "$tmateCmdBase has-session -t $sessionName 2>/dev/null"
    tmateLsResult="$(bash -lc "$tmateCmdBase ls 2>/dev/null || :")"
    tmateLsResult="$(echo $tmateLsResult | head -n1 | cut -d ' ' -f 1,2,3)"
    # echo "tmateLsResult => $tmateLsResult"
    # if 'tmate ls' not return like '...: 1 windows', then need to revew tmate session
    if [ -z "$(grep -m1 "1 windows" <<< "$tmateLsResult")" ]; then
      # Set up your session
      echo "Need to re-new tmate session"
      createNewSession "$tmateCmdBase" "$namedSessionCmd" "$setDefaultCmd"
    fi
    # ouput the connection strings to ssh to Mac box
    echo "SSH: ${tmateSSH} | Web shell: ${tmateWeb}"
    # sleep N seconds
    sleep $interval
    # output timelapsed
    echo "Timelapsed => $((tickCounter+=interval)) seconds"
  done
  # return success
  return 0
}

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
  # set value to 2 global variables
  tmateSSH="$(bash -lc "${tmateCmdBase} display -p '#{tmate_ssh}'")"
  tmateWeb="$(bash -lc "${tmateCmdBase} display -p '#{tmate_web}'")"
  
  # if [ -n "$tmateSSH" ]; then
  #   sessionName="$(echo "$tmateSSH" | cut -d ' ' -f 3 | cut -d '@' -f 1)"
  # fi
  
  echo "Created new session successfully"
  # return success
  return 0
}
