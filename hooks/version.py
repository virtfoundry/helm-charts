"""Replace @@VERSION@@ in docs with the chart appVersion."""
import pathlib
import yaml

VERSION = yaml.safe_load(pathlib.Path("charts/virtfoundry/Chart.yaml").read_text())["appVersion"]


def on_page_markdown(markdown, **_):
    return markdown.replace("@@VERSION@@", VERSION)
