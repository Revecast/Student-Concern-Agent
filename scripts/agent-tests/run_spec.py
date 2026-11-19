"""Run every test case in an agent test spec as a fresh live preview conversation and write a markdown transcript.
Substitute for Testing Center where the org can't create AiEvaluationDefinition/AiTestingDefinition."""
import subprocess, sys, yaml, datetime
spec_path, out_path = sys.argv[1], sys.argv[2]
spec = yaml.safe_load(open(spec_path))
lines = [f"# {spec['name']} — live preview run {datetime.date.today()}", "",
         f"Agent: `{spec['subjectName']}` (authoring bundle, live actions, running as the CLI user).", ""]
for i, tc in enumerate(spec["testCases"], 1):
    utt = tc["inputs"][0]["utterance"]
    expected = {s["name"]: s.get("expected") for s in tc["scorers"]}
    out = subprocess.run(["python3", "scripts/agent-tests/converse.py", spec["subjectName"], utt],
                         capture_output=True, text=True, timeout=900).stdout
    reply = out.split("AGENT:", 1)[1].strip() if "AGENT:" in out else out.strip()
    lines += [f"## Case {i}: {utt}", "", f"**Expected topic:** `{expected.get('topic_sequence_match')}`  ",
              f"**Expected outcome:** {expected.get('bot_response_rating')}", "", "**Agent reply:**", "",
              "> " + reply.replace("\n", "\n> "), ""]
open(out_path, "w").write("\n".join(lines))
print("written", out_path)
