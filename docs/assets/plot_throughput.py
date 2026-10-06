"""Draw docs/assets/throughput.svg from the paper's means (20 runs per configuration).

Run from the repository root:
    uv run --with matplotlib python docs/assets/plot_throughput.py
"""
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

OUT = Path(__file__).with_name("throughput.svg")

HOSTS = ["x86", "Jetson", "Pi 5"]
LINKS = ["Ethernet", "Wi-Fi/GRE", "5G/WireGuard"]
# rows: hosts, columns: F1 links, Mb/s
DL = np.array([[99.4, 51.8, 76.2],
               [87.9, 45.3, 67.8],
               [61.8, 40.9, 47.2]])
UL = np.array([[22.6, 12.1, 18.9],
               [18.1, 13.5, 16.6],
               [15.4, 9.8, 12.4]])
MONO_DL, MONO_UL = 189.2, 26.4

# the percentages quoted in the README must match the data
assert [round(100 * DL[1, j] / DL[0, j], 1) for j in range(3)] == [88.4, 87.5, 89.0]
assert [round(100 * DL[i, 2] / DL[i, 0], 1) for i in range(3)] == [76.7, 77.1, 76.4]

rc = {"font.family": "serif", "font.serif": ["STIXGeneral", "DejaVu Serif"], "mathtext.fontset": "stix",
      "font.size": 9, "axes.linewidth": 0.6, "xtick.direction": "in", "ytick.direction": "in",
      "xtick.major.width": 0.6, "ytick.major.width": 0.6, "hatch.linewidth": 0.6}
with plt.rc_context(rc):
    fig, axes = plt.subplots(1, 2, figsize=(7.16, 2.6))
    x = np.arange(len(HOSTS))
    w = 0.26
    for ax, data, mono, label, top in ((axes[0], DL, MONO_DL, "Downlink (Mb/s)", 200),
                                       (axes[1], UL, MONO_UL, "Uplink (Mb/s)", 30)):
        for j, (link, face, hatch) in enumerate(zip(LINKS, ["0.25", "white", "0.85"], ["", "////", "...."])):
            ax.bar(x + (j - 1) * w, data[:, j], w, color=face, edgecolor="black", lw=0.6, hatch=hatch, label=link)
        ax.axhline(mono, color="black", ls=(0, (4, 2)), lw=0.8)
        ax.text(2.42, mono, f"monolithic {mono}", ha="right", va="bottom", fontsize=8)
        ax.set_xticks(x, HOSTS)
        ax.set_ylabel(label)
        ax.set_ylim(0, top * 1.06)
    handles, labels = axes[0].get_legend_handles_labels()
    fig.legend(handles, labels, ncols=3, fontsize=8, frameon=False, loc="upper center", bbox_to_anchor=(0.5, 1.06))
    axes[0].set_title("(a)", fontsize=9, y=-0.32)
    axes[1].set_title("(b)", fontsize=9, y=-0.32)
    fig.tight_layout(w_pad=2)
    fig.savefig(OUT, bbox_inches="tight", facecolor="white", metadata={"Date": None})

# drop the DOCTYPE line: some SVG hosts refuse DTDs
OUT.write_text(re.sub(r"<!DOCTYPE[^>]*>\s*", "", OUT.read_text(), count=1))
print(OUT)
