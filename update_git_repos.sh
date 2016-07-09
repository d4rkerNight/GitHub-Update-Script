#!/bin/bash

# Update Github repository
# By Sergio Sieni
#
# Archlinux zsh
# Debian bash

U="\e[4m"		# underline
B="\e[44m"		# blue background
N="\e[0m"		# normal
G="\e[32m"		# green
Y="\e[93m"		# yellow
BB="\e[1m"		# bolt
LR="\e[91m"		# light red
GG="\e[100m"		# gray
LRB="\e[101m"		# light red background
input=""; selection=""
abort="Aborting"
update="Updating"
no_update="up-to-date"
up=0; no_up=0; err=0

function banner() {
	echo -e "\n\t${B}GitHub Update Script${N}"
	echo -e "\t  ${B}by Sergio  Sieni${N}\n"
}

function options() {
	echo -e "${BB}${U}Repository Options:${N}\n"
	echo -e "[1] - Update"
	echo -e "[2] - List"
	echo -e "[3] - Count\n"
	echo -e "[0] - Exit\n"
}

function show_res() {
	echo -e "\n${BB}Done!! ##########${N}"
	echo -e "${G}[I] Updated:\t${up}${N}"
	echo -e "${Y}[W] Up-to-Date:\t${no_up}${N}"
	echo -e "${LR}[E] Error:\t${err}${N}"
	echo -e "${BB}#################${N}"
	up=0; no_up=0; err=0
}

function press_enter() {
	echo -en "\n${GG}Press Enter to continue${N}\n"
	read
	if [ $1 = "clear" ]; then
		clear
	fi
}

function count() {
	cnt=0
	while IFS= read -r -d $'\0'; do
		cnt=$(($cnt+1))
	done < <(find ~ -name ".git" -type d -print0 2>/dev/null)
	echo -e "${G}[I] $cnt git found${N}"
}

function list() {
	cnt=0
	for i in $(find ~ -name ".git" -type d 2>/dev/null); do
		if ! (($cnt % 2)); then
			echo -e "${G}[I] ${i%?????}${N}"
		else
			echo -e "${G}[I] ${N}${i%?????}"
		fi
		cnt=$(($cnt+1))
	done
}

function find_repo() {
	start=1
	end=${#array[*]}
	select_=()
	for num in $selected; do
		if [[ $num -ge $start && $num -le $end ]]; then
			select_+=("$num")
		else
			echo -e "${LR}[E] $num is not valid!${N}"
			press_enter "nclean"
		fi
	done
}

function show_err() {
	show_error=""
	until [ "${show_error}" = "n" ]; do
		echo -en "${BB}\nShow Error/s [y/n]? ${N}"
		read show_error
		case ${show_error} in
			y|"")
				if [[ ${#arr_err[*]} -gt 1 ]]; then
					echo -e "\n${BB}${#arr_err[*]} Errors #################${N}"
				else
					echo -e "\n${BB}${#arr_err[*]} Error  #################${N}"
				fi
				for error in ${arr_err[*]}; do
					echo -e "${LR}$error${N}"
				done
				echo -e "${BB}##########################${N}\n"
				press_enter "clear"
				break
				;;
			n)
				press_enter "clear"
				;;
			*)
				echo -e "\n${LRB}Invalid Option${N}"
		esac
	done
}

function update2() {
	cnt=1
	arr_=("$@")
	arr_err=()
	for item in ${arr_[*]}; do
		echo -e "\n${G}[I] $cnt/${#arr_[*]} Updating: ${item%?????}${N}";
		cd "${item}"; cd ".."
		output=$(git pull origin master 2>&1)
		if echo "$output" | grep -q "$update" && ! echo "$output" | grep -q "$abort"; then
			echo -e "\n${G}[I] Updated${N}"
			up=$(($up+1))
		elif echo "$output" | grep -q "$no_update"; then
			echo -e "\n${Y}[W] Already up-to-date${N}"
			no_up=$(($no_up+1))
		else
			echo -e "\n${LR}[E] Error!${N}"
			echo -e "${N}$output${N}\n"
			err=$(($err+1))
			arr_err+=("${item%?????}")
			press_enter "nclean"
		fi
		cnt=$(($cnt+1))
	done
	show_res $up $no_up $err
}

function update() {
	cnt=0
	array=()
	while IFS= read -r -d $'\0'; do
		array+=("$REPLY")
	done < <(find ~ -name ".git" -type d -print0 2>/dev/null)
	for item in ${array[*]}; do
		if ! (($cnt % 2)); then
			echo -e "${G}[I] [$(($cnt+1))] ${item%?????}${N}"
		else
			echo -e "${G}[I] ${N}[$(($cnt+1))] ${item%?????}"
		fi
		cnt=$(($cnt+1))
	done
	echo -en "\n${BB}Update [1] all, [2] select, [3] exclude: ${N}"
	read input
	case ${input} in
		1)
			update2 ${array[*]}
			;;
		2)
			echo -en "\n${BB}Which Repo/s (separated by space): ${N}"
			read selected
			find_repo $selected ${array[*]}
			new_arr=()
			for sel in ${select_[*]}; do
				new_arr+=("${array[$((sel-1))]}")
			done
			update2 ${new_arr[*]}
			;;
		3)
			echo -en "\n${BB}Which Repo/s to exclude (separated by space): ${N}"
			read selected
			find_repo $selected ${array[*]}
			for del in ${select_[*]}; do
				unset array[$((del-1))]
			done
			update2 ${array[*]}
			;;
		*)
			echo -e "${LRB}Invalid Option${N}\n"
	esac
}

clear
until [ "${selection}" = "0" ]; do
	banner
	options
	echo -en "${BB}Select: ${N}"
	read selection
	echo ""
	case ${selection} in
		1)
			update
			if [[ ${#arr_err[*]} -gt 0 ]]; then
				show_err
			else
				press_enter "clear"
			fi
			;;
		2)
			list
			press_enter "clear"
			;;
		3)
			count
			press_enter "clear"
			;;
		0)
			echo -e "${BB}Quitting...${N}\n"
			;;
		*)
			echo -e "${LRB}Invalid Option${N}\n"
			press_enter "clear"
	esac
done
