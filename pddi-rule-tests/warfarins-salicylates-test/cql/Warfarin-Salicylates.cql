library "Warfarin-Salicylates" version '1.0'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers 

include CDS_Connect_Commons_for_FHIRv300 version '1.1.0' called C3F 


codesystem "RXNORM": 'http://www.nlm.nih.gov/research/umls/rxnorm'


valueset "Warfarins VS": '2.16.840.1.113762.1.4.1213.8'
valueset "Topical Non Acetylated Salicylates VS": '2.16.840.1.113762.1.4.1213.26'
valueset "Non Acetylated Salicylates VS": '2.16.840.1.113762.1.4.1213.27'
valueset "Salicylates VS": '2.16.840.1.113762.1.4.1213.25'


parameter "Salicylate dose 3 grams/day or more" default true
parameter "Prevention of thromboembolic events?" default true
parameter InclusionMedicationsLookbackPeriod default 180 days

context Patient

define "Warfarins":
  exists(C3F.MedicationStatementLookBack([MedicationStatement: "Warfarins VS"], 180 days))

define "Topical Non Acetylated Salicylates":
  exists(C3F.MedicationStatementLookBack([MedicationStatement: "Topical Non Acetylated Salicylates VS"], 180 days))

define "Non Acetylated Salicylates":
  exists(C3F.MedicationStatementLookBack([MedicationStatement: "Non Acetylated Salicylates VS"], 180 days))

define "Salicylate dose 3 grams/day or more_1":
  not("Salicylate dose 3 grams/day or more")

define "Salicylates":
  exists(C3F.MedicationStatementLookBack([MedicationStatement: "Salicylates VS"], 180 days))

define "Prevention of thromboembolic events":
  "Prevention of thromboembolic events?"

define "No prevention of thromboembolic events":
  not("Prevention of thromboembolic events?")

define "MeetsInclusionCriteria":
  "Warfarins"

define "Topical Salicylate":
  if "InPopulation" is not true then
    null
  else
  "Topical Non Acetylated Salicylates"

define "Non Acetylated Salicylates ":
  if "InPopulation" is not true then
    null
  else
  "Non Acetylated Salicylates"

define "Salicylate dose >= 3 grams/day":
  if "InPopulation" is not true then
    null
  else
  "Salicylate dose 3 grams/day or more"

define "Salicylate dose < 3 grams/day":
  if "InPopulation" is not true then
    null
  else
  "Salicylate dose 3 grams/day or more_1"

define "Systemic - Aspirin":
  if "InPopulation" is not true then
    null
  else
  "Salicylates"

define "Prevention of thromboembolic events - yes":
  if "InPopulation" is not true then
    null
  else
  "Prevention of thromboembolic events"

define "Prevention of thromboembolic events - no":
  if "InPopulation" is not true then
    null
  else
  "No prevention of thromboembolic events"

define "InPopulation":
   "MeetsInclusionCriteria" 

define "Recommendation":
  if "Topical Salicylate" then 'No special precautions'
  else if "Non Acetylated Salicylates " and "Salicylate dose < 3 grams/day" then 'No special precautions'
  else if "Non Acetylated Salicylates " and "Salicylate dose >= 3 grams/day" then 'Use only if benefit outweighs risk'
  else if "Systemic - Aspirin" and "Prevention of thromboembolic events - no" then 'Use only if benefit outweighs risk'
  else if "Systemic - Aspirin" and "Prevention of thromboembolic events - yes" then 'No special precautions'
  else null

define "Rationale":
  if "Topical Salicylate" then 'Increased risk of bleeding unlikely'
  else if "Non Acetylated Salicylates " and "Salicylate dose < 3 grams/day" then 'Increased risk of bleeding unlikely'
  else if "Non Acetylated Salicylates " and "Salicylate dose >= 3 grams/day" then 'Increased risk of bleeding'
  else if "Systemic - Aspirin" and "Prevention of thromboembolic events - no" then 'Increased risk of bleeding'
  else if "Systemic - Aspirin" and "Prevention of thromboembolic events - yes" then 'Increased anti-coagulation desired'
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

define WarfarinMedicationStatements:
  C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Warfarins VS"],
    InclusionMedicationsLookbackPeriod
  ))

define TopicalSalicylateMedicationStatements:
  C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Topical Non Acetylated Salicylates VS"],
    InclusionMedicationsLookbackPeriod
  ))

define SalicylateMedicationStatements:
  C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Salicylates VS"],
    InclusionMedicationsLookbackPeriod
  ))

define ReportWarfarinMedicationStatements:
  (WarfarinMedicationStatements) S
  return {
    Type:  'Statement',
    Name:  ConceptText(S.medication as FHIR.CodeableConcept),
    Start: MedicationStatementDate(S),
    End:   DateTimeText((S.effective as FHIR.Period)."end"),
    Status: S.status.value
  }
  sort by Start desc, End desc

define ReportSalicylateMedicationStatements:
  (SalicylateMedicationStatements) S
  return {
    Type:  'Statement',
    Name:  ConceptText(S.medication as FHIR.CodeableConcept),
    Start: MedicationStatementDate(S),
    End:   DateTimeText((S.effective as FHIR.Period)."end"),
    Status: S.status.value
  }
  sort by Start desc, End desc

define ReportTopicalSalicylateMedicationStatements:
  (TopicalSalicylateMedicationStatements) S
  return {
    Type:  'Statement',
    Name:  ConceptText(S.medication as FHIR.CodeableConcept),
    Start: MedicationStatementDate(S),
    End:   DateTimeText((S.effective as FHIR.Period)."end"),
    Status: S.status.value
  }
  sort by Start desc, End desc

define HasRecentWarfarinMedication:
  exists(C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Warfarins VS"],
    InclusionMedicationsLookbackPeriod)
  ))
  and exists(C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Salicylates VS"],
    InclusionMedicationsLookbackPeriod)
  ))

 define Summary: {
  Patient: {
    Name: Combine(Patient.name.given G return G.value, ' ') + ' ' + Combine(Patient.name.family F return F.value, ' '),
    Gender: Patient.gender.value,
    Age: AgeInYears()
  },
  ConcomitantDrugExposure: HasRecentWarfarinMedication,
  HistoricalTreatments: {
    WarfarinMedications: ReportWarfarinMedicationStatements,
    SalicylateMedications: ReportSalicylateMedicationStatements
    // TopicalSalicylateMedications: ReportTopicalSalicylateMedicationStatements
  }
}
