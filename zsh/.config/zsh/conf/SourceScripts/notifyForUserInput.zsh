function check_user_input {
    local parent_pid=$(ps -o ppid= -p $$)
    local child_pids=$(pgrep -P $parent_pid)

    for child_pid in $child_pids; do
        local cmd=$(ps -o cmd= -p $child_pid)
        if [[ $cmd =~ "read" ]]; then
            # Customize your notification command or message here
            echo "User input requested in process: $cmd"
        fi
    done
}

precmd_functions+=(check_user_input)
