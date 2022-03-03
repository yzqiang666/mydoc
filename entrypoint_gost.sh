#!/bin/bash
###  第一行的内容必不可少

PP=${PORT}

#v2ray-plugin版本
if [[ -z "${VER}" ]]; then
  VER="latest"
fi


if [[ -z "${PASSWORD}" ]]; then
  PASSWORD="5c301bb8-6c77-41a0-a606-4ba11bbab084"
fi


if [[ -z "${ENCRYPT}" ]]; then
  ENCRYPT="rc4-md5"
fi

if [[ -z "${V2_Path}" ]]; then
  V2_Path="/s233"
fi

if [[ -z "${PLUGIN}" ]]; then
  PLUGIN="v2ray-plugin"
fi


if [[ -z "${PLUGIN_OPTS}" ]]; then
   PLUGIN_OPTS="server;path=/s233}"
  if [ "${PLUGIN}" == "obfs-server" ] ; then
    PLUGIN_OPTS="obfs=http;obfs-host=www.bing.com;path=/"    
  fi
fi


if [[ -z "${QR_Path}" ]]; then
  QR_Path="/qr_img"
fi

cd /wwwroot
tar xvf wwwroot.tar.gz >/dev/null 2>/dev/null
rm -rf wwwroot.tar.gz

if [ ! -d /etc/shadowsocks-libev ]; then  
  mkdir /etc/shadowsocks-libev
fi

# TODO: bug when PASSWORD contain '/'
sed -e "/^#/d"\
    -e "s/\${PASSWORD}/${PASSWORD}/g"\
    -e "s/\${ENCRYPT}/${ENCRYPT}/g"\
    -e "s/\${PLUGIN}/${PLUGIN}/g"\
    -e "s|\${PLUGIN_OPTS}|${PLUGIN_OPTS}|g"\
    -e "s|\${V2_Path}|${V2_Path}|g"\
    /conf/shadowsocks-libev_config.json >  /etc/shadowsocks-libev/config.json

if [[ -z "${ProxySite}" ]]; then
  s="s/proxy_pass/#proxy_pass/g"
#  echo "site:use local wwwroot html"
else
  s="s|\${ProxySite}|${ProxySite}|g"
#  echo "site: ${ProxySite}"
fi

wget -q -O download.tmp "$NGINX_SERVER_URL"
if [ -s download.tmp ] && [ ! "`grep \"server {\" download.tmp`" == "" ] ; then
 echo "Download from url ${NGINX_SERVER_URL} file success." 
else
  cp /conf/nginx_ss.conf ownload.tmp
  echo "Use default ss.conf."
fi

sed -e "/^#/d"\
    -e "s/\${AppName}/${AppName}/g"\
    -e "s/\${PORT}/${PORT}/g"\
    -e "s|\${V2_Path}|${V2_Path}|g"\
    -e "s|\${QR_Path}|${QR_Path}|g"\
    -e "$s"\
    download.tmp > /etc/nginx/conf.d/ss.conf
     
if [ ! "${NGINX_CONF_URL}" == "" ] ; then
  wget -q -O download1.tmp "$NGINX_CONF_URL"
  if [ -s download1.tmp ] && [ ! "`grep \"worker_processes\" download1.tmp`" == "" ] ; then
    cp download1.tmp /tmp/nginx.conf
    echo "Download from url ${NGINX_CONF_URL} file success." 
  else
    cp /etc/nginx/nginx.conf /tmp/nginx.conf
    echo "Download from url ${NGINX_CONF_URL} file failed." 
  fi
else
    cp /etc/nginx/nginx.conf /tmp/nginx.conf
    echo "Use default nginx.conf."
fi

#echo =====================================================================
#echo 下载地址：${NGINX_CONF_URL}
#echo 以下为nginx配置文件：/etc/nginx/nginx.conf
#cat /etc/nginx/nginx.conf
#echo =====================================================================
#echo 以下为ss配置文件：/etc/nginx/conf.d/ss.conf
#cat /etc/nginx/conf.d/ss.conf
#echo =====================================================================

rm -rf /etc/nginx/sites-enabled/* >/dev/null 2>/dev/null

echo gost  -L="ss://$ENCRYPT:$PASSWORD@:2334"
gost  -L="ss://$ENCRYPT:$PASSWORD@:2334" &
echo "############# GOST information #####################"



cp /tmp/nginx.conf /etc/nginx/nginx.conf
if [ -s /tmp/nginx.conf ] ; then
  cat /etc/nginx/conf.d/ss.conf
  nginx -t -c /tmp/nginx.conf
  nginx -c /tmp/nginx.conf -g 'daemon off;'
else
  nginx -t
  nginx -g 'daemon off;'
fi
exit 1
