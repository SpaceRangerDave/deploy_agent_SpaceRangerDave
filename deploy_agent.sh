#!/usr/bin/env bash

deploy_the_application(){
    echo "This feature creates the directories, creates the files, and populates them"
    perform_pre_flight_checks
    
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
    python3 --version
    fi 

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
