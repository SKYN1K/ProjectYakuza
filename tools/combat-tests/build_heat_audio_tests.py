from pathlib import Path
w=Path(__file__).parent;m=w.parents[1]/"combat/ProjectYakuza/42/media/lua"
s=(w/"heat-audio-test-fixture.lua").read_text(encoding="utf-8")
s=s.replace("-- FEEDBACK\n","do\n"+(m/"client/ProjectYakuza/Feedback.lua").read_text(encoding="utf-8")+"\nend\n")
(w/"heat-audio-tests.lua").write_text(s,encoding="utf-8")
