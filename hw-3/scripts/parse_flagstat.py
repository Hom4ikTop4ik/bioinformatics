#!/usr/bin/env python3
"""
Parser for samtools flagstat output
Calculates mapping percentage and returns OK/pot OK/FAIL
"""

import re
import sys

def parse_flagstat(filename, ok_threshold=95, pot_threshold=80):
    """
    Parse flagstat file and return percentage of mapped reads
    """
    try:
        with open(filename, 'r') as f:
            content = f.read()
        
        # Look for the total mapped reads line
        # Format: "1700946 + 0 mapped (87.91% : N/A)"
        match = re.search(r'(\d+)\s+\+\s+0\s+mapped\s+\((\d+\.?\d*)%', content)
        
        if match:
            mapped_reads = int(match.group(1))
            percent = float(match.group(2))
            
            # Quality assessment
            if percent >= ok_threshold:
                status = "OK"
                status_icon = "✅"
            elif percent >= pot_threshold:
                status = "pot OK"
                status_icon = "⚠️"
            else:
                status = "FAIL"
                status_icon = "❌"
            
            # Print results
            print(f"\n{'='*40}")
            print(f"MAPPING RESULTS")
            print(f"{'='*40}")
            print(f"Mapped reads: {mapped_reads:,}")
            print(f"Mapping percentage: {percent}%")
            print(f"OK threshold: ≥{ok_threshold}%")
            print(f"POT OK threshold: ≥{pot_threshold}%")
            print(f"{'='*40}")
            print(f"STATUS: {status_icon} {status}")
            print(f"{'='*40}\n")
            
            # Additional information from flagstat
            proper_match = re.search(r'(\d+)\s+\+\s+0\s+properly paired\s+\((\d+\.?\d*)%', content)
            if proper_match:
                proper_percent = float(proper_match.group(2))
                print(f"Properly paired: {proper_percent}%")
            
            singleton_match = re.search(r'(\d+)\s+\+\s+0\s+singletons\s+\((\d+\.?\d*)%', content)
            if singleton_match:
                singleton_percent = float(singleton_match.group(2))
                print(f"Singletons: {singleton_percent}%")
            
            return percent, status
            
        else:
            print("ERROR: Could not find mapped reads line in flagstat output")
            return None, "ERROR"
            
    except FileNotFoundError:
        print(f"ERROR: File {filename} not found")
        return None, "ERROR"

if __name__ == "__main__":
    # Read command line arguments
    if len(sys.argv) < 2:
        print("Usage: python3 parse_flagstat.py <flagstat_file> [ok_threshold] [pot_threshold]")
        sys.exit(1)
    
    flagstat_file = sys.argv[1]
    ok_thresh = int(sys.argv[2]) if len(sys.argv) > 2 else 95
    pot_thresh = int(sys.argv[3]) if len(sys.argv) > 3 else 80
    
    parse_flagstat(flagstat_file, ok_thresh, pot_thresh)

