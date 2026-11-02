import math

def bridge_scene_cuts(paths,blend_frames=6):
    raw=[[list(point)for point in path]for path in paths]
    count=len(raw[0]);cuts=[]
    for i in range(1,count):
        steps=[math.dist(path[i],path[i-1])for path in raw]
        if min(steps)>.1 and max(steps)>.12:cuts.append(i)
    result=[[list(point)for point in path]for path in raw];offset=[0.,0.];records=[]
    for i in range(count):
        if i in cuts:
            shifts=[[path[i][a]-path[i-1][a]for a in range(2)]for path in raw]
            common=[sum(row[a]for row in shifts)/2 for a in range(2)]
            offset=[offset[a]+common[a]for a in range(2)]
            records.append({'frame':i,'sharedTranslation':common,'relativeResiduals':[[row[a]-common[a]for a in range(2)]for row in shifts],'blendFrames':blend_frames})
        for actor in range(2):
            point=[raw[actor][i][a]-offset[a]for a in range(2)]
            for cut in records:
                age=i-cut['frame']
                if age<blend_frames:
                    t=age/blend_frames;fade=1-t*t*(3-2*t)
                    point=[point[a]-cut['relativeResiduals'][actor][a]*fade for a in range(2)]
            result[actor][i]=point
    return result,records
