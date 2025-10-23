#!/bin/bash
#####
# Put in bashrc/bash_aliases/...
# if [ -f ~/scripts/pwsh_func.sh ]; then
#   . ~/scripts/pwsh_func.sh
# fi
#####

pwsh() {
    # VS2022 Pro paths (hard-coded for speed)
    local VS_INSTALL_PATH_WINDOWS='C:\Program Files\Microsoft Visual Studio\2022\Professional'
    local DEV_SHELL_DLL="$VS_INSTALL_PATH_WINDOWS\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"

    # Map WSL PWD to Windows path
    local WINPWD
    WINPWD="$(wslpath -w "$PWD")"

    if [ $# -eq 0 ]; then
        # Interactive: enter Dev Shell, then force back to current dir
        local PS_CMD
        PS_CMD="[void](Import-Module '$DEV_SHELL_DLL' -ErrorAction Stop); Enter-VsDevShell -VsInstallPath '$VS_INSTALL_PATH_WINDOWS' -DevCmdArguments '-arch=x64 -host_arch=x64'; Set-Location -LiteralPath '$WINPWD'"
        /mnt/c/Program\ Files/PowerShell/7/pwsh.exe -NoLogo -NoProfile --NoExit -Command "$PS_CMD"
        return $?
    fi

    # One-off command mode: no Dev Shell; run in current dir
    /mnt/c/Program\ Files/PowerShell/7/pwsh.exe -NoLogo -NoProfile -WorkingDirectory "$WINPWD" -Command "$*"
}


# pwsh() {
#   local exit_flag=""
#   local args=()
#   local ps_command=""
#
#   if [[ $# -eq 0 ]]; then
#     # No arguments, start pwsh interactively without exiting
#     /mnt/c/Program\ Files/PowerShell/7/pwsh.exe --NoExit
#     return $?
#   fi
#
#   while [[ $# -gt 0 ]]; do
#     case "$1" in
#       --noexit|-n)
#         exit_flag="--NoExit"
#         shift
#         ;;
#       *)
#         args+=("$1")
#         shift
#         ;;
#     esac
#   done
#
#   # Combine arguments into a single command string
#   ps_command="${args[*]}"
#
#   if [[ -z "$ps_command" ]]; then
#     # No command specified after options, start pwsh interactively
#     /mnt/c/Program\ Files/PowerShell/7/pwsh.exe --NoExit
#     return $?
#   else
#     # Execute the command(s)
#     /mnt/c/Program\ Files/PowerShell/7/pwsh.exe $exit_flag -Command "$ps_command"
#     local ps_exit_code=$?
#     return $ps_exit_code
#   fi
# }
#
