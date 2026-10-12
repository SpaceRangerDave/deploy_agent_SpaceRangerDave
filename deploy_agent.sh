#!/usr/bin/env bash

deploy_the_application(){
    echo "This feature creates the directories, creates the files, and populates them"
    perform_pre_flight_checks
    create_project_structure
    
}

run_the_application(){
    echo "A standalone feature that executes the app on an already deployed project:"
}

archive_file_logs(){ 
    echo "After a run, archive the generated logs."
}

perform_pre_flight_checks(){
    if ! command -v zip > /dev/null 2>&1; then
    echo "Zip is missing, install it first"
    exit 1
    else
    echo "Zip exists, will proceed to check for Python"
    sleep 2 # small pause so it feels like the script is really checking for python (might remove it)
    fi

    if ! command -v python3 > /dev/null 2>&1; then
    echo "Python is missing, install it first"
    exit 1
    else
    echo -n "Python Version: "; python3 --version
    fi 
}

create_project_structure(){
    read -p "Enter a project name: " project_name

    if [ -z "$project_name" ]; then 
        echo "Aborting ...Project name can't be empty."
        exit 1
    fi

    project_dir="attendance_tracker_$project_name"

    if [ -e "$project_dir" ]; then 
        read -p "$project_dir already exists. Overwrite? (y/n): " answer

        if [ "$answer" = "y" ]; then
            rm -rf "$project_dir"
        else
            echo "Aborting so nothing gets overwritten"
            exit 1
        fi
    fi 
    mkdir -p "$project_dir/Helpers" "$project_dir/reports"    
}

echo "1) Deploy The Application"
echo "2) Run the Application"
echo "3) Archive file logs"
echo "4) Exit"

read -p "Pick a number: " user_choice

case "$user_choice" in
    1) deploy_the_application;;
    2) run_the_application;;
    3) archive_file_logs;;
    4) echo "Goodbye" ;;
    *) echo "Invalid choice" ;;
esac
