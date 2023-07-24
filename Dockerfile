FROM archlinux:latest
RUN \
  echo -e [multilib]\\nInclude = /etc/pacman.d/mirrorlist >> /etc/pacman.conf && \
  pacman -Sy --noconfirm tar lib32-glibc wine winetricks grep awk nano sudo unzip xorg-server-xvfb x11vnc openbox && \
  useradd -m -G wheel user && \
  echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
USER user
RUN \
  WINEARCH=win64 xvfb-run -s '-screen 0 1280x720x24' -n 99 -l -- sh -c 'WINEDLLOVERRIDES="mscoree,mshtml=" wineboot --init /nogui -u && \
    winetricks sound=disabled && winetricks -q corefonts vcrun2013 vcrun2017 dotnet48 d3dcompiler_47 && \
    winetricks -q --force vcrun2019 && \
    wine reg add "HKCU\Software\Wine\DllOverrides" "/f" "/v" "d3d9" "/t" "REG_SZ" "/d" "native" && \
    wine reg add "HKCU\\SOFTWARE\\Microsoft\\Avalon.Graphics" /v DisableHWAcceleration /t REG_DWORD /d 1 /f'

# torch distribution
ADD https://build.torchapi.com/job/Torch/job/master/lastSuccessfulBuild/artifact/bin/torch-server.zip /home/user/torch-server.zip
USER root
# torch distribution tuning & cleanup
RUN \
  mkdir /home/user/{torch,data} && \
  unzip /home/user/torch-server.zip -d /home/user/torch && \
  chown user:user -R /home/user/{torch,data} && \
  rm -rf /home/user/.cache /home/user/torch-server.zip /var/cache/pacman/pkg/* /tmp/* /var/tmp/*
## runtime
USER user
WORKDIR /home/user
VOLUME /home/user/data
ENV VNC_OPTIONS="-nevershared -forever" XVFB_OPTIONS="-s '-screen 0 1280x720x24'"
COPY ./entrypoint.sh .
EXPOSE 5900 8080 27016/udp
ENTRYPOINT ["/home/user/entrypoint.sh"]
