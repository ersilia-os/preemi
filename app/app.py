import streamlit as st

st.title("PREEMI predictor")

# Inputs

stage = st.radio("Stage", options=["Day 0", "Pregnancy", "Delivery"])

maternal_age = st.radio("Maternal Age", options=[])
school_level = st.radio("School Level", options=[])
years_of_education = st.radio("Years of Education", options=[])
parity = st.radio("Parity", options=[])


variable_stages = {
    "Day0": [
        "Maternal Age",
        "School Level",
        "Years of Education",
        "Parity",
        "Gravida",
        "BMI",
        "Multiple Birth",
    ],
    "Pregnancy": ["Antenatal Visits"],
    "Delivery": [
        "Birthweight",
        "Method of Determining Gestation",
        "Last Menstrual Period",
        "Baby Sex",
        "Dexamethasone",
        "CPAP",
        "Oxygen",
        "Kangaroo Mother Care",
        "Cord care Chlorhexidine",
        "Bag and Mask Resuscitation",
        "Delivery Date",
    ],
}
