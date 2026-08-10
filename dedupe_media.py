import os
import hashlib
import csv
import time
import argparse
from tqdm import tqdm
from PIL import Image
import imagehash

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".heic", ".tif", ".tiff"}
VIDEO_EXTENSIONS = {".mp4", ".mov", ".avi", ".mkv", ".wmv", ".flv", ".mts", ".m2ts"}

PHASH_THRESHOLD = 5


# -------------------------------
# Hashing
# -------------------------------
def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def phash(path):
    try:
        img = Image.open(path)
        return imagehash.phash(img)
    except Exception:
        return None


# -------------------------------
# Generic scoring system
# -------------------------------
def compute_score(path, filename_rules, folder_rules, priority_folders):
    score = 0
    lower = path.lower()

    # Priority folders → lower score = more important
    for pf in priority_folders:
        if pf.lower() in lower:
            score -= 10

    # Folder specificity rules
    for rule in folder_rules:
        key, val = rule.split("=")
        if key.lower() in lower:
            score += int(val)

    # Filename specificity rules
    name = os.path.basename(path).lower()
    for rule in filename_rules:
        key, val = rule.split("=")
        if key.lower() in name:
            score += int(val)

    return score


# -------------------------------
# Choose which file to delete
# -------------------------------
def choose_delete(path1, path2, filename_rules, folder_rules, priority_folders):
    s1 = compute_score(path1, filename_rules, folder_rules, priority_folders)
    s2 = compute_score(path2, filename_rules, folder_rules, priority_folders)

    if s1 < s2:
        return path1
    if s2 < s1:
        return path2
    return ""


# -------------------------------
# Main
# -------------------------------
def main():
    parser = argparse.ArgumentParser(description="Generic photo/video dedupe scanner")

    parser.add_argument("--type", choices=["photo", "video"], required=True,
                        help="Choose whether to scan photos or videos")

    parser.add_argument("--root", required=True,
                        help="Root directory to scan")

    parser.add_argument("--output", default="dedupe_results.csv",
                        help="CSV output file path")

    parser.add_argument("--delete", action="store_true",
                        help="Delete chosen duplicates")

    parser.add_argument("--deep", action="store_true",
                        help="Enable perceptual hashing (pHash) for photos")

    parser.add_argument("--folders", nargs="*", help="Top-level folders to scan")

    parser.add_argument("--exclude-folders", nargs="*", default=[],
                        help="Folder names to exclude")

    parser.add_argument("--filename-specificity", nargs="*", default=[],
                        help="Rules like IMG_=1 DSC=1 2020-=5")

    parser.add_argument("--folder-specificity", nargs="*", default=[],
                        help="Rules like screenshots=1 random=0 honeymoon=5")

    parser.add_argument("--priority-folders", nargs="*", default=[],
                        help="Folders that should be preserved (lower score)")

    args = parser.parse_args()

    ROOT = args.root
    OUTPUT = args.output

    start_time = time.time()

    seen_sha = {}
    seen_phash = []
    rows = []

    all_files = []

    # -------------------------------
    # Build file list
    # -------------------------------
    for folder, _, files in os.walk(ROOT):
        folder_lower = folder.lower()

        # Exclusions
        if any(ex.lower() in folder_lower for ex in args.exclude_folders):
            continue

        for name in files:
            ext = os.path.splitext(name.lower())[1]

            if args.type == "photo" and ext not in IMAGE_EXTENSIONS:
                continue
            if args.type == "video" and ext not in VIDEO_EXTENSIONS:
                continue

            full_path = os.path.join(folder, name)
            full_lower = full_path.lower()

            if any(ex.lower() in full_lower for ex in args.exclude_folders):
                continue

            # Determine top-level folder
            rel = os.path.relpath(full_path, ROOT)
            top = rel.split(os.sep)[0]

            # Folder filter
            if args.folders and top not in args.folders:
                continue

            all_files.append(full_path)

    tqdm.write(f"Total files to scan: {len(all_files)}")

    last_top = None

    # -------------------------------
    # Process each file
    # -------------------------------
    for path in tqdm(all_files, desc="Scanning", unit="file"):
        rel = os.path.relpath(path, ROOT)
        top = rel.split(os.sep)[0]

        if top != last_top:
            tqdm.write(f"--- Now scanning top-level folder: {top} ---")
            last_top = top

        reason = None
        original = None
        to_delete = ""
        deleted_flag = "NO"

        # -------------------------------
        # Tier 1: SHA-256 exact duplicates
        # -------------------------------
        try:
            h = sha256(path)
            if h in seen_sha:
                original = seen_sha[h]
                reason = "SHA256_MATCH"
                to_delete = choose_delete(
                    path, original,
                    args.filename_specificity,
                    args.folder_specificity,
                    args.priority_folders
                )
            else:
                seen_sha[h] = path

        except Exception as e:
            tqdm.write(f"Error hashing {path}: {e}")
            continue

        # -------------------------------
        # Tier 2: pHash visual duplicates (photos only)
        # -------------------------------
        if args.type == "photo" and args.deep and reason is None:
            ph = phash(path)
            if ph is not None:
                for (other_path, other_ph) in seen_phash:
                    dist = ph - other_ph
                    if dist <= PHASH_THRESHOLD:
                        original = other_path
                        reason = f"PHASH_MATCH(dist={dist})"
                        to_delete = choose_delete(
                            path, original,
                            args.filename_specificity,
                            args.folder_specificity,
                            args.priority_folders
                        )
                        break

                seen_phash.append((path, ph))

        # -------------------------------
        # If duplicate found
        # -------------------------------
        if reason:
            if args.delete and to_delete:
                try:
                    os.remove(to_delete)
                    deleted_flag = "YES"
                except Exception as e:
                    tqdm.write(f"Error deleting {to_delete}: {e}")
                    deleted_flag = "NO"

            rows.append((path, original, reason, to_delete, deleted_flag))

    # -------------------------------
    # Write CSV
    # -------------------------------
    tqdm.write(f"\nWriting CSV to {OUTPUT}")
    with open(OUTPUT, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["duplicate", "original", "reason", "to_delete", "deleted"])
        writer.writerows(rows)

    elapsed = time.time() - start_time
    tqdm.write(f"\nTime elapsed: {elapsed/60:.2f} minutes")
    tqdm.write("Done.")


if __name__ == "__main__":
    main()
