import json
from pprint import pformat


with open("./catalog_strchive.json") as file:
    catalog = json.load(file)
    for entry in catalog:
        entry["LocusId"] = entry["LocusId"].split("_")[-1]
    catalog = sorted(catalog, key=lambda it: it["LocusId"])


with open("./catalog_strchive.cleaned.json", "w") as file:
    print(json.dumps(catalog, indent=4), file=file)
