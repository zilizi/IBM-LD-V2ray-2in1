name: IBM Cloud Foundry - V2Ray

env:
  IBM_CF_API: https://api.${{ secrets.IBM_CF_REGOIN }:-eu-gb}.cf.cloud.ibm.com
  IBM_CF_APP_MEM: ${{ secrets.IBM_CF_APP_MEM }:-128M}
  IBM_CF_USERNAME: ${{ secrets.IBM_CF_USERNAME }}
  IBM_CF_PASSWORD: ${{ secrets.IBM_CF_PASSWORD }}
  IBM_CF_APP_NAME1: ${{ secrets.IBM_CF_APP_NAME1 }}
  IBM_CF_APP_NAME2: ${{ secrets.IBM_CF_APP_NAME2 }}
  V2_UUID: ${{ secrets.V2_UUID }:-f3a836ba-e93b-4cf3-8ee9-ce37a1e84cd8}
  V2_WS_PATH: ${{ secrets.V2_WS_PATH }:-/v2ray}


on:
  workflow_dispatch:
  repository_dispatch:
  schedule:
    - cron: 15 21 * * 2

jobs:
  deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 5

    steps:

    - name: Install Cloud Foundry CLI
      run: |
        curl -fsSL "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v7&source=github" | tar -zxC /tmp
        sudo install -m 755 /tmp/cf7 /usr/local/bin/cf
        cf version
        
    - name: Login to IBM Cloud Foundry
      run: |
        cf login \
          -a "${IBM_CF_API}" \
          -u "${IBM_CF_USERNAME}" \
          -p "${IBM_CF_PASSWORD}" \
          -o "${IBM_CF_USERNAME}" \
          -s "dev"
          
    - name: Download Latest V2Ray
      run: |
        DOWNLOAD_URL="https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip"
        curl -fsSL "$DOWNLOAD_URL" -o "latest-v2ray.zip"
        unzip latest-v2ray.zip v2ray v2ctl geoip.dat geosite.dat
        rm latest-v2ray.zip
        chmod -v 755 v2*
        ./v2ray -version
        cp v2ray ${IBM_CF_APP_NAME1}
        mv v2ray ${IBM_CF_APP_NAME2}
      
    - name: Generate V2Ray Config File (VLESS)
      run: |
        base64 << 123 > config1
        {
          "log": {
            "access": "none",
            "loglevel": "error"
          },
          "inbounds": [
            {
              "port": 8080,
              "protocol": "vless",
              "settings": {
                "decryption": "none",
                "clients": [
                  {
                    "id": "${V2_UUID}"
                  }
                ]
              },
              "streamSettings": {
                "network":"ws",
                "wsSettings": {
                  "path": "${V2_WS_PATH}"
                }
              }
            }
          ],
          "outbounds": [
            {
              "protocol": "freedom"
            }
          ]
        }
    - name: Generate V2Ray Config File (VMess)
      run: |
        base64 << 123 > config2
        {
          "log": {
            "access": "none",
            "loglevel": "error"
          },
          "inbounds": [
            {
              "port": 8080,
              "protocol": "vmess",
              "settings": {
                "clients": [
                  {
                    "id": "${V2_UUID}",
                    "alterId": 64
                  }
                ]
              },
              "streamSettings": {
                "network":"ws",
                "wsSettings": {
                  "path": "${V2_WS_PATH}"
                }
              }
            }
          ],
          "outbounds": [
            {
              "protocol": "freedom"
            }
          ]
        }
    - name: Generate Manifest File (VLESS)
      run: |
        cat << 123 > manifest.yml
        applications:
        - name: ${IBM_CF_APP_NAME1}
          memory: ${IBM_CF_APP_MEM}
          random-route: true
          command: base64 -d config1 > config.json; ./${IBM_CF_APP_NAME1} -config=config.json
          buildpacks:
          - binary_buildpack
        
    - name: Deploy Cloud Foundry App (VLESS)
      run: cf push
      
    - name: Generate Manifest File (VMess)
      run: |
        cat << 123 > manifest.yml
        applications:
        - name: ${IBM_CF_APP_NAME2}
          memory: ${IBM_CF_APP_MEM}
          random-route: true
          command: base64 -d config2 > config.json; ./${IBM_CF_APP_NAME2} -config=config.json
          buildpacks:
          - binary_buildpack
        
    - name: Deploy Cloud Foundry App (VMess)
      run: cf push
