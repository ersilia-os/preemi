from __future__ import annotations

import contextlib
import os
import subprocess
from pathlib import Path


with open(os.devnull, "w") as devnull, contextlib.redirect_stderr(devnull):
    import pandas as pd


DATASET_NAMES = [
    "ml_d1_predelivery",
    "ml_d2_earlydeath",
    "ml_d3_latedeath",
]

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data" / "processed"
RESULTS_DIR = ROOT / "results"
HTML_OUTPUT = RESULTS_DIR / "supplementary_tables_rebuttal.html"
RTF_OUTPUT = RESULTS_DIR / "supplementary_tables_rebuttal.rtf"
DOCX_OUTPUT = RESULTS_DIR / "supplementary_tables_rebuttal.docx"


def add_common_column_stats(summary: pd.DataFrame, df: pd.DataFrame) -> pd.DataFrame:
    summary = summary.copy()
    summary.index.name = "column"
    summary["dtype"] = df[summary.index].dtypes.astype(str)
    summary["missing_n"] = df[summary.index].isna().sum()
    summary["missing_pct"] = (df[summary.index].isna().mean() * 100).round(2)
    summary["non_missing_n"] = df[summary.index].notna().sum()
    summary["unique_n"] = df[summary.index].nunique(dropna=True)
    return summary


def describe_numeric_for_ml(df: pd.DataFrame) -> pd.DataFrame:
    numeric_df = df.select_dtypes(include="number")
    if numeric_df.empty:
        return pd.DataFrame()

    summary = add_common_column_stats(numeric_df.describe().T, df)
    ordered_columns = [
        "dtype",
        "non_missing_n",
        "missing_n",
        "missing_pct",
        "unique_n",
        "count",
        "mean",
        "std",
        "min",
        "25%",
        "50%",
        "75%",
        "max",
    ]
    return summary.reindex(columns=ordered_columns)


def describe_categorical_for_ml(df: pd.DataFrame) -> pd.DataFrame:
    categorical_df = df.select_dtypes(exclude="number")
    if categorical_df.empty:
        return pd.DataFrame()

    summary = add_common_column_stats(categorical_df.describe().T, df)
    ordered_columns = [
        "dtype",
        "non_missing_n",
        "missing_n",
        "missing_pct",
        "unique_n",
        "count",
        "top",
        "freq",
    ]
    return summary.reindex(columns=ordered_columns)


def format_value(value: object) -> str:
    if pd.isna(value):
        return ""
    if isinstance(value, float):
        return f"{value:.2f}"
    return str(value)


def escape_rtf(text: object) -> str:
    value = format_value(text)
    value = value.replace("\\", r"\\").replace("{", r"\{").replace("}", r"\}")
    return "".join(char if ord(char) < 128 else rf"\u{ord(char)}?" for char in value)


def dataframe_to_rtf_table(df: pd.DataFrame) -> str:
    if df.empty:
        return r"\pard\fs18\i No variables of this type were found in this dataset.\i0\par"

    headers = ["column"] + list(df.columns)
    rows = [headers] + [[index, *row.tolist()] for index, row in df.iterrows()]
    total_width = 15120
    col_width = max(900, total_width // len(headers))
    cell_positions = [col_width * (i + 1) for i in range(len(headers))]

    table_parts = [r"\pard\fs16"]
    for row_idx, row in enumerate(rows):
        table_parts.append(r"\trowd\trgaph60\trleft0")
        for position in cell_positions:
            table_parts.append(
                rf"\clbrdrt\brdrs\brdrw10"
                rf"\clbrdrl\brdrs\brdrw10"
                rf"\clbrdrb\brdrs\brdrw10"
                rf"\clbrdrr\brdrs\brdrw10"
                rf"\cellx{position}"
            )
        for value in row:
            if row_idx == 0:
                table_parts.append(rf"\intbl\b {escape_rtf(value)}\b0\cell")
            else:
                table_parts.append(rf"\intbl {escape_rtf(value)}\cell")
        table_parts.append(r"\row")
    table_parts.append(r"\pard\par")
    return "".join(table_parts)


def build_rtf_document() -> str:
    parts = [
        r"{\rtf1\ansi\deff0",
        r"{\fonttbl{\f0 Arial;}}",
        r"\paperw15840\paperh12240\margl720\margr720\margt720\margb720\landscape",
        r"\fs22",
        r"\pard\b Supplementary Tables S1-S6\b0\par",
        (
            r"\pard\sa120 Legend. These supplementary tables describe the machine-learning "
            r"datasets used in the rebuttal analysis. Numeric variables are summarized by data "
            r"type, non-missing count, missing count, missing percentage, number of unique "
            r"observed values, count, mean, standard deviation, quartiles, and range. "
            r"Categorical variables are summarized by data type, non-missing count, missing "
            r"count, missing percentage, number of unique observed values, count, most frequent "
            r"category (top), and its frequency (freq). Missing percentage was computed as the "
            r"proportion of rows with missing values in each column.\par"
        ),
    ]

    table_number = 1
    for dataset_name in DATASET_NAMES:
        df = pd.read_csv(DATA_DIR / f"{dataset_name}.csv")
        numeric_summary = describe_numeric_for_ml(df)
        categorical_summary = describe_categorical_for_ml(df)

        parts.append(
            rf"\pard\sb180\sa120\b Table S{table_number}. Numeric variables in {escape_rtf(dataset_name)}\b0\par"
        )
        parts.append(dataframe_to_rtf_table(numeric_summary))
        table_number += 1

        parts.append(
            rf"\pard\sb180\sa120\b Table S{table_number}. Categorical variables in {escape_rtf(dataset_name)}\b0\par"
        )
        parts.append(dataframe_to_rtf_table(categorical_summary))
        table_number += 1

    parts.append("}")
    return "".join(parts)


def main() -> None:
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    RTF_OUTPUT.write_text(build_rtf_document(), encoding="utf-8")

    subprocess.run(
        [
            "textutil",
            "-convert",
            "docx",
            str(RTF_OUTPUT),
            "-output",
            str(DOCX_OUTPUT),
        ],
        check=True,
    )

    print(DOCX_OUTPUT)


if __name__ == "__main__":
    main()
