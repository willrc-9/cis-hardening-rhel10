#!/usr/bin/env bash

manage_rpm() {
	local failed=0
	# *** Audit Mode ***
	if [[ "$MODE" == "audit" ]]; then
		
		# 1.2.1

		# Ensure GPG keys are configured
		log_info "Manual Audit Required: Please check GPG keys, compare to relevant repositories public key page to confirm they are correct."
		if ask_yes_no "View gpg-pubkey list?"; then
			for RPM_PACKAGE in $(rpm -q gpg-pubkey); do
  				echo "RPM: ${RPM_PACKAGE}"
  				RPM_SUMMARY=$(rpm -q --queryformat "%{SUMMARY}" "${RPM_PACKAGE}")
  				RPM_PACKAGER=$(rpm -q --queryformat "%{PACKAGER}" "${RPM_PACKAGE}")
  				RPM_DATE=$(date +%Y-%m-%d -d "1970-1-1+$((0x$(rpm -q --queryformat "%{RELEASE}" "${RPM_PACKAGE}") ))sec")
  				RPM_KEY_ID=$(rpm -q --queryformat "%{VERSION}" "${RPM_PACKAGE}")
  				echo "Packager: ${RPM_PACKAGER}
			Summary: ${RPM_SUMMARY}
			Creation date: ${RPM_DATE}
			Key ID: ${RPM_KEY_ID}
			"
			done
		fi

		# gpgcheck is configured
		grpout=$(grep -Pi -- '^\h*gpgcheck\h*=\h*(1|true|yes)\b' /etc/dnf/dnf.conf | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' || true)
		if [[ $grpout == "gpgcheck=1" || $grpout == "gpgcheck=true" || $grpout == "gpgcheck=yes" ]]; then
			if [[ -z $(grep -Pris -- '^\h*gpgcheck\h*=\h*(0|[2-9]|[1-9][0-9]+|false|no)\b' /etc/yum.repos.d/ || true) ]]; then
	                        log_success "gpgcheck is enabled and not disabled in a file in the /etc/yum.repos.d/ directory."
                	else
                        	failed=1
                        	log_warn "gpgcheck is enabled, but diasbled in a file in the /etc/yum.repos.d/ directory."
                	fi
		else
			failed=1
			log_warn "gpgcheck is not enabled."
		fi

		# ensure repo_gpgcheck is globally activated

		if [[ $(grep ^repo_gpgcheck /etc/dnf/dnf.conf) != "repo_gpgcheck=1" ]]; then
			log_warn "Audit Failed: repo_gpgcheck is not globally activated."
		fi

		# ensure package manager repositories are configured
		log_info "Please read below text: "
		echo "# ============================================#"
		echo "#                                             #"
		echo "#     Please make sure to manually check      #"
		echo "# repositories, using the following commands: #"
		echo "#                                             #"
		echo "#      # cat /etc/yum.repos.d/*.repo          #"
		echo "#      # dnf repolist                         #"
		echo "#                                             #"
		echo "#=============================================#"


		# Ensure weak deps are configured
		if grep -Pi -- '^\h*install_weak_deps\h*=\h*(0|false|no)\b' /etc/dnf/dnf.conf; then
			log_success "Weak dependencies are configured."
		else
			failed=1
			log_warn "Weak dependencies are not configured."
		fi

		# 1.2.2
		
		# Ensure updates, patches, and additional security software are installed
		log_info "Please read below text: "
                echo "# ============================================#"
                echo "#                                             #"
                echo "#     Please make sure to manually check      #"
                echo "#    updates, using the following commands:   #"
                echo "#                                             #"
                echo "#      # dnf check-update                     #"
                echo "#      # dnf needs-restarting -r              #"
                echo "#                                             #"
                echo "#=============================================#"

		return $failed
	fi

	# *** Apply Mode ***

	log_info "Creating backup of /etc/dnf/dnf.conf if exists..."

	if [[ -f /etc/dnf/dnf.conf ]]; then
		cp -n /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak
	fi

	log_info "Manual remediation required for 1.2.1.1. Please see $SCRIPT_DIR/helperScripts/ for help."
        
	# 1.2.1.2
	if ask_yes_no "Configure gpgcheck?"; then
		sed -i '/^\s*gpgcheck\s*=/d' /etc/dnf/dnf.conf
		echo "gpgcheck=1" >> /etc/dnf/dnf.conf
		log_success "Enforced gpgcheck=1 in /etc/dnf/dnf.conf"
		find /etc/yum.repos.d/ -name "*.repo" -exec echo "Checking:" {} \; -exec sed -i 's/^\gpgcheck\s*=\s*.*/gpgcheck=1/' {} \;

	fi

	# 1.2.1.3
        if ask_yes_no "Configure repo_gpgcheck?"; then
                sed -i '/^\s*repo_gpgcheck\s*=/d' /etc/dnf/dnf.conf
                echo "repo_gpgcheck=1" >> /etc/dnf/dnf.conf
                log_success "Enforced repo_gpgcheck=1 in /etc/dnf/dnf.conf"
	fi
	
	# 1.2.1.4
	log_info "Manual remediation required for 1.2.1.4. Please see $SCRIPT_DIR/helperScripts/ for help."
        
        # 1.2.1.5
        if ask_yes_no "Configure weak dependencies?"; then
                sed -i '/^\s*install_weak_deps\s*=/d' /etc/dnf/dnf.conf
                echo "install_weak_deps=0" >> /etc/dnf/dnf.conf
                log_success "Enforced install_weak_deps=0 in /etc/dnf/dnf.conf"
        fi

	if ask_yes_no "Check for updates?"; then
		dnf update
		dnf needs-restarting -r
	fi
}

run_rpm() {
	log_info "Starting RPM (CIS 1.2 - Package Management)"
	manage_rpm
	log_success "Completed RPM (CIS 1.2 - Package Management)"
}
register_control "rpm" "run_rpm"
