Expose
======

Port 8042 22 3306  
Volume /data rw

Info
----

This image is for development purpose only, do not use it in prod   
Mysql passwords are shown in stdout at the first run of the container   
Default credentials for totodl are admin@admin.org:admin   
Default ssh root password is root   

Example
------
```bash
docker build -t totodl .   
docker run -v /home/user/totodl_dev:/data:rw -p 8042:8042 totodl   
```

To use streaming features, you will have to create a new host named "totodl.dev" pointing to totodl host. You cannot map the port 8042.   
If you want to change this edit config/totodl.json (download section) and config/totodl.nginx   

