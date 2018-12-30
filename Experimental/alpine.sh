#!/data/data/com.termux/files/usr/bin/bash
folder=alpine-fs
if [ -d "$folder" ]; then
	first=1
	echo "skipping downloading"
fi
tarball="alpine-rootfs.tar.gz"
if [ "$first" != 1 ];then
	if [ ! -f $tarball ]; then
		echo "Download Rootfs, this may take a while base on your internet speed."
		case `dpkg --print-architecture` in
		aarch64)
			archurl="aarch64" ;;
		arm)
			archurl="armhf" ;;
		amd64)
			archurl="x86_64" ;;
		x86_64)
			archurl="x86_64" ;;	
		i*86)
			archurl="x86" ;;
		x86)
			archurl="x86" ;;
		*)
			echo "unknown architecture"; exit 1 ;;
		esac
		ALPINE_VER=$(curl -s http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${archurl}/latest-releases.yaml | grep -m 1 -o version.* | sed -e 's/[^0-9.]*//g' -e 's/-$//')
		wget "http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/${archurl}/alpine-minirootfs-${ALPINE_VER}-${archurl}.tar.gz" -O $tarball
	fi
	cur=`pwd`
	mkdir -p "$folder"
	cd "$folder"
	echo "Decompressing Rootfs, please be patient."
	proot --link2symlink tar -xf ${cur}/${tarball}||:
	cd "$cur"
fi
mkdir -p alpine-binds
bin=start-alpine.sh
echo "writing launch script"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder"
if [ -n "\$(ls -A alpine-binds)" ]; then
    for f in alpine-binds/* ;do
      . \$f
    done
fi
command+=" -b /dev"
command+=" -b /proc"
command+=" -b alpine-fs/tmp:/dev/shm"
## uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to / 
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

echo "fixing shebang of $bin"
termux-fix-shebang $bin
echo "making $bin executable"
chmod +x $bin
echo "removing image for some space"
rm $tarball
echo "You can now launch Alpine with the ./${bin} script"