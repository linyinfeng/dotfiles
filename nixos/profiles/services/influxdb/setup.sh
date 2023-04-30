#!@shell@

influx="@influxdb2@/bin/influx"
curl="@curl@/bin/curl"
bucket="@bucket@"
org="@org@"
retention="@retention@"
username="@username@"

set -e

while [ "$("$curl" -sL -w "%{http_code}" "$INFLUX_HOST/ping")" != "204" ]; do
  # if influxdb is not up
  echo "wait for influxdb"
  sleep 1 # wait one second
done

if [ ! -f "$INFLUX_CONFIGS_PATH" ]; then
  echo "setting up..."

  password=$(cat "$CREDENTIALS_DIRECTORY/password")

  echo "y" | "$influx" setup \
    --username "$username" \
    --password "$password" \
    --token "$(cat "$CREDENTIALS_DIRECTORY/token")" \
    --org "$org" \
    --bucket "$bucket" \
    --retention "$retention"

  touch "$INFLUX_CONFIGS_PATH"
fi

# ensure buckets
buckets=(@ensureBuckets@)
for bucket in "${buckets[@]}"; do
  echo "ensure bucket '$bucket'"
  if "$influx" bucket list --org "$org" \
    --token "$(cat "$CREDENTIALS_DIRECTORY/token")" \
    --name "$bucket"; then
    echo "bucket '$bucket' already exists"
  else
    echo "create bucket '$bucket'"
    "$influx" bucket create \
      --token "$(cat "$CREDENTIALS_DIRECTORY/token")" \
      --name "$bucket" \
      --retention "$retention"
  fi
done
