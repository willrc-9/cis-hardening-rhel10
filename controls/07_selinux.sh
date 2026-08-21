#!/usr/bin/env bash

manage_selinux(){
	# *** Audit Mode ***
	if [[ "$MODE" == "audit" ]]; then
		# 1.3.1.1
		if ! rpm -q libselinux >/dev/null 2>&1; then
			log_warn "SELinux is not installed."
		else
			log_success "SELinux is installed."
		fi

		# 1.3.1.2

		if [[ -n $(grubby --info=ALL | grep -Po '(selinux|enforcing)=0\b') ]]; then
			if [[ -n $(grep -Prs -- '^\h*([^#\n\r]+\h+)?kernelopts=([^#\n\r]+\h+)?(selinux|enforcing)=0\b' /boot/grub2 /boot/efi) ]]; then
				log_success "selinux=0 and enforcing=0 have not been set."
			else
				log_warn "selinux=0 and/or enforcing=0 have been set."
			fi
		else
			log_warn "selinux=0 and/or enforcing=0 have been set."
		fi

		# 1.3.1.3
		grepout=$(grep -Psi -- '^\h*SELINUXTYPE\h*=\h*(targeted|mls)\b' /etc/selinux/config)
		result="${grepout#*=}"
		result=$result | tr '[:lower:]'

		if [[ $result == targeted ]];
			log_success "Audit Passed: SELinux policy is configured."
		else
			log_warn "Audit Failed: SELinux policy is not configured."
		fi
		
		# 1.3.1.4
		if grep -Pqi -- '^\h*SELINUX=(enforcing|permissive)\b' /etc/selinux/config; then
			log_success "Audit Passed - SELinux policy is not in disabled mode"
		else
			log_warn "Audit Failed - SELinux policy is in disabled mode."
		fi
	fi

	# *** Apply Mode ***
	
	# 1.3.1.1
	if ask_yes_no "Run SELinux installer?"; then
		dnf install libselinux
	fi

	# 1.3.1.2
	if ask_yes_no "Enable SELinux at boot (through grub)?"; then
		grubby --update-kernel ALL --remove-args "selinux=0 enforcing=0"
		grep -Prsq -- '^\h*([^#\n\r]+\h+)?kernelopts=([^#\n\r]+\h+)?(selinux|enforcing)=0\b' /boot/grub2 /boot/efi && grub2-mkconfig -o "$(grep -Prl -- '\h*([^#\n\r]+\h+)?kernelopts=([^#\n\r]+\h+)?(selinux|enforcing)=0\b' /boot/grub2 /boot/efi)"
	fi

	# 1.3.1.3
	if ask_yes_no "Configure SELinux policy?"; then	
		log_info "Creating backup of /etc/selinux/conf if exists..."
		if [[ -f /etc/selinux/config ]]; then
			cp -n /etc/selinux/config /etc/selinux/config.bak
		fi
		sed -i '/^\s*SELINUXTYPE\s*=/d' /etc/selinux/config
		echo "SELINUXTYPE=targeted"
		log_success "Successfully configured SELinux policy."
	fi

	# 1.3.1.4
	if ask_yes_no "Set SELinux mode to enforcing?"; then
		touch /.autorelabel
		sed -i '/^\s*SELINUX\s*=/d' /etc/selinux/config
		echo "SELINUX=enforcing" >> /etc/selinux/config
		setenforce 1
		log_info "Please reboot after script is done running."
		log_success "Successfully set SELinux to \"enforcing\" mode"
	fi
	
	1.3.1.5


}

run_selinux(){
	log_info "Running SELinux - CIS 1.3"
	manage_selinux
	log_success "Successfully completed SELinux - CIS 1.3"
}
control_runners "selinux" "run_selinux"
