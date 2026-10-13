#!/usr/bin/env bash

deploy_the_application(){
    echo "This feature creates the directories, creates the files, and populates them"
    perform_pre_flight_checks
    create_project_structure
    copy_template_files
    copy_or_generate_roster
    
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

copy_template_files(){
    echo "Copying Templates files..."
    sleep 2 # small pause for asthetics (might remove it) 

    cp templates/attendance_checker.py "$project_dir/" && echo "Copied attendance_checker.py"|| { exit 1; }

    cp templates/config.json "$project_dir/Helpers/" && echo "Copied config.json" || { exit 1; }

    sleep 2 # small pause for asthetics (might remove it)

    echo "Template files copied into $project_dir"
}

copy_student_roster_from_template(){
    available=$(( $(grep -c . templates/assets.csv) - 1 ))
    read -p "How many students to copy (1-$available)? " count

    if [[ ! "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ] || [ "$count" -gt "$available" ]; then
        echo "Please enter a whole number from 1 to $available" >&2
        exit 1
    fi

    head -n $((count + 1)) templates/assets.csv > "$project_dir/Helpers/assets.csv"
    echo "Copied $count students into the roster"
}

generate_fresh_student_roster(){
    names=("Mussab Atif Ibrahim Abdelgadir" "Bill Francis Ajengo" "Felix Chifumnanya Akpu" "Akuol Juach Agok Anyar" "Mucyo Kayibanda Blaise" "Brandon Nshuti Bugingo" "Teta Christella" "Gold Adaobi Cole-Okafor" "Tona Faradowza" "Keji Vicky Wani Hillario" "Latonia Igihozo" "Eden Ganael Ntahonkiriye Intwari" "David Ishimwe" "Shekinah Eva Kamikazi" "Fiorella Demba Keza" "Neema Nyokabi Maina" "Hwa-Pyong Edouard Maniragaba" "Miriam Daniel Meles" "Ian Maranga Misati" "Derrick Mugire" "Frank Mugisha" "Aristide Niyokwizerwa" "Benjamin Mugisha Ntege" "Obichukwu Sidney Nwosu" "David Olowatomisin Oladapo" "Nyamesomfo Ama Osei-Nimako" "Raymond Odhiambo Otieno" "Benjamin Kwagala Semakula" "Prosper Shimwa" "Thierry Sugira" "Teninlanimi David Taiwo" "Kevine Umuganwa" "Lewis Gathungu Wanjiku" "steve Dessoue Yambouka")

    emails=("mussab@example.com" "bill@example.com" "felix@example.com" "akuol@example.com" "mucyo@example.com" "brandon@example.com" "teta@example.com" "gold@example.com" "tona@example.com" "keji@example.com" "latonia@example.com" "eden@example.com" "david.ishimwe@example.com" "shekinah@example.com" "fiorella@example.com" "neema@example.com" "hwa-pyong@example.com" "miriam@example.com" "ian@example.com" "derrick@example.com" "frank@example.com" "aristide@example.com" "benjamin.ntege@example.com" "obichukwu@example.com" "david.oladapo@example.com" "nyamesomfo@example.com" "raymond@example.com" "benjamin.semakula@example.com" "prosper@example.com" "thierry@example.com" "teninlanimi@example.com" "kevine@example.com" "lewis@example.com" "steve@example.com")  

    available=${#names[@]}

    read -p "How many students to generate (1-$available)? " count

    if [[ ! "$count" =~ ^[0-9]+$ ]] || [ "$count" -lt 1 ] || [ "$count" -gt "$available" ]; then
        echo "Please enter a whole number from 1 to $available" >&2
        exit 1
    fi

    echo "Email,Names,Attendance Count,Absence Count" > "$project_dir/Helpers/assets.csv"

    for ((i=0; i<count; i++)); do
        printf "%s,%s,0,0\n" "${emails[i]}" "${names[i]}" >> "$project_dir/Helpers/assets.csv"
    done
    echo "Generated $count students into the roster"

    sed -i 's/"total_sessions": [0-9]*/"total_sessions": 1/' "$project_dir/Helpers/config.json"
    echo "total_sessions set to 1 because this roster is brand new"
}


copy_or_generate_roster(){
    sleep 2 # small pause for asthetics (might remove it)
    echo "Would you like to copy roster from template or Generate a fresh one ?"
    echo "A) Copy from the template"
    echo "B) Generate a fresh roster"

    read -p "Pick a letter: " user_roster_choice

    case "$user_roster_choice" in
        A|a) copy_student_roster_from_template;;
        B|b) generate_fresh_student_roster;;
        *) echo "Invalid choice" >&2; exit 1 ;;
    esac
}

# Main Menu
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
