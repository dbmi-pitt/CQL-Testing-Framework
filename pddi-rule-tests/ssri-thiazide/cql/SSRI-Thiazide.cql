library "SSRI-and-Thiazide" version '1'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers 

include CDS_Connect_Commons_for_FHIRv300 version '1.1.0' called C3F 

include ReusableFunctions_FHIRv300 version '1.0.0' called RF

// include CDS_Connect_Conversions version '1' called Convert 

valueset "SSRIs and SNRIs VS": '2.16.840.1.113762.1.4.1213.33'
valueset "Thiazide and Thiazide like Diuretics VS": '2.16.840.1.113762.1.4.1213.61'
valueset "Sodium Concentration Lab Measurements VS": '2.16.840.1.113762.1.4.1213.80'
valueset "Amiodarones VS": '2.16.840.1.113762.1.4.1213.81'
valueset "ACEis and ARBs VS": '2.16.840.1.113762.1.4.1213.11'
valueset "NSAIDs VS": '2.16.840.1.113762.1.4.1213.9'
valueset "Antineoplastics VS": '2.16.840.1.113762.1.4.1213.62'
valueset "Antiepileptics VS": '2.16.840.1.113762.1.4.1213.56'
valueset "Risperidones VS": '2.16.840.1.113762.1.4.1213.60'
valueset "Quetiapines VS": '2.16.840.1.113762.1.4.1213.59'
valueset "Haloperidols VS": '2.16.840.1.113762.1.4.1213.63'
valueset "History of HIV/AIDS ICD10CM VS": '2.16.840.1.113762.1.4.1213.72'
valueset "History of HIV/AIDS SNOMED VS": '2.16.840.1.113762.1.4.1213.73'
valueset "History of Adrenal Insufficiency ICD10CM VS": '2.16.840.1.113762.1.4.1213.65'
valueset "History of Adrenal Insufficiency SNOMED VS": '2.16.840.1.113762.1.4.1213.66'
valueset "History of Adrenal Insufficiency ICD9CM VS": '2.16.840.1.113762.1.4.1213.64'
valueset "History of Heart Failure ICD9CM VS": '2.16.840.1.113762.1.4.1213.67'
valueset "History of Heart Failure SNOMED VS": '2.16.840.1.113762.1.4.1213.68'
valueset "History of Hepatic Cirrhosis ICD10CM VS": '2.16.840.1.113762.1.4.1213.70'
valueset "History of Hepatic Cirrhosis SNOMED VS": '2.16.840.1.113762.1.4.1213.71'
valueset "History of Hepatic Cirrhosis ICD9CM VS": '2.16.840.1.113762.1.4.1213.69'
valueset "History of Malignancy ICD10CM VS": '2.16.840.1.113762.1.4.1213.75'
valueset "History of Malignancy SNOMED VS": '2.16.840.1.113762.1.4.1213.76'
valueset "History of Malignancy ICD9CM VS": '2.16.840.1.113762.1.4.1213.74'
valueset "History of Pneumonia ICD9CM VS": '2.16.840.1.113762.1.4.1213.78'
valueset "History of Pneumonia SNOMED VS": '2.16.840.1.113762.1.4.1213.79'
valueset "History of Pneumonia ICD10CM VS": '2.16.840.1.113762.1.4.1213.77'

context Patient

define "Hyponatremia Drug Risk Valuesets":
  [MedicationStatement: "Amiodarones VS"]
  union [MedicationStatement: "ACEis and ARBs VS"]
  union [MedicationStatement: "NSAIDs VS"]
  union [MedicationStatement: "Antineoplastics VS"]
  union [MedicationStatement: "Antiepileptics VS"]
  union [MedicationStatement: "Risperidones VS"]
  union [MedicationStatement: "Quetiapines VS"]
  union [MedicationStatement: "Haloperidols VS"]

define "Hyponatremia Condition Risk Valuesets":
  [Condition: "History of HIV/AIDS ICD10CM VS"]
  union [Condition: "History of HIV/AIDS SNOMED VS"]
  union [Condition: "History of Adrenal Insufficiency ICD10CM VS"]
  union [Condition: "History of Adrenal Insufficiency SNOMED VS"]
  union [Condition: "History of Adrenal Insufficiency ICD9CM VS"]
  union [Condition: "History of Heart Failure ICD9CM VS"]
  union [Condition: "History of Heart Failure SNOMED VS"]
  union [Condition: "History of Hepatic Cirrhosis ICD10CM VS"]
  union [Condition: "History of Hepatic Cirrhosis SNOMED VS"]
  union [Condition: "History of Hepatic Cirrhosis ICD9CM VS"]
  union [Condition: "History of Malignancy ICD10CM VS"]
  union [Condition: "History of Malignancy SNOMED VS"]
  union [Condition: "History of Malignancy ICD9CM VS"]
  union [Condition: "History of Pneumonia ICD9CM VS"]
  union [Condition: "History of Pneumonia SNOMED VS"]
  union [Condition: "History of Pneumonia ICD10CM VS"]

define "SSRIs and SNRIs":
  exists(C3F.ActiveMedicationStatement([MedicationStatement: "SSRIs and SNRIs VS"]))

define "Thiazide and Thiazide like Diuretics":
  exists(C3F.ActiveMedicationStatement([MedicationStatement: "Thiazide and Thiazide like Diuretics VS"]))

define "Sodium Concentration <130 mmol/L":
  C3F.HighestObservation(C3F.ObservationLookBack([Observation: "Sodium Concentration Lab Measurements VS"], 7 days)) < 130 'mmol/L'


define "General Risk Factor Age >=65":
  AgeInYears() >= 65

define "General Risk Factor Female": 
  Patient.gender.value = 'female'

define "Hyponatremia Risk Drugs":
  exists(C3F.ActiveMedicationStatement("Hyponatremia Drug Risk Valuesets"))

define "Hyponatremia Risk Conditions":
  exists("Hyponatremia Condition Risk Valuesets")

define "No Recent Low Sodium Concentration":
  not("Sodium Concentration <130 mmol/L")

define "No General Risk Factor Age >=65":
  not("General Risk Factor Age >=65")

define "No General Risk Factor Female":
  not("General Risk Factor Female")

define "No Hyponatremia Risk Drugs":
  not("Hyponatremia Risk Drugs")

define "No Hyponatremia Risk Conditions":
  not("Hyponatremia Risk Conditions")

define "MeetsInclusionCriteria":
  "SSRIs and SNRIs"
  and "Thiazide and Thiazide like Diuretics"

define "Low Sodium Concentration":
  if "InPopulation" is not true then
    null
  else
  "Sodium Concentration <130 mmol/L"

define "Not Low Sodium Concentration":
  if "InPopulation" is not true then
    null
  else
  "No Recent Low Sodium Concentration"

define "Yes General Risks":
  if "InPopulation" is not true then
    null
  else
  "General Risk Factor Age >=65"
  or "General Risk Factor Female"

define "No General Risks":
  if "InPopulation" is not true then
    null
  else
  "No General Risk Factor Age >=65"
  and "No General Risk Factor Female"

define "Yes Hyponatremia Risks":
  if "InPopulation" is not true then
    null
  else
  "Hyponatremia Risk Drugs"
  or "Hyponatremia Risk Conditions"

define "No Hyponatremia Risks":
  if "InPopulation" is not true then
    null
  else
  "No Hyponatremia Risk Drugs"
  and "No Hyponatremia Risk Conditions"

define "InPopulation":
   "MeetsInclusionCriteria" 

define "Recommendation":
  if "Low Sodium Concentration" then 'Avoid concurrent if possible
If combination is used, monitor serum sodium'
  else if "Not Low Sodium Concentration" and "Yes General Risks" then 'Consider alternative
If combination is used, monitor serum sodium'
  else if "Not Low Sodium Concentration" and "No General Risks" and "Yes Hyponatremia Risks" then 'Consider alternative
If combination is used, monitor serum sodium'
  else if "Not Low Sodium Concentration" and "No Hyponatremia Risks" and "No General Risks" then ''
  else null

define "Rationale":
  if "Low Sodium Concentration" then 'Substantial risk of hyponatremia'
  else if "Not Low Sodium Concentration" and "Yes General Risks" then 'Increased risk of hyponatremia'
  else if "Not Low Sodium Concentration" and "No General Risks" and "Yes Hyponatremia Risks" then 'Likely increased risk of hyponatremia'
  else if "Not Low Sodium Concentration" and "No Hyponatremia Risks" and "No General Risks" then null
  else null

define "Classification":
  if "Low Sodium Concentration" then 'Avoid Combination'
  else if "Not Low Sodium Concentration" and "Yes General Risks" then 'Usually Avoid Combination'
  else if "Not Low Sodium Concentration" and "No General Risks" and "Yes Hyponatremia Risks" then 'Minimize Risk'
  else if "Not Low Sodium Concentration" and "No Hyponatremia Risks" and "No General Risks" then 'No Special Precautions'
  else null

define "Indicator":
  if "Low Sodium Concentration" then 'critical'
  else if "Not Low Sodium Concentration" and "Yes General Risks" then 'critical'
  else if "Not Low Sodium Concentration" and "No General Risks" and "Yes Hyponatremia Risks" then 'warning'
  else if "Not Low Sodium Concentration" and "No Hyponatremia Risks" and "No General Risks" then 'info'
  else null
define "Errors":
  null
