from __future__ import annotations

import contextlib
import os
from pathlib import Path


with open(os.devnull, "w") as devnull, contextlib.redirect_stderr(devnull):
    import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
INPUT_FILE = ROOT / "data" / "processed" / "dr.csv"
OUTPUT_DIR = ROOT / "data" / "deidentified"
OUTPUT_FILE = OUTPUT_DIR / "preemi_clean_deidentified.csv"
PRIVATE_DIR = ROOT / "data" / "private"
SITE_CODES_FILE = PRIVATE_DIR / "site_codes.csv"

DATE_COLUMNS = ["Expected Due Date", "Last Menstrual Period"]
CONSTANT_COLUMNS = ["Method of Determining Gestation"]
SITE_COLUMN = "Type of Delivery Place"
MIN_SITE_SIZE = 20
AGE_COLUMN = "Maternal Age"
AGE_MIN, AGE_MAX = 15, 45
QUASI_IDENTIFIERS = [
    "Maternal Age",
    "Parity",
    "School Level",
    "Type of Delivery Place",
    "Multiple Birth",
    "Mode of Delivery",
]


def recode_sites(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    counts = df[SITE_COLUMN].value_counts()
    large = counts[counts >= MIN_SITE_SIZE].index
    codes = {name: f"Site {i + 1:02d}" for i, name in enumerate(large)}
    mapping = pd.DataFrame({"facility": counts.index, "n": counts.values})
    mapping["code"] = mapping["facility"].map(codes).fillna("Other")
    df = df.copy()
    df[SITE_COLUMN] = df[SITE_COLUMN].map(codes).where(
        df[SITE_COLUMN].isna() | df[SITE_COLUMN].isin(large), "Other"
    )
    return df, mapping


def k_anonymity_report(df: pd.DataFrame) -> None:
    sizes = df.groupby(QUASI_IDENTIFIERS, dropna=False)[AGE_COLUMN].transform("size")
    print(f"k-anonymity on {', '.join(QUASI_IDENTIFIERS)}:")
    print(f"  records with k=1: {(sizes == 1).sum()} ({(sizes == 1).mean():.1%})")
    print(f"  records with k<5: {(sizes < 5).sum()} ({(sizes < 5).mean():.1%})")


def main() -> None:
    df = pd.read_csv(INPUT_FILE)
    df = df.drop(columns=DATE_COLUMNS + CONSTANT_COLUMNS)
    df, mapping = recode_sites(df)
    df[AGE_COLUMN] = df[AGE_COLUMN].clip(AGE_MIN, AGE_MAX)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    PRIVATE_DIR.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUTPUT_FILE, index=False)
    mapping.to_csv(SITE_CODES_FILE, index=False)

    print(f"Wrote {OUTPUT_FILE.relative_to(ROOT)}: {df.shape[0]} rows x {df.shape[1]} columns")
    print(f"Wrote private site mapping to {SITE_CODES_FILE.relative_to(ROOT)} (do not share)")
    k_anonymity_report(df)


if __name__ == "__main__":
    main()
