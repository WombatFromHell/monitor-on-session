#!/usr/bin/env python

import re
import shutil
import subprocess
import sys


def cmd_exists(cmd):
    return shutil.which(cmd) is not None


def strip_ansi(text):
    ansi_escape = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
    return ansi_escape.sub("", text)


def run_kscreen_doctor():
    # Run the command and capture the output
    if cmd_exists("kscreen-doctor"):
        result = subprocess.run(
            ["kscreen-doctor", "-o"], capture_output=True, text=True
        )
        return result.stdout
    else:
        print("kscreen-doctor not found!")
        exit(1)


def parse_modes(input):
    result = []
    modes_list = input.strip().split("Modes: ")[1]
    for mode in modes_list.strip().split("  "):
        mode_chunks = strip_ansi(mode).split(":")
        mode_id = mode_chunks[0].strip()
        mode_res = mode_chunks[1].strip()
        mode_active = False
        if "*!" in mode_res:
            mode_active = True
        result.append((mode_id, mode_res.split("*!")[0], mode_active))
    return result


def get_outputs(input):
    lines = input.split("\n")
    enabled = False
    connected = False
    output_id = None
    prio_num = None
    modes = None
    outputs = []

    for _, line in enumerate(lines):
        if "Output:" in line:
            chunks = line.strip().split()
            output_id = chunks[2]
            continue
        if "enabled" in line:
            enabled = True
            continue
        if enabled and "connected" in line:
            connected = True
            modes = None  # reset our modes state when entering a valid section
            continue
        if enabled and connected and "priority" in line:
            prio = line.strip().split()
            prio_num = strip_ansi(prio[1].strip())
            continue
        if enabled and connected and prio_num is not None and "Modes:" in line:
            modes = parse_modes(line)
            continue
        if enabled and connected and prio_num is not None and modes and "Vrr:" in line:
            vrr_enablement = line.strip().split(": ")[1]
            vrr_enabled = (
                True
                if "Automatic" in vrr_enablement or "Always" in vrr_enablement
                else False
            )
            outputs.append((output_id, prio_num, modes, vrr_enabled))

    return outputs


def find_ids(input, device, res):
    lines = input.split("\n")
    device_found = False
    enabled = False
    connected = False
    output_id = None
    mode_id = None

    for _, line in enumerate(lines):
        if "Output:" in line and device in line:
            device_found = True
            chunks = line.strip().split()
            output_id = chunks[2]
            continue
        if device_found and "enabled" in line:
            enabled = True
            continue
        if device_found and enabled and "connected" in line:
            connected = True
            continue
        if "Output:" in line:
            device_found = False
            enabled = False
            connected = False

        if device_found and connected and "Modes:" in line.strip():
            modes = line.strip()[7:].split()
            for mode in modes:
                parts = mode.split(":")
                if len(parts) == 2:
                    id, spec = parts
                    if res in spec:
                        mode_id = id
                        return (output_id, mode_id)
    return None


def help():
    print(f"{sys.argv[0]} < --current|--oid|--mid > [ OUTPUT ] [ WResxHRes@Hz ]")
    print("Output mode options are as follows:")
    print("\t--current\tReturn the output id of the primary monitor")
    print(
        "\t--vrr\t\tThe same as --current but also returns True/False if VRR is enabled on the output"
    )
    print("\t--oid\t\tOutput ID (if resolution is found)")
    print("\t--mid\t\tMode ID (if the resolution is found)")
    print("")
    exit(1)


def main():
    if not cmd_exists("kscreen-doctor"):
        print("Error: kscreen-doctor not found in the current PATH!")
        exit(1)

    if len(sys.argv) == 2:
        output_mode = sys.argv[1]
        input = run_kscreen_doctor()
        result = get_outputs(input)

        if result is None:
            print("Error: couldn't detect current primary output!")
            exit(1)

        if sys.argv[1] == "--current":
            for output in result:
                if output[1] == "1":
                    print(output[0])
        if sys.argv[1] == "--vrr":
            for output in result:
                print(output[0], output[3])
    elif len(sys.argv) == 4:
        output_mode = sys.argv[1]
        device = sys.argv[2]
        resolution = sys.argv[3]
        input = run_kscreen_doctor()

        result = find_ids(input, device, resolution)
        if result is not None and len(result) == 2:
            oid, mid = result
            if output_mode is not None and output_mode == "--oid":
                print(oid)
            elif output_mode is not None and output_mode == "--mid":
                print(mid)
            else:
                help()
        else:
            print("Error: couldn't find current monitor on that output!")
    else:
        help()


if __name__ == "__main__":
    main()
