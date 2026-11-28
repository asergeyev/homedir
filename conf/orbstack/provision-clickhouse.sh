#!/usr/bin/env bash
# provision-clickhouse.sh — Provision OrbStack `clickhouse` Ubuntu machine as a one-node
# cluster `main` with embedded Keeper and prod's macros, listening on ports 39000 / 38123.
# Installs the latest stable release and upgrades to it on every run. To pin one (e.g. prod's, for an upgrade test):
#   orb -m clickhouse env CH_VERSION=<x.y.z.w> bash -s < conf/orbstack/provision-clickhouse.sh
# A later run without CH_VERSION (10-setup-orbstack.sh too) moves it back to the latest.
set -euo pipefail

CH_VERSION="${CH_VERSION:-latest}"
PKGS=(clickhouse-common-static clickhouse-server clickhouse-client)

# sudo drops an exported DEBIAN_FRONTEND, and apt runs maintainer scripts on a pty, so without it the
# clickhouse-server postinst waits forever for a default-user password
apt_get() { sudo env DEBIAN_FRONTEND=noninteractive apt-get "$@"; }

# "installed" = configured, so a half-configured package (an interrupted postinst) is fixed too;
# not Status-Abbrev, which the hold below turns from "ii" into "hi"
installed() { dpkg-query -W -f='${db:Status-Status} ${Version}' clickhouse-server 2>/dev/null || true; }
before=$(installed)
if [ "$CH_VERSION" = latest ] || [ "$before" != "installed $CH_VERSION" ]; then
  apt_get update
  apt_get install -y apt-transport-https ca-certificates curl gnupg
  curl -fsSL https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key \
    | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=$(dpkg --print-architecture)]" \
    "https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list >/dev/null
  apt_get update
  sudo apt-mark unhold "${PKGS[@]}" || true
  if [ "$CH_VERSION" = latest ]; then
    apt_get install -y "${PKGS[@]}" </dev/null
  else
    apt_get install -y --allow-downgrades "${PKGS[@]/%/=$CH_VERSION}" </dev/null
  fi
  sudo apt-mark hold "${PKGS[@]}"
  # The running server keeps its old binary until restarted
  [ "$(installed)" = "$before" ] || sudo systemctl try-restart clickhouse-server
fi

changed=0
tmp=$(mktemp)
cat >"$tmp" <<'EOF'
<clickhouse>
    <logger><level>information</level></logger>
    <timezone>UTC</timezone>
    <!-- Use 39000/38123 so scratch ClickHouse never collides with 9000/9440 -->
    <tcp_port>39000</tcp_port>
    <http_port>38123</http_port>
    <interserver_http_port>9009</interserver_http_port>
    <interserver_http_host>127.0.0.1</interserver_http_host>

    <keeper_server>
        <tcp_port>9181</tcp_port>
        <server_id>1</server_id>
        <log_storage_path>/var/lib/clickhouse/coordination/log</log_storage_path>
        <snapshot_storage_path>/var/lib/clickhouse/coordination/snapshots</snapshot_storage_path>
        <raft_configuration>
            <server><id>1</id><hostname>127.0.0.1</hostname><port>9234</port></server>
        </raft_configuration>
    </keeper_server>
    <zookeeper>
        <node><host>127.0.0.1</host><port>9181</port></node>
    </zookeeper>

    <remote_servers>
        <main>
            <shard><replica><host>127.0.0.1</host><port>39000</port></replica></shard>
        </main>
    </remote_servers>
    <macros>
        <cluster>main</cluster>
        <shard>s0</shard>
        <replica>r0</replica>
    </macros>
    <default_replica_path>/clickhouse/tables/{uuid}/{cluster}-{shard}</default_replica_path>
    <default_replica_name>{replica}</default_replica_name>
    <distributed_ddl><path>/clickhouse/task_queue/ddl</path></distributed_ddl>
</clickhouse>
EOF

if ! sudo cmp -s "$tmp" /etc/clickhouse-server/config.d/scratch.xml; then
  sudo install -m 0644 "$tmp" /etc/clickhouse-server/config.d/scratch.xml
  changed=1
fi
rm -f "$tmp"

# A plain clickhouse-client in the machine uses the scratch port; the client reads it per run, no restart.
# The root must be <config> like the packaged config.xml's, or the client ignores the file.
sudo mkdir -p /etc/clickhouse-client/config.d
echo '<config><port>39000</port></config>' | sudo tee /etc/clickhouse-client/config.d/scratch.xml >/dev/null

sudo systemctl enable clickhouse-server
if [ "$changed" = 1 ]; then
  sudo systemctl restart clickhouse-server
else
  sudo systemctl start clickhouse-server
fi

for _ in $(seq 1 60); do
  if clickhouse-client --port 39000 -q "SELECT 1" </dev/null >/dev/null 2>&1; then
    echo "OrbStack ClickHouse scratch server is ready on port 39000 (HTTP 38123)."
    exit 0
  fi
  sleep 2
done

echo "ClickHouse server did not respond on port 39000" >&2
exit 1
