sudo /home/pi/bin/mountrw.sh
sudo chown root:root /tmp/blog/*
sudo chown root:root /tmp/cloud/*
sudo /home/pi/bin/mountro.sh
sudo cp /tmp/blog/* /etc/letsencrypt/live/blog.tdod.org-0001
sudo cp /tmp/cloud/* /etc/letsencrypt/live/cloud.tdod.org
sleep 1
sudo /home/pi/bin/mountro.sh
sudo rm /tmp/blog/*
sudo rm /tmp/cloud/*

