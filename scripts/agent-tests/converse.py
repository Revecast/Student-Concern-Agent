"""Run one scripted conversation against an agent preview (live actions). Usage: converse.py <bundle> "utt1" "utt2" ..."""
import json, subprocess, sys
ORG = "jaxedupde-dev-ed"
def sf(args):
    out = subprocess.run(["sf", "agent", "preview"] + args + ["--target-org", ORG, "--json"],
                         capture_output=True, text=True, timeout=600).stdout
    try:
        return json.loads(out)
    except Exception:
        return {"status": 1, "message": out[:1500]}
def text(d):
    r = d.get("result") or {}
    msgs = r.get("messages") or r.get("response", {}).get("messages") or []
    if isinstance(msgs, list) and msgs:
        return " | ".join(m.get("message", m.get("text", "")) or json.dumps(m)[:400] for m in msgs)
    return json.dumps(d)[:1500]
bundle, utts = sys.argv[1], sys.argv[2:]
s = sf(["start", "--authoring-bundle", bundle, "--use-live-actions"])
sid = (s.get("result") or {}).get("sessionId")
print("START:", text(s) if sid else json.dumps(s)[:1500])
for u in utts:
    r = sf(["send", "--session-id", sid, "--authoring-bundle", bundle, "--utterance", u])
    print("\nADVISOR:", u, "\nAGENT:", text(r))
sf(["end", "--session-id", sid, "--authoring-bundle", bundle])
