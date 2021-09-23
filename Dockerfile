FROM centos:8

RUN yum install -y unzip wget

RUN useradd -G root -m godot

WORKDIR /opt/server

RUN wget https://downloads.tuxfamily.org/godotengine/3.3.3/Godot_v3.3.3-stable_linux_headless.64.zip -O Godot_v3.3.3-stable_linux_headless.64.zip
RUN wget https://downloads.tuxfamily.org/godotengine/3.3.3/Godot_v3.3.3-stable_linux_server.64.zip -O Godot_v3.3.3-stable_linux_server.64.zip
RUN unzip Godot_v3.3.3-stable_linux_headless.64.zip
RUN unzip Godot_v3.3.3-stable_linux_server.64.zip

COPY . .

RUN chown godot:root -R /opt/server
USER godot

RUN ./Godot_v3.3.3-stable_linux_headless.64 --export-pack "Linux Server" server.pck

CMD ["./Godot_v3.3.3-stable_linux_server.64", "--main-pack", "server.pck"]