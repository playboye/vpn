#!/bin/bash

clear
if [[ ! $(cat /boyevpn/user_database.json | jq -r '.xray.vmess[].username') ]]; then
	echo ""
	echo "There are no Vmess users."
	echo ""
	exit 0
fi

source /boyevpn/params
unset choice

n=0
echo ""
for username in $(cat /boyevpn/user_database.json | jq -r '.xray.vmess[].username'); do
	n=$((n+1))
	user[$n]=$username
	echo "[$n] $username"
done
echo ""
echo "[x] Cancel"
echo ""
until [[ $choice -ge 1 ]] && [[ $choice -le $n ]] || [[ $choice == "x" ]]; do
	read -p "Choose user : " choice
	if [[ $choice -lt 1 ]] || [[ $choice -gt $n ]]; then
		[[ $choice != "x" ]] && echo "[ERROR] Invalid choice."
	fi
done
[[ $choice == "x" ]] && echo "" && exit
username=${user[${choice}]}
email=${username}@vmess-${installSubDomain}

cat /usr/local/etc/xray/tls.json | jq 'del(.inbounds[3].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/tls.json.tmp
mv -f /usr/local/etc/xray/tls.json.tmp /usr/local/etc/xray/tls.json
cat /usr/local/etc/xray/ntls.json | jq 'del(.inbounds[3].settings.clients[] | select(.email == "'${email}'"))' > /usr/local/etc/xray/ntls.json.tmp
mv -f /usr/local/etc/xray/ntls.json.tmp /usr/local/etc/xray/ntls.json
systemctl daemon-reload
systemctl restart xray@tls
systemctl restart xray@ntls

cat /boyevpn/user_database.json | jq 'del(.xray.vmess[] | select(.username == "'$username'"))' > /boyevpn/user_database.json.tmp
mv /boyevpn/user_database.json.tmp /boyevpn/user_database.json

clear
echo ""
echo "User '$username' has been deleted successfully."
echo ""
