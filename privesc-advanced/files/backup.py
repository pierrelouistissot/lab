#!/usr/bin/env python3
import os
import utils

def main():
    utils.log(f"backup.py running as uid={os.geteuid()}")
    utils.do_backup()

if __name__ == "__main__":
    main()
