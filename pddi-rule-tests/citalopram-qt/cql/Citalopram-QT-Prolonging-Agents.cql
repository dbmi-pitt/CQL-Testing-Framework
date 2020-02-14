library "Citalopram-QT-Prolonging-Agents" version '1.0'
// ./cql-to-elm/build/install/cql-to-elm/bin/cql-to-elm  --format=JSON --input /Users/erc53/Github/CQL-Testing-Framework/pddi-rule-tests/citalopram-qt/cql/Citalopram-QT-Prolonging-Agents.cql   --output /Users/erc53/Github/CQL-Testing-Framework/pddi-rule-tests/citalopram-qt/cql/

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers

include CDS_Connect_Commons_for_FHIRv300 version '1.1.0' called C3F

include ReusableFunctions_FHIRv300 version '1.0.0' called RF

// include CDS_Connect_Conversions version '1' called Convert

codesystem "RXNORM": 'http://www.nlm.nih.gov/research/umls/rxnorm'

valueset "Citaloprams VS": '2.16.840.1.113762.1.4.1213.3'
valueset "QT Prolonging Agents VS": '2.16.840.1.113762.1.4.1213.4'


context Patient
// ----- BEGIN MANUAL ADDITION -----
define "Report Citaloprams":
    "Citaloprams" S
        return {
            // Type:  'Statement',
            Name:  RF.ConceptText(S.medication as FHIR.CodeableConcept),
            Start: RF.MedicationStatementDate(S),
            End:   RF.DateTimeText((S.effective as FHIR.Period)."end"),
            Status: S.status.value,
            Dosage: RF.QuantityText(S.dosage[0].dose as FHIR.Quantity),
            DailyDosage: ToString(S.dosage[0].dose.value * S.dosage[0].maxDosePerPeriod.numerator.value) + ' mg/d'
        }
        sort by Start desc, End desc

define "Report QT Prolonging Agents":
    "QT Prolonging Agents" S
        return {
            Type:  'Statement',
            Name:  RF.ConceptText(S.medication as FHIR.CodeableConcept),
            Start: RF.MedicationStatementDate(S),
            End:   RF.DateTimeText((S.effective as FHIR.Period)."end"),
            Status: S.status.value
        }
        sort by Start desc, End desc

define "Basic Concomitant Exposure":
  "Citaloprams Exists"
  and "QT Prolonging Agents Exists"

// ----- END MANUAL ADDITION -----
define "Citaloprams":
  [MedicationStatement: "Citaloprams VS"]

define "QT Prolonging Agents":
  [MedicationStatement: "QT Prolonging Agents VS"]

// Dosage >= 60 mg/d
define "High Dosage Citaloprams Exist":
  System.Quantity { value: "Citaloprams".dosage[0].dose.value * "Citaloprams".dosage[0].maxDosePerPeriod.numerator.value, unit: 'mg/d' } >= 60 'mg/d'


define "QT Prolonging Agents Exists":
  exists("QT Prolonging Agents")

// Dosage < 60 mg/d
define "Not High Dosage Citaloprams Exist":
  System.Quantity { value: "Citaloprams".dosage[0].dose.value * "Citaloprams".dosage[0].maxDosePerPeriod.numerator.value, unit: 'mg/d' } < 60 'mg/d'

define "Citaloprams Exists":
  exists("Citaloprams")

define "QT Prolonging Agents Not Exist":
  not("QT Prolonging Agents Exists")

define "MeetsInclusionCriteria":
  "Citaloprams Exists"

define "Citalopram High Dosage, QT":
  if "InPopulation" is not true then
    null
  else
  "QT Prolonging Agents Exists"
  and "High Dosage Citaloprams Exist"

define "Citalopram High Dosage, No QT":
  if "InPopulation" is not true then
    null
  else
  "QT Prolonging Agents Not Exist"
  and "High Dosage Citaloprams Exist"

define "Citalopram Not High Dosage":
  if "InPopulation" is not true then
    null
  else
  "Not High Dosage Citaloprams Exist"

define "InPopulation":
   "MeetsInclusionCriteria"

define "Recommendation":
  if "Citalopram High Dosage, QT" then 'Use only if benefit outweighs risk and monitor patients ECG'
  else if "Citalopram High Dosage, No QT" then 'Minimize risk and monitor ECG'
  else if "Citalopram Not High Dosage" then 'No special precaution'
  else null

define "Rationale":
  if "Citalopram High Dosage, QT" then 'Increased risk of prolonged QTc likely'
  else if "Citalopram High Dosage, No QT" then 'Increased risk of prolonged QTc possible'
  else if "Citalopram Not High Dosage" then null
  else null
// ----- BEGIN MANUAL ADDITION -----

define "Errors":
  if null then
    {''}
  else null

define Summary: {
  Patient: {
    Name: Combine(Patient.name.given G return G.value, ' ') + ' ' + Combine(Patient.name.family F return F.value, ' '),
    Gender: Patient.gender.value,
    Age: AgeInYears()
  },
  HistoricalTreatments: {
    Citaloprams: "Report Citaloprams",
    QTProlongingAgents: "Report QT Prolonging Agents",
    BasicConcomitant: "Basic Concomitant Exposure",
    HighCitalopramDose: "High Dosage Citaloprams Exist"
  },
  Alert: {
    Recommendation: "Recommendation",
    Rationale: "Rationale"
  }
}
// ----- END MANUAL ADDITION -----
