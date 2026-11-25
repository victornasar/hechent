import json,sys,os
H=os.path.expanduser("~/verify-blind-runs")
arm,name,lines=sys.argv[1],sys.argv[2],int(sys.argv[3])
for f in ("transcript.jsonl","transcript-2.jsonl"):
    p=f"{H}/{arm}/_transcripts/{name}/{f}"
    if not os.path.exists(p): continue
    r=[json.loads(l) for l in open(p) if l.strip()]; r=[e for e in r if e.get("type")=="result"][0]
    txt=[l for l in r["result"].split("\n") if l.strip()]
    print(f"  --- {f}"); print("\n".join("  "+l[:210] for l in txt[:lines]))
