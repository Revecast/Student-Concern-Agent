"""Run a prompt template live via the generations API. Usage: gen_test.py <Template> <json valueMap>"""
import json, subprocess, sys, tempfile
def run(tpl, value_map):
    body = {"isPreview": False, "inputParams": {"valueMap": value_map},
            "additionalConfig": {"applicationName": "PromptTemplateGenerationsInvocable"}}
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump(body, f); path = f.name
    out = subprocess.run(["sf", "api", "request", "rest", f"/services/data/v68.0/einstein/prompt-templates/{tpl}/generations",
                          "--method", "POST", "--body", f"@{path}", "--target-org", "jaxedupde-dev-ed"],
                         capture_output=True, text=True).stdout
    try:
        d = json.loads(out)
        return d["generations"][0]["text"]
    except Exception:
        return "ERROR: " + out[:800]
