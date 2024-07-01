#!/bin/sh

upload() {
    md5_dir=/root/md5/
    cert_pem=$1
    cert_file=$2

    ssh pi@192.168.1.50 'mkdir -p /tmp/blog'
    scp $cert_pem pi@192.168.1.50:/tmp/blog/
    echo $cur_cert_md5 > ${md5_dir}${cert_file}
}

process1() {
    md5_dir=/root/md5/
    cert_pem=$1
    cert_file=$2

    echo "*** Processing $cert_pem..."

    cur_cert_md5=`md5sum ${cert_pem} | awk '{ print $1 }'`

    old_cert_md5=`cat ${md5_dir}${cert_file}`
    echo "  old_cert_md5=$old_cert_md5"
    echo "  cur_cert_md5=$cur_cert_md5"

    if [ "$old_cert_md5" = "$cur_cert_md5" ]; then
        echo "  MD5 has not changed. Checking if file still exists on rpi13..."

        command="ssh pi@192.168.1.50 '/home/pi/bin/blog/$cert_file'"
        exists=`$command`
        echo "  exists=$exists"
        if [ "$exists" = "1" ]; then
            echo "  File exists on rpi13. Doing nothing"
        else 
            echo "  File does not exist on rpi13. Uploading..."
            upload $cert_pem $cert_file
        fi
    else
        echo "  MD5 has changed. Processing..."

        upload $cert_pem $cert_file
    fi

}

process1 "/etc/letsencrypt/live/blog.tdod.org-0001/cert.pem" "cert.md5"
process1 "/etc/letsencrypt/live/blog.tdod.org-0001/chain.pem" "chain.md5"
process1 "/etc/letsencrypt/live/blog.tdod.org-0001/fullchain.pem" "fullchain.md5"
process1 "/etc/letsencrypt/live/blog.tdod.org-0001/privkey.pem" "privkey.md5"

