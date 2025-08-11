#!/usr/bin/env python3
import os
import re
import matplotlib.pyplot as plt
from datetime import datetime

LOG_DIR = "logs"

def parse_logs():
    data = []
    pattern = re.compile(r"(Failover|Election|Rebalance).*: (\d+) ms")
    for filename in os.listdir(LOG_DIR):
        filepath = os.path.join(LOG_DIR, filename)
        with open(filepath, "r") as f:
            content = f.read()
        match = pattern.search(content)
        if match:
            metric_type = match.group(1)
            value = int(match.group(2))
            ts_str = filename.split("_")[-1].replace(".log", "")
            ts_date = "_".join(filename.split("_")[1:3]).replace(".log","")
            try:
                ts = datetime.strptime(ts_date, "%Y-%m-%d_%H-%M-%S")
            except:
                ts = datetime.now()
            data.append((metric_type, ts, value))
    return data

def plot_data(data):
    if not data:
        print("No data to plot.")
        return

    plt.figure(figsize=(10,6))
    metric_map = {}
    for metric_type, ts, value in data:
        metric_map.setdefault(metric_type, []).append((ts, value))

    for metric_type, values in metric_map.items():
        values.sort(key=lambda x: x[0])
        x = [v[0] for v in values]
        y = [v[1] for v in values]
        plt.plot(x, y, marker='o', label=metric_type)

    plt.title("Failover / Election / Rebalance Süreleri")
    plt.xlabel("Tarih")
    plt.ylabel("Süre (ms)")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(os.path.join(LOG_DIR, "failover_times.png"))
    plt.show()

if __name__ == "__main__":
    if not os.path.exists(LOG_DIR):
        print(f"Log klasörü '{LOG_DIR}' bulunamadı.")
    else:
        data = parse_logs()
        plot_data(data)
