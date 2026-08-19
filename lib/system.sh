#!/usr/bin/env bash

get_os_version() {
	source /etc/os-release
	echo "${VERSION_ID:-}"
}

get_os_name() {
	if [[ -f /etc/os-release ]]; then
		grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"'
	elif [[ -f /etc/rehat-release ]]; then
		cat /etc/redhat-release
	else
		echo "Unknown Enterprise Linux Distribution"
	fi
}

get_hostname() {
	hostname
}

get_kernel() {
	uname -r
}

is_module_loaded() {
	local module="$1"
	lsmod | awk '{print $1}' | grep -qx "$module"
}

module_exists() {
	local module="$1"
	modinfo -n "$module" >/dev/null 2>&1
}

is_pkg_installed() {
	rpm -q "$1" >/dev/null 2>&1
}

ask_yes_no() {
	local prompt="$1"
	
	if [[ "$AUTO_YES" == "true" ]]; then
		log_info "[AUTO-APPROVED] $prompt"
		return 0
	fi
	

	read -r -p "$prompt [y/N]: " response
	case "$response" in
		[yY][eE][sS]|[yY])
			return 0
			;;
		*)
			return 1
			;;
	esac
}
