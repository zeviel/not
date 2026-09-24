wget "https://github.com/p1neappleXpress/OpenFlux/releases/download/0.0.4/openflux-linux-arm"
chmod +x openflux-linux-arm
sudo ./openflux-linux-arm64 --role=exit --mode=l3 \
    --transport=yandex \
    --url="https://boards.yandex.ru/whiteboard/?hash=d3cf401d147809302c35d2859a4d4e05"
