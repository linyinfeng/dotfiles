from flask import Flask, jsonify
import aiohttp
import json
import logging

logging.basicConfig(level=logging.INFO)


def create_app():
    app = Flask(__name__)

    app.config.from_prefixed_env("FW_PROXY_SUBSCRIPTION")
    secret = app.config["SECRET"]
    upstream_url = app.config["UPSTREAM_URL"]

    path = f"/{secret}"

    @app.route(path)
    async def subscription():
        async with aiohttp.ClientSession() as session:
            app.logger.info(f"getting {upstream_url}...")
            async with session.get(upstream_url) as response:
                upstream_config = await response.text()
        config = json.loads(upstream_config)
        tailscale_config = {
            "type": "tailscale",
            "tag": "ts-ep",
            "domain_resolver": {
                "server": "dns_proxy",
            },
        }
        if "endpoints" in config:
            config["endpoints"].append(tailscale_config)
        else:
            config["endpoints"] = [tailscale_config]
        tailscale_route_rule = {
            "domain_suffix": [".ts.li7g.com"],
            "ip_cidr": ["100.64.0.0/10", "fd7a:115c:a1e0::/48"],
            "action": "route",
            "outbound": "ts-ep",
        }
        config["route"]["rules"].insert(0, tailscale_route_rule)
        return jsonify(config)

    return app
