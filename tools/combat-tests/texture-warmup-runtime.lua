function T.add(key,fn)
    if T.jobKeys[key]then return end
    T.jobKeys[key]=true;T.jobs[#T.jobs+1]={key=key,run=fn}
    if T.started and not T.hooked then Events.OnTick.Add(T.tick);T.hooked=true end
end
function T.tick()
    if isGamePaused and isGamePaused()then return end
    if T.index<=#T.paths then
        local stop=math.min(#T.paths,T.index+T.batch-1)
        for index=T.index,stop do local path=T.paths[index];if not T.textures[path]then T.textures[path]=getTexture(path)end end
        T.index=stop+1
    else
        local job=table.remove(T.jobs,1)
        if job then local ok,err=pcall(job.run);if not ok then print("[ProjectYakuza] Warm-up "..job.key..": "..tostring(err))end end
    end
    if T.index>#T.paths and #T.jobs==0 then Events.OnTick.Remove(T.tick);T.hooked=false end
end
function T.start()
    T.started=true
    if not T.hooked and(T.index<=#T.paths or #T.jobs>0)then Events.OnTick.Add(T.tick);T.hooked=true end
end
Events.OnCreatePlayer.Add(T.start)
Events.OnGameStart.Add(T.start)
