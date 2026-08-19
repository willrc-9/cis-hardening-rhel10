#!/usr/bin/env bash

run_initial_setup() {
  log_info "Running initial setup phase..."
  require_root

  require_commands dnf systemctl grep sed awk find sysctl modprobe lsmod

  # Only create directories if we are actively applying changes
  if [[ "$MODE" == "apply" ]]; then
    ensure_directory /var/log
    ensure_directory "$BACKUP_DIR"
    log_success "Required framework directories verified/created."
  else
    log_info "Audit Mode: Directory creation skipped."
  fi

  log_info "Target OS: $(get_os_name)"
  log_info "Kernel: $(get_kernel)"
  log_info "Hostname: $(get_hostname)"
}

register_control "init" "run_initial_setup"
