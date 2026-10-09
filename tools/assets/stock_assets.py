#!/usr/bin/env python3
"""Búsqueda y descarga CC0 desde APIs oficiales. Ver docs/16-assets-stock.md."""
import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from urllib.parse import urlencode, urlparse, unquote
from urllib.request import Request, urlopen

USER_AGENT = "BackroomsNOHO-StockAssets/1.0"
SOURCES = {
    "polyhaven": ("https://polyhaven.com/license", "https://polyhaven.com/our-api"),
    "ambientcg": ("https://docs.ambientcg.com/license/", "https://docs.ambientcg.com/api/v3/assets/"),
}


def request(url):
    if urlparse(url).scheme != "https":
        raise ValueError("Solo se aceptan URLs HTTPS")
    return urlopen(Request(url, headers={"User-Agent": USER_AGENT}), timeout=45)


def get_json(url):
    with request(url) as response:
        return json.load(response)


def catalog(provider, kind, query="", asset_id=None):
    if provider == "polyhaven":
        data = get_json("https://api.polyhaven.com/assets?" + urlencode({"t": kind}))
        return [dict(value, id=key) for key, value in data.items()
                if (key == asset_id if asset_id else
                    query.lower() in json.dumps(value, ensure_ascii=False).lower()
                    or query.lower() in key.lower())]
    params = {"type": "material" if kind == "textures" else "3d-model",
              "include": "downloads,title,url,dimensions", "limit": 20}
    params.update({"id": asset_id} if asset_id else {"q": query})
    return get_json("https://ambientcg.com/api/v3/assets?" + urlencode(params))["assets"]


def variants(provider, asset_id, metadata):
    if provider == "ambientcg":
        return {item["attributes"]: item for item in metadata["downloads"]}
    data = get_json("https://api.polyhaven.com/files/" + asset_id)
    result = {}

    def walk(node, parts):
        if isinstance(node, dict) and "url" in node:
            result["/".join(parts)] = node
        elif isinstance(node, dict):
            for key, value in node.items():
                walk(value, parts + [key])

    walk(data, [])
    return result


def download(entry, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    sha256 = hashlib.sha256()
    md5 = hashlib.md5()
    count = 0
    try:
        with request(entry["url"]) as response, destination.open("xb") as output:
            while chunk := response.read(1024 * 1024):
                count += len(chunk)
                if count > entry["size"]:
                    raise ValueError("La descarga supera el tamaño declarado")
                output.write(chunk)
                sha256.update(chunk)
                md5.update(chunk)
        if count != entry["size"]:
            raise ValueError("Tamaño de descarga incorrecto")
        if entry.get("md5") and md5.hexdigest() != entry["md5"]:
            raise ValueError("MD5 incorrecto")
    except Exception:
        # No borrar un archivo previo si open('xb') fue rechazado.
        if count and destination.exists():
            destination.unlink()
        raise
    return {"file": str(destination.name), "url": entry["url"],
            "bytes": count, "sha256": sha256.hexdigest(), "upstream_md5": entry.get("md5")}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["search", "files", "download"])
    parser.add_argument("provider", choices=SOURCES)
    parser.add_argument("--kind", choices=["models", "textures"], default="textures")
    parser.add_argument("--query", default="")
    parser.add_argument("--id")
    parser.add_argument("--variant", help="Valor literal mostrado por files")
    parser.add_argument("--out", type=Path, help="Directorio nuevo de staging")
    parser.add_argument("--max-mb", type=float, default=30, help="Límite de descarga con dependencias")
    args = parser.parse_args()
    if args.action != "search" and not args.id:
        parser.error("files y download requieren --id")
    records = catalog(args.provider, args.kind, args.query, args.id)
    if args.action == "search":
        for item in records[:20]:
            print(json.dumps({"id": item["id"], "name": item.get("name", item.get("title")),
                              "authors": item.get("authors"), "polycount": item.get("polycount")}, ensure_ascii=False))
        return
    if len(records) != 1:
        parser.error("ID no encontrado; comprobar --kind y repetir search")
    metadata = records[0]
    options = variants(args.provider, args.id, metadata)
    if args.action == "files":
        for key, entry in options.items():
            size = entry["size"] + sum(v["size"] for v in entry.get("include", {}).values())
            print(json.dumps({"variant": key, "bytes_with_dependencies": size, "url": entry["url"]}))
        return
    if not args.variant or not args.out:
        parser.error("download requiere --variant y --out")
    if args.variant not in options:
        parser.error("Variante inexistente; usar files y copiar el valor literal")
    entry = options[args.variant]
    name = Path(unquote(urlparse(entry["url"]).path)).name
    if args.provider == "ambientcg":
        name = args.id + "_" + args.variant + "." + entry["extension"]
    files = {name: entry, **entry.get("include", {})}
    size = sum(v["size"] for v in files.values())
    if size > args.max_mb * 1024 * 1024:
        parser.error(f"{size} bytes exceden --max-mb; elegir otra variante")
    for relative in files:
        path = PurePosixPath(relative)
        if path.is_absolute() or ".." in path.parts or "\\" in relative:
            parser.error("Ruta de dependencia no válida")
    args.out.mkdir(parents=True, exist_ok=False)
    evidence = {"provider": args.provider, "id": args.id, "variant": args.variant,
                "license": "CC0-1.0", "license_url": SOURCES[args.provider][0],
                "api_docs": SOURCES[args.provider][1],
                "asset_url": ("https://polyhaven.com/a/" if args.provider == "polyhaven"
                              else "https://ambientcg.com/a/") + args.id,
                "retrieved_at": datetime.now(timezone.utc).isoformat(),
                "metadata": metadata, "files": [], "status": "downloading"}
    manifest = args.out / "provenance.json"
    manifest.write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + "\n")
    for relative, item in files.items():
        record = download(item, args.out / relative)
        record["file"] = relative
        evidence["files"].append(record)
        manifest.write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + "\n")
    evidence["status"] = "downloaded_not_integrated"
    manifest.write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + "\n")
    print(f"{args.provider}: {args.id} → {args.out} ({size} bytes); registrar en assets/CREDITS.md al integrar")


if __name__ == "__main__":
    main()
