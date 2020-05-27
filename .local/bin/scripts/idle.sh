swayidle -w \
	timeout 300 '~/.local/bin/scripts/lock.sh' \
	timeout 600 'swaymsg "output * dpms off"' \
	    resume 'swaymsg "output * dpms on"' \
	before-sleep '~/.local/bin/scripts/lock.sh'
