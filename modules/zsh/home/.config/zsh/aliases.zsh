alias www="cd /var/www"

alias gc='git add . && git commit -m'
alias save='git add -A && git diff --cached --quiet || (printf "Commit message: " && read msg && git commit -m "$msg" && git push)'

alias dcrm='docker ps -aq | xargs -r docker rm -f'
# shellcheck disable=SC2142
alias my_ip="ip address | grep -o \"inet 192.*/\" | awk '{ print \$2 }' | tr / ' ' | xargs"
