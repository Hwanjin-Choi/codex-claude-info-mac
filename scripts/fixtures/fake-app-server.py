#!/usr/bin/env python3
"""Local test double; never reads credentials or contacts a service."""
import json
import sys
import time

initialized = False
for line in sys.stdin:
    message = json.loads(line)
    method = message["method"]
    if method == "initialized":
        initialized = True
        continue
    if method == "hang":
        continue
    reply = {"id": message["id"]}
    if method == "initialize":
        time.sleep(0.05)
        reply["result"] = {}
    elif not initialized:
        reply["error"] = {"message": "Request sent before initialization completed"}
    elif method == "unsupported":
        reply["error"] = {"message": "Unsupported method"}
    else:
        reply["result"] = {"ok": True}
    print(json.dumps(reply), flush=True)
