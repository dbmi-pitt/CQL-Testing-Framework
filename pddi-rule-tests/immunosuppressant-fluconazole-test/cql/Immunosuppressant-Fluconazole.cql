library "Immunosuppressant-Fluconazole" version '1'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers 

include CDS_Connect_Commons_for_FHIRv300 version '1.1.0' called C3F

codesystem "RXNORM": 'http://www.nlm.nih.gov/research/umls/rxnorm'


valueset "Fluconazoles VS": '2.16.840.1.113762.1.4.1213.19'
valueset "Immunosuppressants VS": '2.16.840.1.113762.1.4.1213.18'
valueset "Fluconazoles PO VS": '2.16.840.1.113762.1.4.1213.21'


// NOTE: This fixes the value at 100 rather than use a value from a Medication Statement
parameter "Dose of Fluconazole PO" default 100.0 'mg/d'
parameter InclusionMedicationsLookbackPeriod default 180 days

context Patient

define "Fluconazoles":
  C3F.MedicationStatementLookBack([MedicationStatement: "Fluconazoles VS"], 180 days)

define "Immunosuppressants":
  C3F.MedicationStatementLookBack([MedicationStatement: "Immunosuppressants VS"], 180 days)

define "Fluconazoles PO":
  C3F.MedicationStatementLookBack([MedicationStatement: "Fluconazoles PO VS"], 180 days)

define "18 years old":
  AgeInYears() >= 18

define "Fluconazoles_1":
  exists("Fluconazoles")

define "Immunosuppressants_1":
  exists("Immunosuppressants")

define "<18 years old":
  ("18 years old") is not true

define "Fluconazoles PO_1":
  exists("Fluconazoles PO")

define "High Dose of Fluconazole PO":
  "Dose of Fluconazole PO" >= 100 'mg/d'


define "Fluconazoles PO_2":
  exists("Fluconazoles PO")

// NOTE: This fixes the value at 100 rather than use a value from a Medication Statement
define "Low Dose of Fluconazole PO":
  "Dose of Fluconazole PO" < 100 'mg/d'


define "MeetsInclusionCriteria":
  "Fluconazoles_1"
  and "Immunosuppressants_1"

define "Immunosuppressant - Fluconazole -- Patient < 18 years old":
  if "InPopulation" is not true then
    null
  else
  "<18 years old"

define "Immunosuppressant - Fluconazole -- Patient > 18 years old, High dose oral fluconazole":
  if "InPopulation" is not true then
    null
  else
  "18 years old"
  and "Fluconazoles PO_1"
  and "High Dose of Fluconazole PO"

define "Immunosuppressant - Fluconazole -- Patient > 18 years old, Low dose oral fluconazole":
  if "InPopulation" is not true then
    null
  else
  "18 years old"
  and "Fluconazoles PO_2"
  and "Low Dose of Fluconazole PO"

define "InPopulation":
   "MeetsInclusionCriteria" 

define "Recommendation":
  if "Immunosuppressant - Fluconazole -- Patient < 18 years old" then 'Monitor immunosuppressant levels. Use only if benefit outweighs risk.'
  else if "Immunosuppressant - Fluconazole -- Patient > 18 years old, High dose oral fluconazole" then 'Monitor immunosuppressant levels. Use only if benefit outweighs risk.'
  else if "Immunosuppressant - Fluconazole -- Patient > 18 years old, Low dose oral fluconazole" then 'Monitor immunosuppressant levels. No special precautions'
  else null

define "Rationale":
  if "Immunosuppressant - Fluconazole -- Patient < 18 years old" then 'Increased risk of immunosuppressant toxicity likely'
  else if "Immunosuppressant - Fluconazole -- Patient > 18 years old, High dose oral fluconazole" then 'Increased risk of immunosuppressant toxicity likely'
  else if "Immunosuppressant - Fluconazole -- Patient > 18 years old, Low dose oral fluconazole" then 'Increased risk of immunosuppressant toxicity unlikely'
  else null
define "Errors":
  if null then
    {''}
  else null


// Added for testing purposes

define function ConceptText(c FHIR.CodeableConcept):
  Coalesce(c.text.value, Coalesce((c.coding) c2 return c2.display.value))

define function MedicationStatementDate(s FHIR.MedicationStatement):
  Coalesce(DateTimeText(s.effective as FHIR.dateTime), DateTimeText((s.effective as FHIR.Period)."start"))

define function DateTimeText(d FHIR.dateTime):
  ToString(d.value)

define FluconazolesMedicationStatements:
  C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Fluconazoles VS"],
    InclusionMedicationsLookbackPeriod
  ))

define ImmunosuppressantMedicationStatements:
  C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Immunosuppressants VS"],
    InclusionMedicationsLookbackPeriod
  ))

define ReportFluconazolesMedicationStatements:
  (FluconazolesMedicationStatements) S
  return {
    Type:  'Statement',
    Name:  ConceptText(S.medication as FHIR.CodeableConcept),
    Start: MedicationStatementDate(S),
    End:   DateTimeText((S.effective as FHIR.Period)."end"),
    Status: S.status.value
  }
  sort by Start desc, End desc

define ReportImmunosuppressantMedicationStatements:
  (ImmunosuppressantMedicationStatements) S
  return {
    Type:  'Statement',
    Name:  ConceptText(S.medication as FHIR.CodeableConcept),
    Start: MedicationStatementDate(S),
    End:   DateTimeText((S.effective as FHIR.Period)."end"),
    Status: S.status.value
  }
  sort by Start desc, End desc

define HasRecentFluconazolesMedication:
  exists(C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Fluconazoles VS"],
    InclusionMedicationsLookbackPeriod)
  ))
  and exists(C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Immunosuppressants VS"],
    InclusionMedicationsLookbackPeriod)
  ))

 define Summary: {
  Patient: {
    Name: Combine(Patient.name.given G return G.value, ' ') + ' ' + Combine(Patient.name.family F return F.value, ' '),
    Gender: Patient.gender.value,
    Age: AgeInYears()
  },
  ConcomitantDrugExposure: HasRecentFluconazolesMedication,
  HistoricalTreatments: {
    FluconazolesMedications: ReportFluconazolesMedicationStatements,
    ImmunosuppressantMedications: ReportImmunosuppressantMedicationStatements
  }
}
