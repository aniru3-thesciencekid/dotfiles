#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'


function section_end {
	if [ "$__last_color" == "$2" ]; then
		# Section colors are the same, use a foreground separator
		local end_char="${symbols[soft_separator]}"
		local fg=$1
	else
		# section colors are different, use a background separator
		local end_char="${symbols[hard_separator]}"
		local fg=$__last_color
	fi
	if [ -n "$__last_color" ]; then
		echo "${colors[$fg]}${colors[On_$2]}$end_char"
	fi
}

# -----------------------------------------------------------------------------
# returns a string with background and foreground colours set
# arg: $1 foreground color
# arg: $2 background color
# arg: $3 content
function section_content {
	echo "${colors[$1]}${colors[On_$2]}$3"
}

# -----------------------------------------------------------------------------
# append to prompt: current time
# arg: $1 foreground color
# arg: $2 background color
# optional arg: $3 - true/false to show seconds
function time_module {
	local bg_color=$1
	local fg_color=$2
	if [ "$3" = true ]; then
		local content="\t"
	else
		local content="\A"
	fi
	PS1+=$(section_end $fg_color $bg_color)
	PS1+=$(section_content $fg_color $bg_color " $content ")
	__last_color=$bg_color
}

#------------------------------------------------------------------------------
# append to prompt: user@host or user or root@host
# arg: $1 foreground color (red if root)
# arg: $2 background color
# optional arg: $3 - true/false to show the hostname
function user_module {
	local bg_color=$1
	local fg_color=$2
	# Show host if true or when user is remote/root
	if [[ "$3" = true || "${SSH_CLIENT}" || "${SSH_TTY}" || ${EUID} = 0 ]]; then
		local content="\u@\h"
	else
		local content="\u"
	fi
	PS1+=$(section_end $fg_color $bg_color)
	PS1+=$(section_content $fg_color $bg_color " $content ")
	__last_color=$bg_color
}

# -----------------------------------------------------------------------------
# append to prompt: [history #]
# arg: $1 foreground color
# arg: $2 background color
function history_module {
	local bg_color=$1
	local fg_color=$2
	PS1+=$(section_end $fg_color $bg_color)
	PS1+=$(section_content $fg_color $bg_color "[\!]")
	__last_color=$bg_color
}

# -----------------------------------------------------------------------------
# append to prompt: icon if ssh
# arg: $1 foreground color
# arg: $2 background color
function ssh_module {
    local bg_color=$1
    local fg_color=$2
    if [ "$SSH_TTY" = "" ]; then
        local content=""
    else
        local content="${symbols[ssh_connected]}"
        PS1+=$(section_end $fg_color $bg_color)
        PS1+=$(section_content $fg_color $bg_color " $content ")
        __last_color=$bg_color
    fi
}

# -----------------------------------------------------------------------------
# append to prompt: user@host
# arg: $1 foreground color
# arg: $2 background color
# optional arg: $3 - true/false to show the username
function host_module {
	local bg_color=$1
	local fg_color=$2
	if [ "$3" = true ]; then
		local content="\u@\h"
	else
		local content="\h"
	fi
	PS1+=$(section_end $fg_color $bg_color)
	PS1+=$(section_content $fg_color $bg_color " $content ")
	__last_color=$bg_color
}

# -----------------------------------------------------------------------------
# append to prompt: current directory
# arg: $1 foreground color
# arg; $2 background color
# optional arg: $3 - 0 — fullpath, 1 — current dir, [x] — trim to x number of
# directories
function path_module {
	local bg_color=$1
	local fg_color=$2
	local content="\w"
	if [ $3 -eq 1 ]; then
		local content="\W"
	elif [ $3 -gt 1 ]; then
		PROMPT_DIRTRIM=$3
	fi
	PS1+=$(section_end $fg_color $bg_color)
	PS1+=$(section_content $fg_color $bg_color " $content ")
	__last_color=$bg_color
}

# -----------------------------------------------------------------------------
# append to prompt: the number of background jobs running
# arg: $1 foreground color
# arg; $2 background color
function jobs_module {
	local bg_color=$1
	local fg_color=$2
	local number_jobs=$(jobs -p | wc -l)
	if [ ! "$number_jobs" -eq 0 ]; then
		PS1+=$(section_end $fg_color $bg_color)
		PS1+=$(section_content $fg_color $bg_color " ${symbols[enter]} $number_jobs ")
		__last_color=$bg_color
	fi
}

# -----------------------------------------------------------------------------
# append to prompt: indicator is the current directory is ready-only
# arg: $1 foreground color
# arg; $2 background color
function read_only_module {
	local bg_color=$1
	local fg_color=$2
	if [ ! -w "$PWD" ]; then
		PS1+=$(section_end $fg_color $bg_color)
		PS1+=$(section_content $fg_color $bg_color " ${symbols[lock]} ")
		__last_color=$bg_color
	fi
}

# -----------------------------------------------------------------------------
# append to prompt: git branch with indictors for;
#     number of; modified files, staged files and conflicts
# arg: $1 foreground color
# arg; $2 background color
# optional arg: $3 - foreground color used if the working directory is dirty
function git_module {
	local git_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
	if [ -n "$git_branch" ]; then
		local bg_color=$1
		local fg_color=$2
		local content="${symbols[git]} $git_branch$git"

		if [ -n "$3" -a -n "$(git status --porcelain)" ]; then
			fg_color=$3
		fi

		local number_modified=$(git diff --name-only --diff-filter=M 2> /dev/null | wc -l )
		if [ ! "$number_modified" -eq "0" ]; then
			content+=" ${symbols[soft_separator]} ${symbols[plus]} $number_modified"
		fi

		local number_staged=$(git diff --staged --name-only --diff-filter=AM 2> /dev/null | wc -l)
		if [ ! "$number_staged" -eq "0" ]; then
			content+=" ${symbols[soft_separator]} ${symbols[tick]} $number_staged"
		fi

		local number_conflicts=$(git diff --name-only --diff-filter=U 2> /dev/null | wc -l)
		if [ ! "$number_conflicts" -eq "0" ]; then
			content+=" ${symbols[soft_separator]} ${symbols[cross]} $number_conflicts"
		fi

		local number_untracked=$(git ls-files --other --exclude-standard | wc -l)
		if [ ! "$number_untracked" -eq "0" ]; then
			content+=" ${symbols[soft_separator]} ${symbols[untracked]} $number_untracked"
		fi

		PS1+=$(section_end $fg_color $bg_color)
		PS1+=$(section_content $fg_color $bg_color " $content ")
		__last_color=$bg_color
	fi
}

# -----------------------------------------------------------------------------
# append to prompt: number of git stash
# arg: $1 foreground color
# arg; $2 background color
function git_stash_module {
	local number_stash=$(git stash list 2>/dev/null | wc -l)
	if [ ! "$number_stash" -eq 0 ]; then
		local bg_color=$1
		local fg_color=$2
		local content="${symbols[stash]} $number_stash"
		PS1+=$(section_end $fg_color $bg_color)
		PS1+=$(section_content $fg_color $bg_color " $content ")
		__last_color=$bg_color
	fi
}

# -----------------------------------------------------------------------------
# append to prompt: repository status against upstream
# arg: $1 foreground color
# arg; $2 background color
function git_ahead_behind_module {
    local number_behind_ahead=$(git rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)
    local number_ahead="${number_behind_ahead#*	}"
    local number_behind="${number_behind_ahead%	*}"
    if [ ! "0$number_ahead" -eq 0 -o ! "0$number_behind" -eq 0 ]; then
		local bg_color=$1
		local fg_color=$2
        local content=""
        if [ ! "$number_ahead" -eq 0 ]; then
            content+=" ${symbols[ahead]} $number_ahead"
        fi
        if [ ! "$number_behind" -eq 0 ]; then
            content+=" ${symbols[behind]} $number_behind"
        fi
		PS1+=$(section_end $fg_color $bg_color)
		PS1+=$(section_content $fg_color $bg_color "$content ")
		__last_color=$bg_color
	fi
}

# -----------------------------------------------------------------------------
# append to prompt: python virtual environment name
# arg: $1 foreground color
# arg; $2 background color
function virtual_env_module {
	if [ -n "$VIRTUAL_ENV" ]; then
		local venv="${VIRTUAL_ENV##*/}"
		local bg_color=$1
		local fg_color=$2
		local content=" ${symbols[python]} $venv"
		PS1+=$(section_end $fg_color $bg_color)
		PS1+=$(section_content $fg_color $bg_color "$content ")
		__last_color=$bg_color
	fi
}

# -----------------------------------------------------------------------------
# append to prompt: indicator for battery level
# arg: $1 foreground color
# arg; $2 background color
function battery_module {
	local bg_color=$1
	local fg_color=$2
	local batt_dir
	local content
	local batt_dir="/sys/class/power_supply/BAT"
	if [ -d $batt_dir"0" ]; then
		batt_dir=$batt_dir"0"
	elif [ -d $batt_dir"1" ]; then
		batt_dir=$batt_dir1""
	else
		return 1
	fi
	local cap=$(<"$batt_dir/capacity")
	local status=$(<"$batt_dir/status")

	if [ "$status" == "Discharging" ]; then
		content="${symbols[battery_discharging]} "
	else
		content="${symbols[battery_charging]}"
	fi
	content="$content$cap%"

	PS1+=$(section_end $fg_color $bg_color)
	PS1+=$(section_content $fg_color $bg_color " $content ")
	__last_color=$bg_color
}


# -----------------------------------------------------------------------------
# append to prompt: append a '$' prompt with optional return code for previous command
# arg: $1 foreground color
# arg; $2 background color
function prompt_module {
	# if we're root then use '#' as the prompt-string
	if [ ${EUID} -eq 0 ]; then
		local prompt_char="#"
	else
		local prompt_char="$"
	fi
	local bg_color=$1
	local fg_color=$2
	local content=" $prompt_char "
	PS1+=$(section_end $fg_color $bg_color)
	PS1+=$(section_content $fg_color $bg_color "$content")
	__last_color=$bg_color
}

# -----------------------------------------------------------------------------
# append to prompt: append a '$' prompt with optional return code for previous command
# arg: $1 foreground color
# arg; $2 background color
function return_code_module {
	if [ ! "$__return_code" -eq 0 ]; then
		local bg_color=$1
		local fg_color=$2
		local content=" ${symbols[flag]} $__return_code "
		PS1+=$(section_end $fg_color $bg_color)
		PS1+=$(section_content $fg_color $bg_color "$content")
		__last_color=$bg_color
	fi
}

# -----------------------------------------------------------------------------
# append to prompt: end the current promptline and start a newline
function newline_module {
	if [ -n "$__last_color" ]; then
		PS1+=$(section_end $__last_color 'Default')
	fi
	PS1+="\n"
	unset __last_color
}

# -----------------------------------------------------------------------------
function pureline_ps1 {
	__return_code=$?      # save the return code
	PS1=""

	# load the modules
	for module in "${!pureline_modules[@]}"; do
		${pureline_modules[$module]}
	done

	# final end point
	if [ -n "$__last_color" ]; then
		PS1+=$(section_end $__last_color 'Default')
	else
		PS1="$"
	fi

	# cleanup
	PS1+="${colors[Color_Off]} "
	unset __last_color
	unset __return_code
}

# -----------------------------------------------------------------------------

# define the basic color set
declare -A colors=(
[Color_Off]='\[\e[0m\]'       # Text Reset
# Foreground
[Default]='\[\e[0;39m\]'      # Default
[Black]='\[\e[0;30m\]'        # Black
[Red]='\[\e[0;31m\]'          # Red
[Green]='\[\e[0;32m\]'        # Green
[Yellow]='\[\e[0;33m\]'       # Yellow
[Blue]='\[\e[0;34m\]'         # Blue
[Purple]='\[\e[0;35m\]'       # Purple
[Cyan]='\[\e[0;36m\]'         # Cyan
[White]='\[\e[0;37m\]'        # White
# Background
[On_Default]='\[\e[49m\]'     # Default
[On_Black]='\[\e[40m\]'       # Black
[On_Red]='\[\e[41m\]'         # Red
[On_Green]='\[\e[42m\]'       # Green
[On_Yellow]='\[\e[43m\]'      # Yellow
[On_Blue]='\[\e[44m\]'        # Blue
[On_Purple]='\[\e[45m\]'      # Purple
[On_Cyan]='\[\e[46m\]'        # Cyan
[On_White]='\[\e[47m\]'       # White
)

# define symbols
declare -A symbols=(
[hard_separator]=""
[soft_separator]=""
[git]=""
[lock]=""
[flag]=""
[plus]="✚"
[tick]="✔"
[cross]="✘"
[enter]=""
[python]="λ"
[untracked]="U"
[ahead]=""
[behind]=""
)

# check if an argument has been given for a config file
if [ -f "$1" ]; then
	source $1
else
	# define default modules to load
	declare -a pureline_modules=(
	'jobs_module               Blue        Black'
	'user_module               Yellow      Black       true'
	'path_module               Blue        Black       0'
	'read_only_module          Red         White'
	'git_module                Purple      Black       Red'
	'git_ahead_behind_module   Purple      Black'
	)
fi

# dynamically set the  PS1

[[ ! ${PROMPT_COMMAND} =~ 'pureline_ps1;' ]] &&  PROMPT_COMMAND="pureline_ps1; $PROMPT_COMMAND" || true
