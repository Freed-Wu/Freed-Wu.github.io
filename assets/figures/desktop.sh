#!/usr/bin/env bash
cd "$(dirname "$(readlink -f "$0")")" || exit 1
for organization in gnome kde lxqt xfce-mirror i3 awesomeWM microsoft android openwrt; do
	curl https://api.github.com/users/$organization | jq -r .id | xargs -I{} curl -o$organization.png https://avatars.githubusercontent.com/u/{}
	gm convert -resize 128 $organization.png $organization.png
done
