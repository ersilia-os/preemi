# PREEMI de-identified dataset

`preemi_clean_deidentified.csv` is the cleaned PREEMI cohort used in the article: one row per pregnancy, 10,596 rows by 28 columns. It is produced from the private clean table (`data/processed/dr.csv`) by `src/deidentify_dataset.py`.

## De-identification

- Direct identifiers (`protocolid`, `personid`, `pr_id`, `ch_id`, `mt_id`) were removed earlier, during data preparation.
- Calendar dates were dropped: `Expected Due Date` and `Last Menstrual Period`. `Method of Determining Gestation` was dropped too because it is constant (LMP).
- Facility names in `Type of Delivery Place` were replaced with anonymous codes. Facilities with at least 20 births are `Site 01`, `Site 02`, … in order of descending size, and all others are `Other`. The key mapping codes to names is not shared.
- `Maternal Age` was bottom- and top-coded to 15–45 years.
- Rows keep the original order of the clean table, which is sorted by last menstrual period, so time-ordered splits can be reproduced. No dates are included.

## Columns

| Column | Description |
|---|---|
| Miscarriage | `Miscarriage` / `No miscarriage` |
| Outcome Death | `Live birth` / `Miscarriage or Stillbirth` |
| Early Neonatal Death | `Alive` / `Dead` (live births only) |
| Late Neonatal Death | `Alive` / `Dead` (survivors of the early neonatal period only) |
| Pre-term Delivery | `Preterm` / `Term` |
| Gestation | Gestational age at delivery, in days |
| Maternal Age | Years (15–45) |
| School Level | Categorical, as coded in the PREEMI codebook |
| Years of Education | Years (capped at 15) |
| Parity | Number of previous live births and stillbirths |
| Maternal Height | cm |
| Maternal Weight | kg |
| Antenatal Visits | Number of antenatal care visits |
| Delivery By | Categorical, as coded in the PREEMI codebook |
| Delivery Place | `Hospital`, `Clinic/Health Center`, `Home`, `Other` |
| Type of Delivery Place | Anonymised facility code (see above) |
| Mode of Delivery | `Vaginal` / `Cesarean` |
| Baby Sex | `Female` / `Male` |
| Multiple Birth | 0 = singleton, 1 = multiple |
| Birthweight | grams |
| Birthweight Measure | Time at which birthweight was measured |
| Neonatal Antibiotics, CPAP, Oxygen, Dexamethasone, Kangaroo Mother Care, Cord care Chlorhexidine, Bag and Mask Resuscitation | Treatment indicators coded 0/1/2, as in the PREEMI case report form |

Missing values are left empty. The modelling datasets used in the notebooks (`ml_d1_predelivery`, `ml_d2_earlydeath`, `ml_d3_latedeath`) are column and row subsets of this table, as defined in `notebooks/220724_NewModel_DataPreparation.ipynb`.
