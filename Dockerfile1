FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y tmate openssh-server openssh-client && \
    sudo sed -i 's/^#\?\s*PermitRootLogin\s\+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo 'root:root' | chpasswd && \
    printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d && \
    apt-get install -y systemd systemd-sysv dbus dbus-user-session && \
    printf "systemctl start systemd-logind" >> /etc/profile

CMD ["bash"]
ENTRYPOINT ["/sbin/init"]
