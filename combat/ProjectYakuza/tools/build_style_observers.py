



from pathlib import Path
import argparse
import copy
import re
import xml.etree.ElementTree as ET

STAMP = b"ProjectYakuza observer builder: code only"


def lua(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return '"' + ''.join('\\\\' if c == '\\' else '\\"' if c == '"' else ('\\%03d' % ord(c)) if ord(c) < 32 else c for c in value) + '"'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return "{" + ",".join(lua(v) for v in value) + "}"
    return "{" + ",".join("[" + lua(k) + "]=" + lua(v) for k, v in value.items()) + "}"


def build(mod_root, style_id, prefix, dry_run=False):
    assert re.fullmatch(r"[\w.-]+", style_id, re.ASCII), "Invalid style ID"
    assert re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*_", prefix), "Prefix must be a unique ASCII identifier ending in _"
    media = Path(mod_root).resolve() / "42/media"
    assert media.is_dir(), "Expected addon root containing 42/media"
    outputs, records, ids = {}, [], set()
    for group in ("melee", "stomp", "actions"):
        for source in sorted((media / "AnimSets/player" / group).glob(prefix + "*.xml")):
            if source.read_bytes().find(STAMP) >= 0:
                continue
            node = ET.parse(source).getroot()
            identifier, animation = node.findtext("m_Name"), node.findtext("m_AnimName")
            assert identifier and re.fullmatch(r"[A-Za-z][A-Za-z0-9_.-]*", identifier) and identifier.startswith(prefix) and animation, source
            assert identifier not in ids, "Duplicate owner node name: " + identifier
            ids.add(identifier)
            conditions = [{"name": c.findtext("m_Name"), "value": c.findtext("m_Value")} for c in node.findall("m_Conditions")]
            assert conditions and all(c["name"] and c["value"] for c in conditions), source


            for c in node.findall("m_Conditions"):
                assert c.findtext("m_Type") in ("BOOL", "STRING"), "Only BOOL/STRING conditions supported: " + str(source)
                assert set(child.tag for child in c) <= {"m_Name", "m_Type", "m_Value"}, "Unsupported condition operator"
            assert not node.findall("m_2DBlends"), "Blend trees require hand-authored observer support"
            records.append({"id": identifier, "animation": animation, "group": group,
                            "loop": node.findtext("m_Looped") == "true", "priority": int(node.findtext("m_ConditionPriority") or 0), "conditions": conditions})
            for target_group in (("actions", group) if group != "actions" else ("actions",)):
                for cycle in ("0", "1"):
                    observer = copy.deepcopy(node)
                    for tag in ("m_Conditions", "m_Events"):
                        for child in list(observer.findall(tag)):
                            observer.remove(child)
                    name = prefix + "Observer_" + target_group + "_" + identifier + "_" + cycle
                    observer.find("m_Name").text = name
                    for tag, value in (("m_Priority", "9"), ("m_ConditionPriority", "500")):
                        element = observer.find(tag)
                        if element is None:
                            element = ET.SubElement(observer, tag)
                        element.text = value
                    for cname, ctype, value in (("ProjectYakuzaRemoteObserver", "BOOL", "true"),
                                               ("ProjectYakuzaRemoteClip", "STRING", identifier),
                                               ("ProjectYakuzaRemoteCycle", "STRING", cycle)):
                        condition = ET.SubElement(observer, "m_Conditions")
                        for k, v in (("m_Name", cname), ("m_Type", ctype), ("m_Value", value)):
                            ET.SubElement(condition, k).text = v
                    destination = media / "AnimSets/player" / target_group / (name + ".xml")
                    outputs[destination] = b'<?xml version="1.0" encoding="utf-8"?>\n<?ProjectYakuzaObserver ' + STAMP + b'?>\n' + ET.tostring(observer, encoding="utf-8") + b"\n"
    assert records, "No matching owner nodes found"
    records.sort(key=lambda r: (-r["priority"], r["id"]))
    module = media / "lua/shared" / (prefix + "Network.lua")
    outputs[module] = ("local _=" + lua(STAMP.decode()) + "\nrequire \"ProjectYakuza/NetworkExtensions\"\nrequire \"" + prefix + "Style\"\nProjectYakuza.registerNetworkAnimations(" + lua(style_id) + "," + lua(records) + ")\n").encode("utf-8")


    for path in outputs:
        assert not path.exists() or STAMP in path.read_bytes(), "Refusing to overwrite author file: " + str(path)
    if not dry_run:
        for path, data in outputs.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
    return records, outputs


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build addon observer nodes and registration from supplied native owner nodes.")
    parser.add_argument("--mod-root", required=True, type=Path)
    parser.add_argument("--style-id", required=True)
    parser.add_argument("--prefix", required=True, help="Owner XML names and shared style module must start with this prefix (e.g. ExampleStyle_)")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    records, outputs = build(args.mod_root, args.style_id, args.prefix, args.dry_run)
    print(("Would write" if args.dry_run else "Wrote"), len(outputs), "code files for", len(records), "owner nodes")
