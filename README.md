# deploy_agent

![Bash](https://img.shields.io/badge/Bash-Shell_Script-4EAA25?logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)
![Platform](https://img.shields.io/badge/Tested_on-Ubuntu_24.04_LTS-E95420?logo=ubuntu&logoColor=white)
![Last commit](https://img.shields.io/github/last-commit/SpaceRangerDave/deploy_agent_SpaceRangerDave)
![Repo size](https://img.shields.io/github/repo-size/SpaceRangerDave/deploy_agent_SpaceRangerDave)
![Status](https://img.shields.io/badge/Status-Summative_submission-blue)

A shell script that bootstraps, runs and archives a Python **Student Attendance Tracker**, and cleans up after itself if the deployment is interrupted.

This repo is my **Scripting Summative Lab** for the Introduction to Linux and IT Tools course. The task: build one script, `deploy_agent.sh`, that does the setup work a person would otherwise do by hand (folders, files, permissions, config) so every deployment comes out identical. I did not touch `attendance_checker.py`. Everything here is shell scripting *around* it.

## Contents

- [What the script does](#what-the-script-does)
- [Repository layout](#repository-layout)
- [How to run it](#how-to-run-it)
- [Feature 1: Deploy](#feature-1-deploy)
- [Feature 2: Run](#feature-2-run)
- [Feature 3: Archive logs](#feature-3-archive-logs)
- [Ctrl+C and Ctrl+Z handling](#ctrlc-and-ctrlz-handling)
- [How I tested it](#how-i-tested-it)
- [Known limitations](#known-limitations)
- [Demo video](#demo-video)

## What the script does

| Menu option | Feature | In one line |
|---|---|---|
| 1 | Deploy | Checks tools, builds the project folder, copies files, builds the roster, sets permissions, offers to update thresholds, then starts the app |
| 2 | Run | Starts the app inside an already deployed project |
| 3 | Archive | Saves timestamped copies of the session logs |
| 4 | Exit | Quits |

I chose an **interactive menu** over command-line flags. The person using this is an instructor at a terminal, so a numbered menu is easier to use and easier to demo than remembering `--deploy`. Flags would be the better pick if this ever had to run unattended.

## Repository layout

```
deploy_agent_SpaceRangerDave/
├── deploy_agent.sh          # the script (all three features + signal handling)
├── templates/               # the three provided files, never modified
│   ├── attendance_checker.py
│   ├── assets.csv
│   └── config.json
├── .gitignore               # hides deployed test projects and interrupt zips
└── README.md
```

A deployed project looks like this:

```
attendance_tracker_{name}/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
├── reports/                 # starts empty, the app writes its logs here
└── archives/                # created the first time you archive
    ├── attendance/
    └── absent/
```

The files in `templates/` are the master copies. The script only ever copies *from* them and edits the *copy*, so two deployments never affect each other.

## How to run it

You need `python3` and `zip` installed. The script checks for both.

```bash
git clone https://github.com/SpaceRangerDave/deploy_agent_SpaceRangerDave.git
cd deploy_agent_SpaceRangerDave
chmod +x deploy_agent.sh
./deploy_agent.sh
```

You will see:

```
1) Deploy The Application
2) Run the Application
3) Archive file logs
4) Exit
Pick a number:
```

Type a number and press Enter. Anything else prints "Invalid choice".

## Feature 1: Deploy

The steps always run in this order:

1. **Pre-flight checks.** The script confirms `zip` and `python3` exist and prints the Python version. If either is missing it prints which one and stops before creating anything.
2. **Name the project.** It asks for a name and builds `attendance_tracker_{name}/`. An empty name is rejected. If the folder already exists it asks whether to overwrite. Answering anything other than `y` aborts and leaves the old project untouched.
3. **Copy the fixed files.** `attendance_checker.py` goes into the project root and `config.json` into `Helpers/`, unmodified. If a copy fails, the script stops.
4. **Build the roster.** You pick one of two options:
   - **A: copy from the template.** It asks how many students (the valid range is counted from the template file, so it adjusts if the template changes) and copies that many rows plus the header.
   - **B: generate a fresh roster.** It asks how many students and builds the rows from name and email arrays inside the script, with both counts starting at `0`.
5. **Set permissions.** `attendance_checker.py` becomes executable (`chmod +x`) and `Helpers/config.json` becomes owner read/write only (`chmod 600`). The script prints `ls -l` for both files as confirmation.
6. **Offer to update the thresholds.** See below.
7. **Start the app.** The deploy ends by launching the attendance app. If it starts, the structure, roster and config all work together.

### How the roster relates to `total_sessions`

`total_sessions` in `config.json` is the number of sessions *including today's*, so it has to be one more than the sessions already recorded in the roster.

| Option | Roster | `total_sessions` |
|---|---|---|
| A (template) | Each student has 4 prior sessions | `5` (the template value, left alone) |
| B (generated) | Everyone starts at 0 | `1` (the script changes it with `sed`) |

There is no prompt for this. The script ships the consistent value for whichever option was chosen.

If you run the app more than once on the same project, the roster counts grow but `total_sessions` does not, so the app prints a note like "has 5 prior sessions on record, expected 4 - proceeding anyway". That is expected. A fresh deploy resets it.

### How the threshold update works

The script asks: *Update the attendance alert thresholds in config.json? (y/n)*. Anything other than `y` or `Y` keeps the defaults.

If you answer yes:

1. It reads a new `warning` value (press Enter for the default **75**) and a new `failure` value (press Enter for **50**).
2. It checks **both** values *before* touching the file:
   - each must be a whole number (a regex `^[0-9]+$` rejects empty text, letters, negatives and decimals)
   - each must be 100 or less
   - `failure` must be strictly **lower** than `warning`. If failure were higher, a student could fail without ever being warned first.
3. Only after every check passes does it run two `sed` edits that target the `"warning": <number>` and `"failure": <number>` lines. The file is never reformatted or reordered.

Validating first matters: if the script edited `warning` and then found a bad `failure`, `config.json` would be left half-updated. On bad input the script prints the reason and exits with status 1 instead of silently falling back to defaults, because the user clearly wanted custom values.

## Feature 2: Run

Option 2 asks for the project name, checks that `attendance_tracker_{name}/` exists and contains `attendance_checker.py`, then runs the app from inside the project:

```bash
( cd "$run_project_dir" && python3 attendance_checker.py )
```

The parentheses run the `cd` in a subshell, so the script itself stays in the repo root afterwards. The app is interactive: it asks for each student to be marked present or absent, updates `Helpers/assets.csv`, and writes `reports/attendance.log` and `reports/absent.log`. A missing project or missing script prints an error and exits with status 1.

## Feature 3: Archive logs

Option 3 asks for the project name, then archives whichever logs exist in `reports/`:

```
attendance_tracker_{name}/archives/
├── attendance/attendance_YYYYMMDD_HHMMSS.log
└── absent/absent_YYYYMMDD_HHMMSS.log
```

- The timestamp is taken **once** per run with `date +%Y%m%d_%H%M%S`, so the two logs from one archive share it, and every archive is unique and traceable.
- The logs are **copied**, not moved. The originals stay in `reports/`, so the app's live logs are not pulled out from under it.
- `mkdir -p` creates the archive folders, so running it repeatedly is safe.
- It prints which logs were archived and where.
- If a log does not exist (for example nobody was absent, so there is no `absent.log`), the script reports "nothing to archive" for that log and carries on with the other one. It does not crash.

## Ctrl+C and Ctrl+Z handling

During a deploy the script traps both `SIGINT` (Ctrl+C) and `SIGTSTP` (Ctrl+Z). **The archive trigger is either of those signals arriving while deployment is in progress.** The handler then:

1. prints that the deployment was interrupted
2. zips whatever exists of the project into `attendance_tracker_{name}_archive.zip` (using the `zip` command)
3. **deletes** the incomplete project folder, but only after the zip succeeded
4. exits cleanly with status 1

Two safeguards:

- A `project_created` flag is set only after the script itself creates the folder. If you press Ctrl+C at the *"Overwrite? (y/n)"* prompt, an old project exists but this run built nothing, so the handler reports "nothing to archive" and leaves your old project alone.
- If you interrupt before a project name is entered, there is nothing to zip, so it exits without creating anything.

The trap is switched off with `trap - SIGINT SIGTSTP` just before the attendance app starts, because the lab says the trap covers the *script's* deployment, not the marking session.

### How to test it

1. Run `./deploy_agent.sh`, pick `1`, name the project `trap1`.
2. Choose `a` at the roster menu.
3. At *"How many students to copy"*, press **Ctrl+C**.
4. Run `ls`. You should see `attendance_tracker_trap1_archive.zip` and **no** `attendance_tracker_trap1` folder.
5. Run `zip -sf attendance_tracker_trap1_archive.zip` to list the contents.
6. Repeat with a new name, pressing **Ctrl+Z** instead.

### What the zip contains

Whatever existed at the moment of interruption. When I interrupted at the roster question, the zip held:

```
attendance_tracker_test1/
attendance_tracker_test1/reports/
attendance_tracker_test1/Helpers/
attendance_tracker_test1/Helpers/config.json
attendance_tracker_test1/attendance_checker.py
```

There is no `assets.csv` because the roster had not been written yet. Interrupting later would include more.

## How I tested it

I tested the failure paths as well as the happy path, since most of my bugs showed up there.

| What | How | Result |
|---|---|---|
| Missing tools | Temporarily misspelled `zip` in the check | Error shown, script stopped |
| Folder structure | `ls -R attendance_tracker_{name}` | `attendance_checker.py` in root, `Helpers/` with `assets.csv` and `config.json`, empty `reports/` |
| Roster option A | Entered `3`, `0`, `11`, `abc`, empty, then `cat` the CSV | Bad input rejected, 3 students + header copied |
| Roster option B | Same inputs, then `cat` the CSV | Header correct, each row ends in `,0,0` |
| `total_sessions` | `grep total_sessions .../config.json` after A and after B | `5` after A, `1` after B |
| Overwrite | Deployed over an existing name, answered `y`, `n` and `maybe`; used a marker file | Only `y` replaced the folder |
| Permissions | `ls -l` on both files | `-rwxr-xr-x` script, `-rw-------` config |
| Thresholds | Enter on both, valid values, `abc`, `-5`, `101`, failure above and equal to warning | Valid values written, the rest rejected before `sed` |
| Run / archive | Marked students with one absent, then archived; removed `absent.log` and archived again | Both logs archived, then a missing log was reported without a crash |
| Signals | Ctrl+C and Ctrl+Z at the name prompt, the overwrite prompt and the roster prompt | Zip created and folder removed only when a project had actually been built |

## Known limitations

- Pressing Ctrl+C is cleaned up, but a plain input error mid-deploy (for example typing `abc` for the student count) exits with an error and does **not** zip or remove the half-built folder. Only the two signals trigger the cleanup.
- Pressing Ctrl+C during the final marking session is not trapped, by design.
- `sleep` calls are in the script for readability of the output, and they add a few seconds to a deploy.

## Demo video

Video walkthrough: https://drive.google.com/file/d/1kMJ6iUnBrAsgjJUazhqUYEGppWOdqQdC/view?usp=sharing

## Author

**SpaceRangerDave**, Introduction to Linux and IT Tools, Scripting Summative Lab.