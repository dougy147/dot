#!/bin/sh

# forked from : Luke's Auto Rice Boostrapping Script (LARBS)
# License: GNU GPLv3

# Installer l'environnement graphique automatiquement

# Credits to Luke Smith

### OPTIONS AND VARIABLES ###

while getopts ":a:r:b:p:h" o; do case "${o}" in
	h) printf "Arguments optionnels pour utilisations particulières:\\n  -r: Répertoire des dotfiles (fichier local ou url)\\n  -p: Fichier CSV des programmes (fichier local ou url)\\n  -a: Installateur AUR (syntaxe pacman obligatoire)\\n  -h: Afficher ce message\\n" && exit 1 ;;
	r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit 1 ;;
	b) repobranch=${OPTARG} ;;
	p) progsfile=${OPTARG} ;;
	a) aurhelper=${OPTARG} ;;
	*) printf "Option invalide: -%s\\n" "$OPTARG" && exit 1 ;;
esac done

[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/dougy147/dot.git"
[ -z "$progsfile" ] && progsfile="https://raw.githubusercontent.com/dougy147/dot/main/programmes.csv"
[ -z "$aurhelper" ] && aurhelper="yay"
[ -z "$repobranch" ] && repobranch="main"

### FUNCTIONS ###

installpkg(){ pacman --noconfirm --needed -S "$1" >/dev/null 2>&1 ;}

error() { printf "%s\n" "$1" >&2; exit 1; }

welcomemsg() { \
	dialog --title "Bienvenue!" --msgbox "Auto-installation (/!\ test!!)\\n\\nCe script est une bifurcation de LARBs créé par Luke Smith (http://github.com/LukeSmithxyz)\\n\\nIl va installer l'environnement de bureau Linux.\\n\\n-dougy147" 10 60

	dialog --colors --title "Important !" --yes-label "Prêt!" --no-label "Retour..." --yesno "Assurez-vous que les paquets et keyrings de votre ordinateur sont à jour.\\n\\nSi ce n'est pas le cas, l'installation de certains programmes risque d'échouer." 8 70
	}

getuserandpass() { \
	# Prompts user for new username an password.
	name=$(dialog --inputbox "Entrez un nom d'utilisateur." 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
	while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do
		name=$(dialog --no-cancel --inputbox "Nom d'utilisateur invalide. Le nom d'utilisateur doit : commencer par une lettre, ne contenir que des lettres minuscules, - ou _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	pass1=$(dialog --no-cancel --passwordbox "Entrez un mot de passe pour cet utilisateur." 10 60 3>&1 1>&2 2>&3 3>&1)
	pass2=$(dialog --no-cancel --passwordbox "Confirmez le mot de passe." 10 60 3>&1 1>&2 2>&3 3>&1)
	while ! [ "$pass1" = "$pass2" ]; do
		unset pass2
		pass1=$(dialog --no-cancel --passwordbox "Les mots de passe ne correspondent pas.\\n\\nEntrez un mot de passe à nouveau." 10 60 3>&1 1>&2 2>&3 3>&1)
		pass2=$(dialog --no-cancel --passwordbox "Confirmez le mot de passe." 10 60 3>&1 1>&2 2>&3 3>&1)
	done ;}

usercheck() { \
	! { id -u "$name" >/dev/null 2>&1; } ||
	dialog --colors --title "ATTENTION!" --yes-label "CONTINUER" --no-label "Retour..." --yesno "L'utilisateur \`$name\` existe déjà. 'NOM_SCRIPT' peut tout de même être installer, TOUTEFOIS il \\Zbremplacera\\Zn les fichiers de configurations qui entreraient en conflit avec lui.\\n\\n'NOM_SCRIPT' \\Zbne va pas\\Zn remplacer vos fichiers personnels (documents, vidéos, etc.). Cliquez sur <CONTINUER> si vous acceptez.\\n\\nNotez que le mot de passe pour l'utilisateur $name' sera désormais celui que vous aurez entrer lors de l'installation de 'NOM_SCRIPT'." 14 70
	}

preinstallmsg() { \
	dialog --title "Démarrage de l'installation" --yes-label "Installer" --no-label "Annuler" --yesno "Le reste de l'installation est complètement automatisé.\\n\\nCliquez sur <Installer> avant de vous préparer un café :)" 13 60 || { clear; exit 1; }
	}

adduserandpass() { \
	# Adds user `$name` with password $pass1.
	dialog --infobox "Ajout de l'utilisateur \"$name\"..." 4 50
	useradd -m -g wheel -s /bin/zsh "$name" >/dev/null 2>&1 ||
	usermod -a -G wheel "$name" && mkdir -p /home/"$name" && chown "$name":wheel /home/"$name"
	repodir="/home/$name/.local/src"; mkdir -p "$repodir"; chown -R "$name":wheel "$(dirname "$repodir")"
	echo "$name:$pass1" | chpasswd
	unset pass1 pass2 ;}

refreshkeys() { \
	case "$(readlink -f /sbin/init)" in
		*systemd* )
			dialog --infobox "Rafraîchissement des clés Arch..." 4 40
			pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
			;;
		*)
			dialog --infobox "Activation des repos Arch..." 4 40
			pacman --noconfirm --needed -S artix-keyring artix-archlinux-support >/dev/null 2>&1
			for repo in extra community; do
				grep -q "^\[$repo\]" /etc/pacman.conf ||
					echo "[$repo]
Include = /etc/pacman.d/mirrorlist-arch" >> /etc/pacman.conf
			done
			pacman-key --populate archlinux
			;;
	esac ;
	}

newperms() { # Set special sudoers settings for install (or after).
	sed -i "/#NOM_SCRIPT/d" /etc/sudoers
	echo "$* #NOM_SCRIPT" >> /etc/sudoers ;}

manualinstall() { # Installs $1 manually. Used only for AUR helper here.
	# Should be run after repodir is created and var is set.
	dialog --infobox "Installing \"$1\", an AUR helper..." 4 50
	sudo -u "$name" mkdir -p "$repodir/$1"
	sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$repodir/$1" >/dev/null 2>&1 ||
		{ cd "$repodir/$1" || return 1 ; sudo -u "$name" git pull --force origin master;}
	cd "$repodir/$1"
	sudo -u "$name" -D "$repodir/$1" makepkg --noconfirm -si >/dev/null 2>&1 || return 1
}


maininstall() { # Installs all needed programs from main repo.
	dialog --title "Installation" --infobox "Installation de \`$1\` ($n sur $total). $1 $2" 5 70
	installpkg "$1"
	}

gitmakeinstall() {
	progname="$(basename "$1" .git)"
	dir="$repodir/$progname"
	dialog --title "Installation" --infobox "Installation de \`$progname\` ($n / $total) via \`git\` et \`make\`. $(basename "$1") $2" 5 70
	sudo -u "$name" git clone --depth 1 "$1" "$dir" >/dev/null 2>&1 || { cd "$dir" || return 1 ; sudo -u "$name" git pull --force origin main;}
	cd "$dir" || exit 1
	make >/dev/null 2>&1
	make install >/dev/null 2>&1
	cd /tmp || return 1 ;}

aurinstall() { \
	dialog --title "Installation" --infobox "Installation de \`$1\` ($n sur $total) depuis l'AUR. $1 $2" 5 70
	echo "$aurinstalled" | grep -q "^$1$" && return 1
	sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
	}

pipinstall() { \
	dialog --title "Installation" --infobox "Installation du package Python \`$1\` ($n sur $total). $1 $2" 5 70
	[ -x "$(command -v "pip")" ] || installpkg python-pip >/dev/null 2>&1
	yes | pip install "$1"
	}

installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/programmes.csv) || curl -Ls "$progsfile" | sed '/^#/d' > /tmp/programmes.csv
	total=$(wc -l < /tmp/programmes.csv)
	aurinstalled=$(pacman -Qqm)
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep -q "^\".*\"$" && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"A") aurinstall "$program" "$comment" ;;
			"G") gitmakeinstall "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
			*) maininstall "$program" "$comment" ;;
		esac
	done < /tmp/programmes.csv ;}

putgitrepo() { # Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts
	dialog --infobox "Téléchargement et installation des fichiers de configurations (dotfiles)..." 4 60
	[ -z "$3" ] && branch="main" || branch="$repobranch"
	dir=$(mktemp -d)
	[ ! -d "$2" ] && mkdir -p "$2"
	chown "$name":wheel "$dir" "$2"
	#sudo -u "$name" git clone --recursive -b "$branch" --depth 1 --recurse-submodules "$1" "$dir" >/dev/null 2>&1
	sudo -u "$name" git clone --recursive -b "$branch" --depth 1 "$1" "$dir" >/dev/null 2>&1
	sudo -u "$name" cp -rfT "$dir" "$2"
	}

installsuckless() { # Install dwm, dwmblocks, dmenu & st
	dialog --infobox "Install de dwm et dwmblocks..." 4 60
	cd "/home/$name/.local/src/dwm"
	#sudo -u "$user" make clean install
	sudo make clean install
	cd "/home/$name/.local/src/dwmblocks"
	sudo make clean install
	dialog --infobox "Install de dmenu..." 4 60
	cd "/home/$name/.local/src/dmenu"
	sudo make clean install
	dialog --infobox "Install de st..." 4 60
	cd "/home/$name/.local/src/st"
	sudo make clean install
	}

systembeepoff() { dialog --infobox "Suppression des beeps..." 10 50
	rmmod pcspkr
	echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;}

finalize(){ \
	dialog --infobox "Préparation du message de bienvenue..." 4 50
	dialog --title "Terminé!" --msgbox "Félicitations, tout est en place !\\n\\nPour profiter de votre nouvel environnement, déconnectez-vous de la session actuelle puis logguez-vous avec l'utilisateur créé. Si l'environnement graphique ne se lance pas, utilisez la commande \"startx\".\\n\\n dougy147" 12 80
	}

### THE ACTUAL SCRIPT ###

### This is how everything happens in an intuitive format and order.

# Check if user is root on Arch distro. Install dialog.
pacman --noconfirm --needed -Sy dialog || error "Assurez-vous de lancer ce script en tant qu'administrateur (root), d'avoir installé une distribution basée sur Arch, et d'avoir une connexion internet."

# Welcome user and pick dotfiles.
welcomemsg || error "L'utilisateur a quitté le script."

# Get and verify username and password.
getuserandpass || error "L'utilisateur a quitté le script."

# Give warning if user already exists.
usercheck || error "L'utilisateur a quitté le script."

# Last chance for user to back out before install.
preinstallmsg || error "L'utilisateur a quitté le script."

### The rest of the script requires no user input.

# Refresh Arch keyrings.
refreshkeys || error "Erreur de rafraîchissement des keyrings. Essayez de le faire manuellement."

for x in curl base-devel git ntp zsh; do
	dialog --title "Installation" --infobox "Installation de \`$x\` (requis par d'autre programmes)." 5 70
	installpkg "$x"
done

dialog --title "Installation" --infobox "Synchronisation de l'heure (heure française en métropole)..." 4 70
ntpdate 0.fr.pool.ntp.org >/dev/null 2>&1

adduserandpass || error "Erreur lors de l'ajout de l'utilisateur."

[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers # Just in case

# Allow user to run sudo without password. Since AUR programs must be installed
# in a fakeroot environment, this is required for all builds with AUR.
newperms "%wheel ALL=(ALL) NOPASSWD: ALL"

# Make pacman and paru colorful and adds eye candy on the progress bar because why not.
#grep -q "^Color" /etc/pacman.conf || sed -i "s/^#Color$/Color/" /etc/pacman.conf
#grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

# Use all cores for compilation.
sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

manualinstall yay-bin || error "Erreur d'installation du gestionnaire de paquets AUR."

# The command that does all the installing. Reads the programmes.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
installationloop

dialog --title "Installation" --infobox "Installation de \`libxft-bgra\` pour activer les couleurs et emojis." 5 70
yes | sudo -u "$name" $aurhelper -S libxft-bgra-git >/dev/null 2>&1

# Install the dotfiles in the user's home directory
putgitrepo "$dotfilesrepo" "/home/$name" "$repobranch"
#putgitrepo "$dotfilesrepo" "/home/$name"
rm -f "/home/$name/README.md" "/home/$name/LICENSE" "/home/$name/FUNDING.yml"
# Create default urls file if none exists.
#[ ! -f "/home/$name/.config/newsboat/urls" ] && echo "http://lukesmith.xyz/rss.xml
#https://notrelated.libsyn.com/rss
#https://www.youtube.com/feeds/videos.xml?channel_id=UC2eYFnH61tmytImy1mTYvhA \"~Luke Smith (YouTube)\"
#https://www.archlinux.org/feeds/news/" > "/home/$name/.config/newsboat/urls"
# make git ignore deleted LICENSE & README.md files
#git update-index --assume-unchanged "/home/$name/README.md" "/home/$name/LICENSE" "/home/$name/FUNDING.yml"

# Installer dwm, dwmblocks, dmenu & st
installsuckless

# Most important command! Get rid of the beep!
systembeepoff

# Make zsh the default shell for the user.
chsh -s /bin/zsh "$name" >/dev/null 2>&1
sudo -u "$name" mkdir -p "/home/$name/.cache/zsh/"

# dbus UUID must be generated for Artix runit.
dbus-uuidgen > /var/lib/dbus/machine-id

# Use system notifications for Brave on Artix
echo "export \$(dbus-launch)" > /etc/profile.d/dbus.sh

# Tap to click
[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && printf 'Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
	# Enable left mouse button by tapping
	Option "Tapping" "on"
EndSection' > /etc/X11/xorg.conf.d/40-libinput.conf

# Fix fluidsynth/pulseaudio issue.
grep -q "OTHER_OPTS='-a pulseaudio -m alsa_seq -r 48000'" /etc/conf.d/fluidsynth ||
	echo "OTHER_OPTS='-a pulseaudio -m alsa_seq -r 48000'" >> /etc/conf.d/fluidsynth

# Start/restart PulseAudio.
pkill -15 -x 'pulseaudio'; sudo -u "$name" pulseaudio --start

# This line, overwriting the `newperms` command above will allow the user to run
# serveral important commands, `shutdown`, `reboot`, updating, etc. without a password.
newperms "%wheel ALL=(ALL) ALL #NOM_SCRIPT
%wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/packer -Syu,/usr/bin/packer -Syyu,/usr/bin/systemctl restart NetworkManager,/usr/bin/rc-service NetworkManager restart,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/paru,/usr/bin/pacman -Syyuw --noconfirm"

# Last message! Install complete!
finalize
clear
