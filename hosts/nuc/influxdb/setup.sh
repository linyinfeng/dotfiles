#!@shell@

influx="@influxdb2@/bin/influx"
curl="@curl@/bin/curl"
bucket="@bucket@"
org="@org@"
retention="@retention@"
username="@username@"

set -e

if [ -f "$INFLUX_CONFIGS_PATH" ]; then
    echo "already setup"
    exit 0
fi

# start setup

while [ "$("$curl" -sL -w "%{http_code}" "$INFLUX_HOST/ping")" != "204" ]; do
    # if influxdb is not up
    echo "wait for influxdb"
    sleep 1 # wait one second
done

password=$(cat "$CREDENTIALS_DIRECTORY/password")

echo "y" | "$influx" setup \
  --username "$username" \
  --password "$password" \
  --token "$(cat "$CREDENTIALS_DIRECTORY/token")" \
  --org "$org" \
  --bucket "$bucket" \
  --retention "$retention"
