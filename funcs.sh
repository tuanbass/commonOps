#!/bin/bash 

. /src/ops/.privateParam

#alias internetIP='curl ifconfig.co; curl ifconfig.co/country'
alias internetIP='curl ifconfig.co/json 2>null|jq'

alias sqlplus="rlwrap sqlplus"


function xxx(){
    
    echo test something
}

######### log in several servers
function login_ssh(){
    local server=$1
    local key=$2
    shift 2
    rlwrap autossh $server  -i $key -M 0 -o "ServerAliveInterval 60" -o "ServerAliveCountMax 3" $@

}

function login_coquat_public (){
    login_ssh "coquat.net" "/home/tuanba1/.ssh/id_rsa_new_server" -p 22
}

function login_coquat_VPN (){
    login_ssh $OPEN_VPN_GW_INTERNAL "/home/tuanba1/.ssh/id_rsa_new_server" -p 22
}

function login_tuanbass_pc_rec() {
    login_ssh "$TUANBA1_PC_REC" "/home/tuanba1/.ssh/tuanbass_pc.pem" -p 3389  
}

function login_tuanbass_pc_stu() {
    login_ssh "$TUANBA1_PC_STU" "/home/tuanba1/.ssh/tuanba1.stu.pem" -p 3389
}


############port forwarding relate stuffd

 function map_port () {

    #check argument
    if [[ $# -lt 3 ]]; then
        echo "Usage: mapport <target_host> <local_port> <proxy_host> [remote_port]"
        return
    fi

    local HOST_SERVICE=$1
    local LOCAL_PORT=$2
    local PROXY_HOST=$3

    if [[ -z $4 ]]; then
         REMOTE_PORT=$LOCAL_PORT
         shift 3
    else
        REMOTE_PORT=$4
        shift 4
    fi

    echo "mapping local $LOCAL_PORT to remote $REMOTE_PORT"

    PORT_SSH=3389
    HOST_SSH=$PROXY_HOST
    COMMAND=`echo autossh $HOST_SSH -p $PORT_SSH  -o ConnectTimeout=10  -N  -L$LOCAL_PORT:$HOST_SERVICE:$REMOTE_PORT $*`
    echo $COMMAND
    eval $COMMAND
     
 }
 
 function startrdp () {
     #check if rdp port was already binding 
    rdp_port=$(netstat -pln|grep :3388|wc -l) 
    echo -n $rdp_port |tee /tmp/rdp
    if [[ rdp_port -ne 0 ]]; then
        read -p "POrt 3388 is already bound. Kill the owner? (y/n)" yn
        case $yn in
            [Yy]* ) x=$(netstat -pln|grep :3388|fgrep 'tcp ');
                    pid=$(echo $x|cut -d' ' -f 7|cut -d'/' -f 1);
                    echo "killing process $pid"
                    kill -9 $pid; 
                    ;;
            [Nn]* ) return;;
            * ) echo "Please answer yes or no.";return;;
        esac
    fi

    map_port $TUANBA1_PC_STU 3388 $TUANBA1_PC_STU 3388  -i /home/tuanba1/.ssh/tuanba1.stu.pem -l tuanba1
 }

 function startOpenVPNAdmin(){
     
     #map_port $OPEN_VPN_GW_LISTEN_IF $OPEN_VPN_ADMIN_PORT $OPEN_VPN_GW_INTERNAL $OPEN_VPN_ADMIN_PORT  -i /home/tuanba1/.ssh/id_rsa_new_server -v
     COMMAND=`echo autossh $OPEN_VPN_GW_INTERNAL   -v -o ConnectTimeout=10    -L$OPEN_VPN_ADMIN_PORT:$OPEN_VPN_GW_LISTEN_IF:$OPEN_VPN_ADMIN_PORT -i /home/tuanba1/.ssh/id_rsa_new_server  $*`
     echo $COMMAND
     eval $COMMAND
 }
 
 function startVPNConnection_cq(){
     sudo route add -net 10.133.0.0 netmask 255.255.0.0 gw 10.133.148.1
     sudo route add -net 10.16.0.0 netmask 255.255.0.0 gw 10.133.148.1
     echo "finish config route"
     cd /home/tuanba1/.ssh/openvpn ; sudo  openvpn --config /home/tuanba1/.ssh/tuanba1.ovpn
 }

 function startDNSGoogle(){
     su -c  "echo nameserver 8.8.8.8 >>/etc/resolv.conf"
 }


 function map_share_to_local () {
     TARGET=$1
     
     if [[ -z $TARGET ]]; then
         TARGET=$TUANBA1_PC_STU
     fi

     
     echo "mapping 135"
     su -c "map_port $TARGET 135  $TUANBA1_PC_STU -i /home/tuanba1/.ssh/tuanba1.stu.pem" 
     echo "mapping 139"
     su -c "map_port $TARGET 139  $TUANBA1_PC_STU -i /home/tuanba1/.ssh/tuanba1.stu.pem"  
     
     
 }
 
 function battery(){
     upower -i $(upower -e|grep battery)
 }
 
 function key_en(){
     ibus engine xkb:us::eng
 }
 
 function key_vi(){
      ibus engine Unikey
 }
 
 function key_GUI(){
     gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus','Unikey')]"
 }
 
 function mosh_coquat_public(){
     mosh -p 53 --ssh="ssh  -i /home/tuanba1/.ssh/id_rsa_new_server" root@coquat.net

 }

 function mosh_coquat_st1_public(){
     mosh -p 53 --ssh="ssh  -p 443 -i /home/tuanba1/.ssh/id_rsa_new_server" root@st1.coquat.net

 }

 function osh_coquat_VPN(){
     mosh --ssh="ssh  -i /home/tuanba1/.ssh/id_rsa_new_server" root@$OPEN_VPN_GW_INTERNAL

 }
 
 function tunnel_rec_srv(){

     local srv=$1
     CMD=$(echo -n "sudo autossh -i /home/tuanba1/.ssh/tuanbass_pc.pem -p 3389 10.133.12.152 -L22$srv:10.133.128.$srv:22")
     echo $CMD
     eval $CMD 
 }
 
 
function update-repo() {
              sudo apt-get update -o Dir::Etc::sourcelist="sources.list.d/$1" \
              -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
}

function de (){

	docker exec -it $1 bash 
}

function repeat_cmd (){
    cmd=$1
    interval=$2
    if [[ -z $interval ]]; then 
        interval=1
    fi
    
    echo "excute $cmd in interval $interval second(s)"
    while [ : ]
    do
        sleep $interval
        eval $cmd
    done
}

function ping_gateway(){
    local default_gw=$(route -n|awk '/UG/{print $2}')
    ping $default_gw
}

function  get_netBIOS_name(){
    nmap --script smb-os-discovery.nse  -Pn -p 445 $1
    
} 

function nmap_mass(){
	nmap -Pn --min-rate 5000 --min-parallelism 64 $*
}

function display_position(){
    local attached_display=$(xrandr |grep ' connected'|grep -v LVDS1|cut  -d' ' -f 1)
    xrandr --output LVDS1  --auto --right-of $attached_display
}

function download(){
    axel -n 32 -a $*
}

function openAsso(){
    xdg-open $*
}

function xfree(){

    user=$FSOFT_USER
    pass=$FSOFT_PASS
    drive=" "
    drive="$drive --drive home,/home/tuanba1"
    drive="$drive --drive share,/vol_share"
    drive="$drive --drive src,/src"

    #drive=""

    param=$1
    echo $param 
    if [[ a"$param" == a ]]; then 
        w=1024
        h=740
    else
        w=1366
        h=720
    fi
    xfreerdp  -u $user -p $pass --bpp 32 -v localhost:3388  --disable-wallpaper --disable-themes \
              -w $w -h $h --enable-clipboard $drive 
}




function syncdate(){
    sudo date -s "$(wget -S  "http://www.google.com/" 2>&1 | grep -E '^[[:space:]]*[dD]ate:' | sed 's/^[[:space:]]*[dD]ate:[[:space:]]*//' | head -1l | awk '{print $1, $3, $2,  $5 ,"GMT", $4 }' | sed 's/,//')"
}

function tcp_dump(){
  #sudo tcpdump -i wlp3s0 -w /tmp/tcpdump 'tcp port 443 and host st1.coquat.net' 
  host=$1
  port=$2
  shift
  shift
  sudo tcpdump  -w /tmp/tcpdump $* "tcp port $port and host $host"
}

function mount_all_hdd(){
    hdd=$1
    n=$2
    for  (( i=1; i<$n; i++))
    do 
        mkdir -p /tmp/$hdd$i
        sudo mount /dev/$hdd$i /tmp/$hdd$i
    done 
}

function addresolution(){
#not test yet :-) 
    #DELL in company
    w=1280 
    h=1024
    f=60
    mode=$(cvt $w $h $f|grep Modeline|cut -d" " -f 2-)
    echo aaa 
    echo $mode aa
    cmd="sudo xrandr --newmode $mode"
    echo $cmd 
    eval $cmd 
    echo $?

    cmd="sudo xrandr --addmode HDMI1 ${w}x${h}_${f}.00"
    echo $cmd
    eval $cmd 
    cmd="xrandr --output HDMI1 --mode  ${w}x${h}_${f}.00"   
    echo $cmd
    eval $cmd 

    echo "calibrate touch screen"
    calibrateTouch

}

function calibrateTouch(){
    devid=$(xinput|grep -i ELAN0732|cut -f2|cut -d'=' -f2)
    output=$(xrandr |grep primar|cut -d' ' -f1)
    xinput map-to-output $devid $output

}
function restartCinnamon() {
    DISPLAY=0; pkill -HUP -f "cinnamon --replace" 
}


function togTouchpad {
    devid=$(xinput|grep -i touchpad|cut -f2|cut -d'=' -f2)

    state=$(xinput list-props $devid |grep "Device Enable"|cut -f3)

    if [[ "$state" = "0" ]]
    then
        newstate=1
        echo "Touchpad is disabled. Enabling it..."
    else
        newstate=0
         echo "Touchpad  is enabled. Disabling it..."
    fi

    xinput set-prop $devid "Device Enabled" $newstate

}

function installSDK(){
    curl -s "https://get.sdkman.io" | bash
}

function findEC2AMI_id(){
    aws ec2 describe-images \
    --owners 'aws-marketplace' \
    --filters 'Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce' \
    --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' \
    --output 'text'\
    --region ap-southeast-1
}


function  check_url {
          url=$1
          echo  -n "checking url:$url. "
          response=$(curl --connect-timeout 5 --write-out %{http_code} --silent --output /dev/null $url)
          echo "Response code:$response"
}

function check_url_from_file(){
    URL_FILE=$1
    while read -r LINE ; do
    # trim LINE
    trimmed=`echo  $LINE`

    if [ "$trimmed" == "" ]; then
        continue
    fi

    check_url $trimmed
    done <$URL_FILE
}

function addLocale_ja(){
    sudo touch /var/lib/locales/supported.d/ja
    sudo echo "ja_JP.UTF-8 UTF-8" >>/var/lib/locales/supported.d/ja
    sudo echo "ja_JP SJIS" >>/var/lib/locales/supported.d/ja
    sudo echo "ja_JP.EUC-JP EUC-JP" >>/var/lib/locales/supported.d/ja
    sudo dpkg-reconfigure locales
}

PS1="\e[01;32m\\u@\\h\e[m\e[01;34m \\w\e[m\$(__git_ps1)\n$"
/usr/bin/setxkbmap -option "caps:swapescape"

function bindKey(){
    #vs code
    ln -s /src/ops/vscode_keybindings.json ~/.config/Code/User/keybindings.json
    ln -s /src/ops/vscode_settings.json ~/.config/Code/User/settings.json


}

### autossh 10.133.58.41 -p 3389 -o ConnectTimeout=10 -N -L2345:10.16.133.144:2345 -i /home/tuanba1/.ssh/tuanba1.stu.pem 
### autossh localhost -p 2345 -o ConnectTimeout=10 -N -L1521:atoos-redesign-oracle-28.clbtbmobtpwq.ap-northeast-1.rds.amazonaws.com:1521 
#export LD_LIBRARY_PATH=/home/tuanba1/oracle/12/instantclient_12_2:$LD_LIBRARY_PATH
#export ORACLE_HOME=/home/tuanba1/oracle/12/instantclient_12_2:$ORACLE_HOME
#export PATH=$PATH:$ORACLE_HOME
#sqlplus  KIRARIDEV/KIRARIDEV@'(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SID=ORCL)(SERVER=DEDICATED))))'
#sqlplus  KIRARIDEV/KIRARIDEV@'(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAMESID=ORCL)(SERVER=DEDICATED))))'
#ora2pg -c /home_share/src/ora2pg-18.2/ora2pg.conf -d -l /home_share/src/ora2pg-18.2/ora2pg.log -u KIRARIDEV -w KIRARIDEV



# Wifi FSOFT: Security = WPA2 Enterprise,Auth=LEAP
#( Easy to misuse: Security=LEAP)

#aws ec2 run-instances --image-id ami-xxxxxxxx --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids sg-xxxxxxxx --subnet-id subnet-xxxxxxxx
# win/Linux time shift: 
# timedatectl set-local-rtc 1
