#!/usr/bin/env bash

local failed=0

auditMod() {
   l_mod_name="$1" l_mod_type="drivers"
   while IFS= read -r l_mod_path; do
      if [ -d "$l_mod_path/${l_mod_name//-/\/}" ] &&  \
      [ -n "$(ls -A "$l_mod_path/${l_mod_name//-/\/}")" ]; then
         printf '%s\n' "$l_mod_name exists in $l_mod_path"
      fi
   done < <(readlink -e /usr/lib/modules/**/kernel/$l_mod_type \
   || readlink -e /lib/modules/**/kernel/$l_mod_type)
}

manage_kernel_modules() {
  	log_info "Starting CIS Kernel Module Hardening (USB/Firewire)"

  	local misc_modules=(
    		"usb-storage"
    		"firewire-core"
	)
	
  	# *** Audit Mode ***

  	if [[ "$MODE" == "audit" ]]; then
  		for mod in "${misc_modules[@]}"; do
    			if is_whitelisted "$mod"; then
      				log_info "Skipping "$mod": Module is present in MODULE_ALLOWLIST."
      				continue
    			fi
			if [[ -z $(auditMod "$mod") ]]; then
				log_success "Audit Passed: "$mod" is not available on this system."
			else
				if [[ $mod == 'usb-storage' ]]; then
					if [[ -z $(lsmod | grep -P -- 'usb(_|-)storage' || true) && -n $(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+usb_storage\b' || true) ]]; then
						log_success "Audit Passed: $mod is not loadable."
					else
						log_warn "Audit Failed: $mod is available on this system."
						failed=1
					fi
				else
					if [[ -z $(lsmod | grep -P -- 'firewire(_|-)core' || true) && -n  $(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+firewire(_|-)core\b' || true) ]]; then
						log_success "Audit Passed: $mod is not loadable."
					else
						log_warn "Audit Failed: $mod is available on this system."
						failed=1
					fi
				fi
			fi
  		done
		return $failed
	fi

	# *** Apply Mode ***
	for mod in "${misc_modules[@]}"; do
		if ask_yes_no "Disable $mod?"; then
			touch /etc/modprobe.d/60-$mod.conf
			modprobe -r $mod 2>/dev/null || true
			rmmod $mod 2>/dev/null || true
			log_info "Writing to /etc/modprob.d/60-$mod.conf..."
			printf '%s\n' "" "install $mod /bin/false" >> /etc/modprobe.d/60-$mod.conf
		fi
		log_success "Successfully disabled $mod."
	done



  log_success "Kernel module hardening completed."

}

run_kernel_modules() {
	log_info "Starting Kernel Modules (CIS 1.1.1.9-10)"
	manage_kernel_modules
	log_success "Completed Kernel Modules (CIS 1.1.1.9-10)"
}

register_control "kernel_modules" "run_kernel_modules"
