#!/bin/bash

## All valid (qBittorrent, libtorrent) combinations and source repositories (tried in order)
declare -A combo_sources=(
	# qBittorrent 4.1.9
	["qBittorrent-4.1.9:libtorrent-1_1_14"]="guowanghushifu jerry048"
	# qBittorrent 4.1.9.1
	["qBittorrent-4.1.9.1:libtorrent-1_1_14"]="guowanghushifu jerry048"
	# qBittorrent 4.2.5
	["qBittorrent-4.2.5:libtorrent-v1.2.19"]="guowanghushifu"
	["qBittorrent-4.2.5:libtorrent-v1.2.20"]="jerry048"
	# qBittorrent 4.3.8
	["qBittorrent-4.3.8:libtorrent-v1.2.14"]="guowanghushifu"
	# qBittorrent 4.3.9
	["qBittorrent-4.3.9:libtorrent-v1.2.19"]="guowanghushifu"
	["qBittorrent-4.3.9:libtorrent-v1.2.20"]="jerry048"
	# qBittorrent 4.4.5
	["qBittorrent-4.4.5:libtorrent-v1.2.19"]="guowanghushifu"
	["qBittorrent-4.4.5:libtorrent-v1.2.20"]="jerry048"
	["qBittorrent-4.4.5:libtorrent-v2.0.10"]="guowanghushifu"
	["qBittorrent-4.4.5:libtorrent-v2.0.11"]="jerry048"
	# qBittorrent 4.5.5
	["qBittorrent-4.5.5:libtorrent-v1.2.19"]="guowanghushifu"
	["qBittorrent-4.5.5:libtorrent-v1.2.20"]="jerry048"
	["qBittorrent-4.5.5:libtorrent-v2.0.10"]="guowanghushifu"
	["qBittorrent-4.5.5:libtorrent-v2.0.11"]="jerry048"
	# qBittorrent 4.6.3
	["qBittorrent-4.6.3:libtorrent-v1.2.19"]="guowanghushifu"
	["qBittorrent-4.6.3:libtorrent-v2.0.10"]="guowanghushifu"
	# qBittorrent 4.6.5
	["qBittorrent-4.6.5:libtorrent-v1.2.19"]="guowanghushifu"
	# qBittorrent 4.6.5.1
	["qBittorrent-4.6.5.1:libtorrent-v1.2.19"]="guowanghushifu"
	# qBittorrent 4.6.5.2
	["qBittorrent-4.6.5.2:libtorrent-v1.2.19"]="guowanghushifu"
	# qBittorrent 4.6.7
	["qBittorrent-4.6.7:libtorrent-v1.2.19"]="guowanghushifu"
	["qBittorrent-4.6.7:libtorrent-v1.2.20"]="jerry048"
	["qBittorrent-4.6.7:libtorrent-v2.0.11"]="jerry048"
	# qBittorrent 5.0.3
	["qBittorrent-5.0.3:libtorrent-v1.2.20"]="guowanghushifu jerry048"
	["qBittorrent-5.0.3:libtorrent-v2.0.11"]="guowanghushifu jerry048"
	# qBittorrent 5.0.4
	["qBittorrent-5.0.4:libtorrent-v1.2.20"]="guowanghushifu"
	["qBittorrent-5.0.4:libtorrent-v1.2.20 - x64_v3"]="guowanghushifu"
	["qBittorrent-5.0.4:libtorrent-v2.0.11"]="guowanghushifu"
	# qBittorrent 5.1.0beta1
	["qBittorrent-5.1.0beta1:libtorrent-v1.2.20"]="jerry048"
	["qBittorrent-5.1.0beta1:libtorrent-v2.0.11"]="jerry048"
)

## Generate sorted unique qBittorrent version list from combo_sources
declare -a qb_name_list
_build_qb_list() {
	local -A seen
	for key in "${!combo_sources[@]}"; do
		seen["${key%%:*}"]=1
	done
	mapfile -t qb_name_list < <(printf '%s\n' "${!seen[@]}" | sort -V)
}
_build_qb_list

## Get available libtorrent versions for a given qBittorrent version (filtered by arch)
_get_lib_for_qb() {
	local target_qb="$1"
	local cur_arch
	cur_arch="$(uname -m)"
	local libs=()
	for key in "${!combo_sources[@]}"; do
		local qb="${key%%:*}"
		local lib="${key##*:}"
		if [[ "$qb" == "$target_qb" ]]; then
			if [[ "$lib" == *"x64_v3"* ]] && [[ "$cur_arch" != "x86_64" ]]; then
				continue
			fi
			libs+=("$lib")
		fi
	done
	printf '%s\n' "${libs[@]}" | sort -V
}

## Download helper with multi-repo fallback
_download_with_fallback() {
	local url_path="$1"
	local output="$2"
	local repos="$3"
	for repo in $repos; do
		local url="https://raw.githubusercontent.com/${repo}/Seedbox-Components/main/Torrent%20Clients/qBittorrent/${url_path}"
		echo "Trying to download from ${repo}..."
		if wget "$url" -O "$output"; then
			chmod +x "$output"
			echo "Downloaded successfully from ${repo}"
			return 0
		fi
		echo "Not available from ${repo}, trying next source..."
	done
	return 1
}

## Display all supported qBittorrent + libtorrent combinations
show_supported_versions() {
	local cur_arch
	cur_arch="$(uname -m)"
	echo ""
	echo "  Supported qBittorrent + libtorrent combinations:"
	echo "  ================================================="
	for qb in "${qb_name_list[@]}"; do
		local libs
		mapfile -t libs < <(_get_lib_for_qb "$qb")
		local lib_str=""
		for lib in "${libs[@]}"; do
			local combo_key="${qb}:${lib}"
			local repos="${combo_sources[$combo_key]}"
			local src
			src=$(echo "$repos" | awk '{print $1}')
			if [[ -n "$lib_str" ]]; then
				lib_str+=", "
			fi
			lib_str+="${lib} [${src}]"
		done
		printf "  %-30s => %s\n" "$qb" "$lib_str"
	done
	echo ""
}

qb_ver_choose(){
	need_input "Please choose your qBittorrent Version:"
	select opt in "${qb_name_list[@]}"
	do
		case $opt in
		qBittorrent*)
			qb_ver=${opt}; break
			;;
		*) warn "Please choose a valid version" ;;
		esac
	done
}

lib_ver_choose(){
	if [[ -z "$qb_ver" ]]; then
		qb_ver_choose
	fi
	local available_libs
	mapfile -t available_libs < <(_get_lib_for_qb "$qb_ver")
	if [[ ${#available_libs[@]} -eq 0 ]]; then
		warn "No libtorrent versions available for $qb_ver"
		return 1
	fi
	need_input "Please choose your libtorrent version for $qb_ver:"
	select opt in "${available_libs[@]}"
	do
		case $opt in
		libtorrent*)
			lib_ver=${opt}; break
			;;
		*) warn "Please choose a valid version" ;;
		esac
	done
}

lib_ver_check(){
	if [[ -z "$lib_ver" ]]; then
		lib_ver_choose
		return
	fi
	local combo_key="${qb_ver}:${lib_ver}"
	if [[ -z "${combo_sources[$combo_key]+_}" ]]; then
		tput sgr0; clear
		warn "$qb_ver is not compatible with $lib_ver"
		warn "Available libtorrent versions for $qb_ver:"
		_get_lib_for_qb "$qb_ver"
		warn "Please choose a compatible version"
		lib_ver_choose
	fi
}

qb_install_check(){
	if [[ ! " ${qb_name_list[*]} " =~ " ${qb_ver} " ]]; then
		warn "qBittorrent $qb_ver is not supported"
		qb_ver_choose
	fi
	lib_ver_check
}


install_qBittorrent_(){
	username=$1
	password=$2
	qb_ver=$3
	lib_ver=$4
	qb_cache=$5
	qb_port=$6
	qb_incoming_port=$7
	client_max_mem=$8

	## Check if qBittorrent is running
	if pgrep -i -f qbittorrent; then
		warn "qBittorrent is running. Stopping it now..."
		pkill -s $(pgrep -i -f qbittorrent)
	fi
	# Check if it is still running
	if pgrep -i -f qbittorrent; then
		warn "Failed to stop qBittorrent. Please stop it manually"
		return 1
	fi

	## Check if qbittorrent-nox is installed
	if test -e /usr/bin/qbittorrent-nox; then
		warn "qBittorrent is already installed. Replacing it now..."
		rm /usr/bin/qbittorrent-nox
	fi

	## Determine the CPU architecture
	local arch
	if [[ $(uname -m) == "x86_64" ]]; then
		arch="x86_64"
	elif [[ $(uname -m) == "aarch64" ]]; then
		arch="ARM64"
	else
		warn "Unsupported CPU architecture"
		return 1
	fi

	## Download qBittorrent-nox with repo fallback
	local combo_key="${qb_ver}:${lib_ver}"
	local repos="${combo_sources[$combo_key]}"
	if [[ -z "$repos" ]]; then
		warn "No source repository found for $qb_ver + $lib_ver"
		return 1
	fi
	local safe_lib_ver="${lib_ver// /%20}"
	local safe_qb_ver="${qb_ver// /%20}"
	local url_path="${arch}/${safe_qb_ver}%20-%20${safe_lib_ver}/qbittorrent-nox"

	if ! _download_with_fallback "$url_path" "$HOME/qbittorrent-nox" "$repos"; then
		warn "Failed to download qBittorrent-nox executable from all repositories"
		return 1
	fi

	# Install qbittorrent-nox
	mv $HOME/qbittorrent-nox /usr/bin/qbittorrent-nox
	mkdir -p /home/$username/qbittorrent/Downloads && chown -R $username:$username /home/$username/qbittorrent/
    mkdir -p /home/$username/.config/qBittorrent && chown $username:$username /home/$username/.config/qBittorrent

	# Create systemd services
	if test -e /etc/systemd/system/qbittorrent-nox@.service; then
		warn "qBittorrent systemd services already exist. Removing it now..."
		rm /etc/systemd/system/qbittorrent-nox@.service
	fi
	touch /etc/systemd/system/qbittorrent-nox@.service
	cat << EOF >/etc/systemd/system/qbittorrent-nox@.service
[Unit]
Description=qBittorrent
After=network.target

[Service]
Type=exec
User=$username
LimitNOFILE=infinity
ExecStart=/usr/bin/qbittorrent-nox
Restart=on-failure
TimeoutStopSec=10
RestartSec=10
EOF

if [[ -n "$client_max_mem" && "$client_max_mem" != "0" ]]; then
    echo "MemoryMax=$client_max_mem" >> /etc/systemd/system/qbittorrent-nox@.service
fi

cat << EOF >>/etc/systemd/system/qbittorrent-nox@.service
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable qbittorrent-nox@$username
    systemctl start qbittorrent-nox@$username

	## Configure qBittorrent
	# Check for Virtual Environment since some of the tunning might not work on virtual machine
	systemd-detect-virt > /dev/null
	if [ $? -eq 0 ]; then
		warn "Virtualization is detected, skipping some of the tunning"
		aio=8
		low_buffer=3072
		buffer=15360
		buffer_factor=200
	else
		#Determine if it is a SSD or a HDD
		disk_name=$(printf $(lsblk | grep -m1 'disk' | awk '{print $1}'))
		disktype=$(cat /sys/block/$disk_name/queue/rotational)
		if [ "${disktype}" == 0 ]; then
			aio=12
			low_buffer=5120
			buffer=20480
			buffer_factor=250
		else
			aio=4
			low_buffer=3072
			buffer=10240
			buffer_factor=150
		fi
	fi

	# Editing qBittorrent settings
    systemctl stop qbittorrent-nox@$username

    if [[ "${qb_ver}" =~ "4.1." ]]; then
        md5password=$(echo -n $password | md5sum | awk '{print $1}')
        cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
[BitTorrent]
Session\AsyncIOThreadsCount=$aio
Session\SendBufferLowWatermark=$low_buffer
Session\SendBufferWatermark=$buffer
Session\SendBufferWatermarkFactor=$buffer_factor

[LegalNotice]
Accepted=true

[Network]
Cookies=@Invalid()

[Preferences]
Connection\PortRangeMin=$qb_incoming_port
Downloads\DiskWriteCacheSize=$qb_cache
Downloads\SavePath=/home/$username/qbittorrent/Downloads/
Queueing\QueueingEnabled=false
WebUI\Password_ha1=@ByteArray($md5password)
WebUI\Port=$qb_port
WebUI\Username=$username
EOF
    elif [[ "${qb_ver}" =~ "4.2." ]] || [[ "${qb_ver}" =~ "4.3." ]]; then
        if ! _download_with_fallback "${arch}/qb_password_gen" "$HOME/qb_password_gen" "guowanghushifu jerry048"; then
			warn "Failed to download qb_password_gen"
			rm -r /home/$username/qbittorrent/Downloads
			rm -r /home/$username/.config/qBittorrent
			rm /usr/bin/qbittorrent-nox
			rm /etc/systemd/system/qbittorrent-nox@.service
			return 1
		fi
		PBKDF2password=$($HOME/qb_password_gen $password)
        cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
[BitTorrent]
Session\AsyncIOThreadsCount=$aio
Session\SendBufferLowWatermark=$low_buffer
Session\SendBufferWatermark=$buffer
Session\SendBufferWatermarkFactor=$buffer_factor

[LegalNotice]
Accepted=true

[Network]
Cookies=@Invalid()

[Preferences]
General\Locale=zh
Connection\PortRangeMin=$qb_incoming_port
Downloads\DiskWriteCacheSize=$qb_cache
Downloads\SavePath=/home/$username/qbittorrent/Downloads/
Queueing\QueueingEnabled=false
WebUI\Password_PBKDF2="@ByteArray($PBKDF2password)"
WebUI\Port=$qb_port
WebUI\Username=$username
EOF
	rm -f $HOME/qb_password_gen
    elif [[ "${qb_ver}" =~ "4.4." ]] || [[ "${qb_ver}" =~ "4.5." ]] || [[ "${qb_ver}" =~ "4.6." ]]; then
        if ! _download_with_fallback "${arch}/qb_password_gen" "$HOME/qb_password_gen" "guowanghushifu jerry048"; then
			warn "Failed to download qb_password_gen"
			rm -r /home/$username/qbittorrent/Downloads
			rm -r /home/$username/.config/qBittorrent
			rm /usr/bin/qbittorrent-nox
			rm /etc/systemd/system/qbittorrent-nox@.service
			return 1
		fi
		PBKDF2password=$($HOME/qb_password_gen $password)
        cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
[Application]
MemoryWorkingSetLimit=$qb_cache

[BitTorrent]
Session\AsyncIOThreadsCount=$aio
Session\DefaultSavePath=/home/$username/qbittorrent/Downloads/
Session\DiskCacheSize=$qb_cache
Session\Port=$qb_incoming_port
Session\QueueingSystemEnabled=false
Session\SendBufferLowWatermark=$low_buffer
Session\SendBufferWatermark=$buffer
Session\SendBufferWatermarkFactor=$buffer_factor

[LegalNotice]
Accepted=true

[Network]
Cookies=@Invalid()

[Preferences]
WebUI\Password_PBKDF2="@ByteArray($PBKDF2password)"
WebUI\Port=$qb_port
WebUI\Username=$username
EOF
    rm -f $HOME/qb_password_gen
    elif [[ "${qb_ver}" =~ "5.0." ]] || [[ "${qb_ver}" =~ "5.1." ]]; then
        if ! _download_with_fallback "${arch}/qb_password_gen" "$HOME/qb_password_gen" "guowanghushifu jerry048"; then
			warn "Failed to download qb_password_gen"
			rm -r /home/$username/qbittorrent/Downloads
			rm -r /home/$username/.config/qBittorrent
			rm /usr/bin/qbittorrent-nox
			rm /etc/systemd/system/qbittorrent-nox@.service
			return 1
		fi
		PBKDF2password=$($HOME/qb_password_gen $password)
        cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
[Application]
MemoryWorkingSetLimit=$qb_cache

[BitTorrent]
Session\AsyncIOThreadsCount=$aio
Session\DefaultSavePath=/home/$username/qbittorrent/Downloads/
Session\DiskCacheSize=$qb_cache
Session\Port=$qb_incoming_port
Session\QueueingSystemEnabled=false
Session\SendBufferLowWatermark=$low_buffer
Session\SendBufferWatermark=$buffer
Session\SendBufferWatermarkFactor=$buffer_factor

[LegalNotice]
Accepted=true

[Network]
Cookies=@Invalid()

[Preferences]
General\Locale=zh_CN
WebUI\Password_PBKDF2="@ByteArray($PBKDF2password)"
WebUI\Port=$qb_port
WebUI\Username=$username
EOF
    rm -f $HOME/qb_password_gen
    fi
    systemctl start qbittorrent-nox@$username
}

return 0
