from pathlib import Path

def fixture_marker(name):
    return 'do local _="ProjectYakuzaFixture:'+name+'" end\n'


def module_source(path):
    path=Path(path)
    text=path.read_text(encoding='utf-8')
    shared=path
    while shared.name!='lua'and shared!=shared.parent:shared=shared.parent
    assert shared.name=='lua',path
    base=shared/'shared/ProjectYakuza'
    dependencies=[]
    if path.name=='DragonOfDojima.lua':dependencies=[base/'BottleMoves.lua',base/'Y5ObjectMoves.lua',base/'BicycleMoves.lua',base/'BicycleHeatPaths.lua',base/'BatHeatPaths.lua',base/'KnifeHeatPaths.lua',base/'HeatSceneData.lua',base/'HeatScenes.lua',base/'WallHeatPaths.lua',base/'GroundHeatPaths.lua',base/'OpenGrabHeatPaths.lua',base/'OpenGrabHeatScene.lua',base/'GrabMotion.lua',base/'GrabMoves.lua',base/'RushEndingPaths.lua',base/'RushMove.lua',base/'CrateHeatMove.lua']
    elif path.name in ['HeatRushRules.lua','NetworkServer.lua','NetworkClient.lua']:dependencies=[base/'GroundHeatPaths.lua',base/'OpenGrabHeatPaths.lua',base/'QTEPlayback.lua',base/'GrabRules.lua',base/'RushEndingPaths.lua']
    elif path.name=='HeatRushUI.lua':dependencies=[shared/'client/ProjectYakuza/GrabCombat.lua']
    if path.name=='HeatActionPresentation.lua':dependencies.append(shared/'client/ProjectYakuza/OpenGrabHeatPresentation.lua')
    if path.name in ['Quicksteps.lua','HeatRush.lua','StyleEntry.lua']:dependencies.append(base/'ActionAnimation.lua')
    return ''.join('do\n'+p.read_text(encoding='utf-8')+'\nend\n'for p in dependencies)+text
