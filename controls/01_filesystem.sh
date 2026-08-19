#!/usr/bin/env bash

# fs names
manage_filesystems() {
local failed=0

checkMod() {
	shopt -s globstar
	l_mod_name="$1" l_mod_type="fs"
	while IFS= read -r l_mod_path; do
      		if [ -d "$l_mod_path/${l_mod_name//-/\/}" ] &&  \
      		[ -n "$(ls -A "$l_mod_path/${l_mod_name//-/\/}")" ]; then
         		printf '%s\n' "$l_mod_name exists in $l_mod_path"
      		fi
   	done < <(readlink -e /usr/lib/modules/**/kernel/$l_mod_type \
   	|| readlink -e /lib/modules/**/kernel/$l_mod_type)
}


# Filenames to block or audit
modname=(
	"cramfs"
	"freevxfs"
	"hfs"
	"hfsplus"
	"jffs2"
	"overlay"
	"squashfs"
	"udf"
)

# *** Audit Mode ***

if [[ "$MODE" == "audit" ]]; then
	for mod in "${modname[@]}"; do
		#check if module is loaded
		if [[ -z $(checkMod "$mod") ]]; then
			log_success "$mod is not available on system."
		else
			if [[ -z $(lsmod | grep "$mod") && ! -n $(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+squashfs\b')  || true ]]; then
				log_success "$mod is available on the system, but is not loaded or loadable."
			else
				log_warn "$mod is available on system"
				failed=1
			fi
		fi		
		
	done
	return $failed
fi


# *** Apply Mode ***
#for loop to go through all fs
for mod in "${modname[@]}"; do
	if  ask_yes_no "Remove $mod?"; then
		#unload module
		modprobe -r $mod 2>/dev/null || true
		rmmod $mod 2>/dev/null || true
	
		log_success "Removed '$mod' from device."

		#blacklist module
		touch /etc/modprobe.d/99-cis-$mod.conf
		printf '%s\n' "" "install $mod /bin/false" >> /etc/modprobe.d/99-cis-$mod.conf
	fi
done
}
run_filesystems(){
	log_info "Running Filesystems (CIS 1.1.1)"
	manage_filesystems
	log_success "Filesystems Completed."
}
register_control "filesystems" "run_filesystems"
