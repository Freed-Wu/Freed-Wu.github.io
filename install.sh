#!/usr/bin/env bash
#shellcheck disable=SC2207,SC2015
has_cmd() {
	for opt in "$@"; do
		command -v "$opt" >/dev/null
	done
}
die() {
	echo "$*"
	exit 1
}

has_cmd fq || has_cmd sudo && sudo pacman -S --noconfirm fq || pacman -S --noconfirm fq
programs=($(fq -r '.plugins|join(" ")' _config.yml) ruby-netrc)
if has_cmd yay; then
	yay -S --noconfirm "${programs[@]}"
else
	die please install yay!
fi
