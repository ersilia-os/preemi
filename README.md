# PREEMI modeling

PREEMI dataset analysis and modeling at CIDRZ

This repository contains code to produce the models and figures related to the article "Machine Learning Algorithm for Prediction of Perinatal Mortality in Zambia" by Manasyan et al.

A de-identified version of the clean dataset is available in [`data/deidentified`](data/deidentified). Dates were removed, facility names were replaced with anonymous site codes, and extreme maternal ages were capped. See the [data README](data/deidentified/README.md) for details. The script that produces it is `src/deidentify_dataset.py`.

The source data needs to remain private, so some notebooks cannot be run end to end. If you need access to the source data, please request access to [this folder](https://drive.google.com/drive/folders/11H7lK9H4MRFMVk65gkbvRgGeDOYWeKwF?usp=sharing).