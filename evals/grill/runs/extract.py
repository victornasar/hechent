import json,sys
path=sys.argv[1]; mode=sys.argv[2] if len(sys.argv)>2 else "summary"
ev=[json.loads(l) for l in open(path) if l.strip()]
results={}
for e in ev:
    if e.get("type")=="user":
        for c in e["message"].get("content",[]) if isinstance(e["message"].get("content"),list) else []:
            if c.get("type")=="tool_result":
                txt=c.get("content")
                if isinstance(txt,list): txt=" ".join(x.get("text","") for x in txt if isinstance(x,dict))
                results[c["tool_use_id"]]=(str(txt), c.get("is_error"))
for e in ev:
    t=e.get("type")
    if t=="system" and e.get("subtype")=="init":
        print("MODEL:",e.get("model"),"| skills:",e.get("skills"))
    if t=="assistant":
        for c in e["message"]["content"]:
            if c.get("type")=="tool_use":
                i=c["input"]; name=c["name"]
                if name=="Bash": s="$ "+i.get("command","")
                elif name in("Read","Write","Edit"): s=name+" "+i.get("file_path","")
                elif name=="Skill": s="SKILL "+json.dumps(i)
                elif name=="Agent" or name=="Task": s="AGENT "+i.get("description","")+" :: "+i.get("prompt","")[:300]
                else: s=name+" "+json.dumps(i)[:200]
                out,err=results.get(c["id"],("",None))
                if mode=="full":
                    print("-"*60); print(s[:1500]); print("  -> "+("[ERR] " if err else "")+out[:900].replace("\n","\n     "))
                else:
                    print(s.replace("\n"," ")[:220])
    if t=="result":
        print("=== RESULT turns=%s cost=%s dur=%ss"%(e.get("num_turns"),e.get("total_cost_usd"),round(e.get("duration_ms",0)/1000)))
        if mode!="cmds": print(e.get("result",""))
