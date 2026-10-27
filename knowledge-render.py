"""Renders one knowledge folder (graph.json plus the per-repo markdown) into a self-contained index.html
for people to read. Usage: knowledge-render.py --root <folder basename> [--out <file>]"""
import argparse
import datetime
import html
import json
import os
import re
import sys

HARNESS_DIR = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(HARNESS_DIR, "skills", "knowledge-map", "template.html")


def inline(text):
    text = html.escape(text, quote=False)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    return re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)


def flow_block(markdown):
    sections = re.split(r"^## Flow\s*$", markdown, maxsplit=1, flags=re.M)
    if len(sections) == 1:
        return None
    section = re.split(r"^## ", sections[1], maxsplit=1, flags=re.M)[0]
    blocks = re.findall(r"```json\s*\n(.*?)\n\s*```", section, re.S)
    if not blocks:
        return None
    try:
        parsed = json.loads(blocks[0])
    except ValueError:
        return None
    if not isinstance(parsed, dict):
        return None
    if not isinstance(parsed.get("components"), list):
        return None
    if not isinstance(parsed.get("flows"), list):
        return None
    return {"components": parsed["components"], "flows": parsed["flows"]}


def notes_html(markdown):
    body = markdown.split("---", 2)[2] if markdown.startswith("---") else markdown
    body = re.split(r"^## (?:Flow|Edges)\s*$", body, maxsplit=1, flags=re.M)[0]
    out, paragraph, in_list = [], [], False

    def flush():
        if paragraph:
            out.append("<p>" + inline(" ".join(paragraph)) + "</p>")
            paragraph.clear()

    for line in body.splitlines():
        stripped = line.strip()
        if stripped.startswith("## "):
            flush()
            if in_list:
                out.append("</ul>")
                in_list = False
            out.append("<h3>" + inline(stripped[3:]) + "</h3>")
            continue
        if re.match(r"^\s*[-*] ", line):
            flush()
            if not in_list:
                out.append("<ul>")
                in_list = True
            out.append("<li>" + inline(re.sub(r"^\s*[-*] ", "", line)) + "</li>")
            continue
        if not stripped:
            flush()
            if in_list:
                out.append("</ul>")
                in_list = False
            continue
        if in_list:
            out[-1] = out[-1][:-5] + " " + inline(stripped) + "</li>"
            continue
        paragraph.append(stripped)
    flush()
    if in_list:
        out.append("</ul>")
    return "".join(out)


def repos_under(root_path):
    if not os.path.isdir(root_path):
        return []
    return sorted(name for name in os.listdir(root_path) if os.path.exists(os.path.join(root_path, name, ".git")))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True, help="folder basename under the knowledge dir, e.g. wisesight")
    parser.add_argument("--out")
    args = parser.parse_args()
    knowledge_dir = os.path.join(os.environ.get("CLAUDE_CONFIG_DIR") or os.path.expanduser("~/.claude"), "knowledge")
    folder = os.path.join(knowledge_dir, args.root)
    graph_path = os.path.join(folder, "graph.json")
    if not os.path.exists(graph_path):
        print(f"no graph at {graph_path}; scan the folder first", file=sys.stderr)
        return 1
    graph = json.load(open(graph_path))
    roots_path = os.path.join(knowledge_dir, "roots.json")
    roots = json.load(open(roots_path)).get("roots", []) if os.path.exists(roots_path) else []
    root_path = next((root for root in roots if os.path.basename(root) == args.root), "")
    mapped = {node["id"] for node in graph["nodes"]}
    notes, flows = {}, {}
    for node in graph["nodes"]:
        md_path = os.path.join(folder, node["id"] + ".md")
        if not os.path.exists(md_path):
            continue
        markdown = open(md_path).read()
        notes[node["id"]] = notes_html(markdown)
        flow = flow_block(markdown)
        if flow is not None:
            flows[node["id"]] = flow
    data = {
        "title": f"{args.root.capitalize()} Knowledge Map",
        "root": args.root,
        "rootPath": root_path,
        "rendered": datetime.date.today().isoformat(),
        "model": os.environ.get("KNOWLEDGE_MODEL", "opus"),
        "nodes": graph["nodes"],
        "edges": graph["edges"],
        "notes": notes,
        "flows": flows,
        "unmapped": [name for name in repos_under(root_path) if name not in mapped],
    }
    template = open(TEMPLATE).read()
    payload = json.dumps(data).replace("</", "<\\/")
    page = template.replace("__TITLE__", html.escape(data["title"])).replace("__DATA__", payload)
    out_path = args.out or os.path.join(folder, "index.html")
    with open(out_path, "w") as handle:
        handle.write(page)
    print(f"rendered {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
