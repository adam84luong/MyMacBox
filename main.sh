# main script
startMyBox() {
  # preparing tmate command
  local sockPath="/tmp/tmate.sock"
  local tmateBashPath="/tmp/tmate.bashrc"

  echo 'set +e' >"$tmateBashPath"
  local setDefaultCmd="set-option -g default-command \"bash --rcfile $tmateBashPath\" \\;"
  
  local tmateCmdBase="tmate -S $sockPath"
  local namedSessionCmd="-k $TMAK -F"
  
  local tmateWeb=""
  local tmateSSH=""
  local sessionName=""
  # createNewSession "$tmateCmdBase" "$namedSessionCmd" "$setDefaultCmd"
  local tmateLsResult=""
  
  # convert to seconds
  local timeToAlive=$((TIME_TO_ALIVE*60))
  # seconds
  local interval=60
  local tickCounter=0
  
  echo "timeToAlive in seconds => $timeToAlive"
  
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
      createNewSession "$tmateCmdBase" "$namedSessionCmd" "$setDefaultCmd"
      # ouput the connection strings to ssh to Mac box
      echo "SSH: ${tmateSSH} | Web shell: ${tmateWeb}"
      # output timelapsed
      echo "Timelapsed => $tickCounter seconds"
    fi
    # sleep N seconds
    sleep $interval
    # pumb up tick count
    tickCounter=$((tickCounter + interval))
  done
  echo "Timelapsed => $tickCounter seconds"
  # return success
  return 0
}

openTunnel() {
  # convert to seconds
  local timeToAlive=$((TIME_TO_ALIVE*60))
  # seconds
  local interval=60
  local tickCounter=0
  
  echo "timeToAlive in seconds => $timeToAlive"
  
  #ssh-add ~/.ssh/mymacbox_rsa && ssh-add -L && ssh-add -l
  #ssh -i ~/.ssh/mymacbox_rsa -f -o ExitOnForwardFailure=yes -R 22841:127.0.0.1:22 a84l@a84l.ddns.net -p22840 sleep 30
  ssh -i ~/.ssh/mymacbox_rsa -R 22841:127.0.0.1:22 a84l@a84l.ddns.net -p22840
  
  echo "Entering main loop"
  while [ $tickCounter -lt $timeToAlive ]; do
    echo "Timelapsed => $tickCounter seconds"
    # sleep N seconds
    sleep $interval
    # pumb up tick count
    tickCounter=$((tickCounter + interval))
  done
  echo "Timelapsed => $tickCounter seconds"
  # return success
  return 0
}

# utility function

preparingStuff() {
  sshBasePath="$HOME/.ssh"
  idrsaPath="$sshBasePath/id_rsa"
  tmateConfigPath="$HOME/.tmate.conf"
  authorizedKeysPath="$sshBasePath/authorized_keys"
  # copy over config file
  cp ./.tmate.conf $tmateConfigPath
  if $IS_SELFHOSTED_SERVER; then
    echo "$TMATE_SERVER_CFG" >> $tmateConfigPath
  fi
  echo "set tmate-authorized-keys \"$HOME/.ssh/authorized_keys\"" >> $tmateConfigPath
  cat "$tmateConfigPath"
  # generate authorized_keys file
  echo "$PUB_KEY_4_MMB" >> "$authorizedKeysPath"
  cat "$authorizedKeysPath"
  # set permission for .ssh folder and authorized_keys file
  chmod 700 "$sshBasePath"
  chmod 600 "$authorizedKeysPath"
  # Generating SSH keys
  echo "Generating SSH keys"
  echo -e 'y\n'|ssh-keygen -q -t rsa -N "" -f "$idrsaPath"
  echo "$KNOWN_HOSTS_ENTRY" >> "$sshBasePath/known_hosts"
  cat "$sshBasePath/known_hosts"
  echo "$PUB_KEY_4_MMB" > "$sshBasePath/mymacbox_rsa.pub"
  echo "$PRV_KEY_4_MMB" > "$sshBasePath/mymacbox_rsa"
  chmod 700 "$sshBasePath/mymacbox_rsa.pub"
  chmod 600 "$sshBasePath/mymacbox_rsa"
  ls -l "$sshBasePath"
  eval `ssh-agent`
  ssh-add "$sshBasePath/mymacbox_rsa"
  ssh-add -l
  ssh-add -L
  echo "Generated SSH-Key successfully"
}

createNewSession() {
  local tmateCmdBase="$1"
  local namedSessionCmd="$2"
  local setDefaultCmd="$3"
  
  local newSessionCmd="${tmateCmdBase} ${namedSessionCmd} ${setDefaultCmd} new-session -d"
  local waitTmateReadyCmd="${tmateCmdBase} wait tmate-ready"
  
  #echo "Creating new session..."
  
  # echo "${newSessionCmd}"
  # echo "${waitTmateReadyCmd}"
  bash -lc "${newSessionCmd}" && bash -lc "${waitTmateReadyCmd}" &
  
  showProgressAsync "Creating new session..." 3
  
  wait $!
  
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

showProgressAsync() {
  local msg="$1"
  local duration=$2
  # start stopwatch
  local stopwatch=$SECONDS
  local tickCounter=0
  # echo original message
  echo "$msg"
  local progressBar=""
  while [ $tickCounter -le $duration ]; do
    tickCounter=$((SECONDS - stopwatch))
    progressBar="$progressBar."
    echo -ne "$progressBar\r"
    sleep 1
    #if [ $tickCounter -lt $duration ]; then
    #
    #   fi
  done
}
