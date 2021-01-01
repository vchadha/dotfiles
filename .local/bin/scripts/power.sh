#!/bin/sh

entries="⏻ Shutdown, Reboot,⏾ Suspend, Logout, Lock"

selected=$(echo $entries | rofi -m 0 -dmenu -sep ',' -p "" -i | awk '{print tolower($2)}')

case $selected in
  lock) 
    exec ~/.local/bin/scripts/lock.sh;;
  logout)
    swaymsg exit;;
  suspend)
    exec systemctl suspend;;
  reboot)
    exec systemctl reboot;;
  shutdown)
    exec systemctl poweroff -i;;
esac
