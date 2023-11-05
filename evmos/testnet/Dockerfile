
FROM gregsaram/evmos:1.0.0
WORKDIR /root
USER root
RUN apk add --no-cache python3 py3-pip && pip3 install ijson
COPY testnet_node.sh /usr/bin/testnet_node.sh
RUN chmod +x /usr/bin/testnet_node.sh
COPY genesis_edit.py /usr/bin/genesis_edit.py
RUN chmod +x /usr/bin/genesis_edit.py
# RUN addgroup -g 1000 evmos \
# && adduser -S -h /home/evmos -D evmos -u 1000 -G evmos

# USER 1000
# WORKDIR /home/evmos

EXPOSE 26656 26657 1317 9090 8545 8546

CMD ["evmosd"]
