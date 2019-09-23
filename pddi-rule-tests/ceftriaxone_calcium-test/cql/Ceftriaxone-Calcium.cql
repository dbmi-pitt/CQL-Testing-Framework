library "Ceftriaxone-Calcium" version '1.0'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers 

include CDS_Connect_Commons_for_FHIRv300 version '1.1.0' called C3F


// ## Code Systems ##

codesystem "RXNORM": 'http://www.nlm.nih.gov/research/umls/rxnorm'


valueset "Ceftriaxone VS": '2.16.840.1.113762.1.4.1213.15'
valueset "Calciums VS": '2.16.840.1.113762.1.4.1213.17'


parameter "Patient older than 28 days old" default true
parameter "Calcium administrated through IV" default true
// In same IV line
parameter "Simultaneous administration" default true
parameter InclusionMedicationsLookbackPeriod default 180 days

context Patient

define "Ceftriaxone":
  C3F.MedicationStatementLookBack([MedicationStatement: "Ceftriaxone VS"], 180 )

define "Calciums":
  C3F.MedicationStatementLookBack([MedicationStatement: "Calciums VS"], 180 days)

define "Ceftriaxone_1":
  exists("Ceftriaxone")

define "Calciums_1":
  exists("Calciums")

define "Under 28 days":
  AgeInDays() >= 1 and AgeInDays() <= 27

define "28 or older":
  AgeInDays() >= 28

define "Calcium not administrated through IV":
  not("Calcium administrated through IV")

// In same IV line
define "No simultaneous administration":
  not("Simultaneous administration")

define "MeetsInclusionCriteria":
  "Ceftriaxone_1"
  and "Calciums_1"

define "Patient under 28 days old":
  if "InPopulation" is not true then
    null
  else
  "Under 28 days"

define "Patient over 28 days old":
  if "InPopulation" is not true then
    null
  else
  "28 or older"

define "Calcium administrated IV":
  if "InPopulation" is not true then
    null
  else
  "Calcium administrated through IV"

define "Calcium not administrated IV":
  if "InPopulation" is not true then
    null
  else
  "Calcium not administrated through IV"

define "Simultaneous Administration":
  if "InPopulation" is not true then
    null
  else
  "Simultaneous administration"

define "No Simultaneous Administration":
  if "InPopulation" is not true then
    null
  else
  "No simultaneous administration"

define "InPopulation":
   "MeetsInclusionCriteria" 

define "Recommendation":
  if "Patient under 28 days old" then 'Avoid!'
  else if "Patient over 28 days old" and "Calcium not administrated IV" then 'No special precautions'
  else if "Patient over 28 days old" and "Calcium administrated IV" and "No Simultaneous Administration" then 'No special precautions'
  else if "Patient over 28 days old" and "Calcium administrated IV" and "Simultaneous Administration" then 'Avoid!'
  else null

define "Rationale":
  if "Patient under 28 days old" then 'Combination Incompatible.'
  else if "Patient over 28 days old" and "Calcium not administrated IV" then null
  else if "Patient over 28 days old" and "Calcium administrated IV" and "No Simultaneous Administration" then null
  else if "Patient over 28 days old" and "Calcium administrated IV" and "Simultaneous Administration" then 'Start another IV line'
  else null
define "Errors":
  null


// Added for testing purposes

define function ConceptText(c FHIR.CodeableConcept):
  Coalesce(c.text.value, Coalesce((c.coding) c2 return c2.display.value))

define function MedicationStatementDate(s FHIR.MedicationStatement):
  Coalesce(DateTimeText(s.effective as FHIR.dateTime), DateTimeText((s.effective as FHIR.Period)."start"))

define function DateTimeText(d FHIR.dateTime):
  ToString(d.value)

define CeftriaxoneMedicationStatements:
  C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Ceftriaxone VS"],
    InclusionMedicationsLookbackPeriod
  ))

define CalciumMedicationStatements:
  C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Calciums VS"],
    InclusionMedicationsLookbackPeriod
  ))

define ReportCeftriaxoneMedicationStatements:
  (CeftriaxoneMedicationStatements) S
  return {
    Type:  'Statement',
    Name:  ConceptText(S.medication as FHIR.CodeableConcept),
    Start: MedicationStatementDate(S),
    End:   DateTimeText((S.effective as FHIR.Period)."end"),
    Status: S.status.value
  }
  sort by Start desc, End desc

define ReportCalciumMedicationStatements:
  (CalciumMedicationStatements) S
  return {
    Type:  'Statement',
    Name:  ConceptText(S.medication as FHIR.CodeableConcept),
    Start: MedicationStatementDate(S),
    End:   DateTimeText((S.effective as FHIR.Period)."end"),
    Status: S.status.value
  }
  sort by Start desc, End desc

define HasRecentCeftriaxoneMedication:
  exists(C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Ceftriaxone VS"],
    InclusionMedicationsLookbackPeriod)
  ))
  and exists(C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Calciums VS"],
    InclusionMedicationsLookbackPeriod)
  ))

 define Summary: {
  Patient: {
    Name: Combine(Patient.name.given G return G.value, ' ') + ' ' + Combine(Patient.name.family F return F.value, ' '),
    Gender: Patient.gender.value,
    Age: AgeInYears()
  },
  ConcomitantDrugExposure: HasRecentCeftriaxoneMedication,
  HistoricalTreatments: {
    CeftriaxoneMedications: ReportCeftriaxoneMedicationStatements,
    CalciumMedications: ReportCalciumMedicationStatements
  }
}
