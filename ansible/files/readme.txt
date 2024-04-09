to allow launching the desktop icon:

if we had to copy the file, then:
gio set ~/Desktop/app.desktop metadata::trusted true
chmod a+x ~/Desktop/app.desktop


common place: /usr/share/applications  --> ansible-managed.desktop