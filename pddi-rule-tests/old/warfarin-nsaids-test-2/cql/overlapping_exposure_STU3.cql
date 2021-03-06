// # Introduction

// NOTE: THIS IS AN UNTESTED FHIR STU3 PORT OF THE PAIN MANAGEMENT SUMMARY.
// THIS ARTIFACT IS INTENDED FOR TESTING PURPOSES ONLY!

// The Pain Management Summary artifact provides relevant information to consider when managing a patient’s pain.
// This CDS logic was informed by the Centers for Disease Control and Prevention (CDC) Guideline for Opioid Prescribing
// for Chronic Pain. The CDS is not a direct representation of any one recommendation statement within the guideline.
// Instead, the CDS compiles clinical concepts mentioned throughout the guideline in one consolidated summary for
// clinician review.
//
// In the process of authoring the logic, certain assumptions were made and details developed when the guideline did
// not provide enough specificity.  These decisions were made in the context of the CDS Connect Workgroup and CDC
// stakeholders, and are documented in the logic and/or in the CDS Connect artifact metadata.
//
// ##Source guideline: [CDC Guideline for Opioid Prescribing for Chronic Pain](https://www.cdc.gov/drugoverdose/prescribing/guideline.html)

// library simple_concomitant_exposure_STU3 version '1.0.0'
library overlapping_exposure_STU3 version '1.0.0'

// # Data model #

// The FHIR STU3 model is used for testing purposes only.  It has not been piloted.
using FHIR version '3.0.0'

// # Referenced libraries #

// The CDS Connect Commons for FHIRv102 library provides functions representing commonly used CDS logic and patterns.
include CDS_Connect_Commons_for_FHIRv300 version '1.1.0' called C3F

// The FHIRHelpers library provides common functions for simplifying interaction w/ the FHIR v102 data model.
include FHIRHelpers version '3.0.0' called FHIRHelpers

// # Value sets and codes #

// ## Code Systems ##

codesystem "RXNORM": 'http://www.nlm.nih.gov/research/umls/rxnorm'

// ## Value sets ##

// List value sets used by the artifact. The links to the Value Set Authority Center (VSAC) point to the latest
// expansion of each value set available.

// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113762.1.4.1032.37/expansion)
valueset "Warfarin": '2.16.840.1.113883.3.117.1.7.1.232'

valueset "Medications for Primary Headache NSAIDs": '2.16.840.1.113762.1.4.1046.84'

valueset "Proton Pump Inhibitors not including for H. pylori treatment": '1.3.6.1.4.1.6997.4.1.2.271.12.37696.1.1.999.654'

// ## Individual codes ##

// list individual codes from code systems used directly in the CQL logic. Individual codes are used when there is
// a single code from a particular vocabulary standard used to represent a clinical concept. It is considered
// best-practice not to create value sets containing a single code.


// The following codes do not yet have standardized codes associated with them so are expressed as LOCAL codes.
// As standardized codes become available, this CDS will be updated to use standard codes rather than LOCAL codes.


// CQL currently requires concept declarations to contain references to code declarations.


// # Parameters #

// The InclusionMedicationsLookbackPeriod allows CDS implementors to specify how far the inclusion logic should look
// back for qualifying active medications. By default, the inclusion logic will look back 180 days.
parameter InclusionMedicationsLookbackPeriod default 180 days

// # CDS logic #

context Patient

// ## Re-usable functions ##

// Returns the first-found display text for a CodeableConcept, looking first at the `text` attribute, then the
// `display` on each `coding` until it finds a non-null value.
// @param c - a FHIR CodeableConcept to get text from
// @returns {System.String} the display text or null if none is found
define function ConceptText(c FHIR.CodeableConcept):
  Coalesce(c.text.value, Coalesce((c.coding) c2 return c2.display.value))

// Returns a text representation of a date associated with a MedicationStatement, preferring `effectiveDateTime`, then
// `.start`.
// @param m - a FHIR MedicationStatement to get the text date from
// @returns {System.String} the text representation of a relevant date from the MedicationStatement
define function MedicationStatementDate(s FHIR.MedicationStatement):
  Coalesce(DateTimeText(s.effective as FHIR.dateTime), DateTimeText((s.effective as FHIR.Period)."start"))

// Returns a text representation of a dateTime using the CQL `ToString` function.
// @param d - a FHIR dateTime to get text for
// @returns {System.String} the text representation of the dateTime
define function DateTimeText(d FHIR.dateTime):
  ToString(d.value)

// RISK CONSIDERATIONS

define WarfarinMedicationStatements:
  C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Warfarin"],
    InclusionMedicationsLookbackPeriod
  ))

define NsaidsMedicationStatements:
  C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Medications for Primary Headache NSAIDs"],
    InclusionMedicationsLookbackPeriod
  ))

define PPIsMedicationStatements:
  C3F.ActiveOrCompletedMedicationStatement(C3F.MedicationStatementLookBack(
    [MedicationStatement: "Proton Pump Inhibitors not including for H. pylori treatment"],
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

define ReportNsaidsMedicationStatements:
  (NsaidsMedicationStatements) S
  return {
    Type:   'Statement',
    Name:   ConceptText(S.medication as FHIR.CodeableConcept),
    Start:  MedicationStatementDate(S),
    End:    DateTimeText((S.effective as FHIR.Period)."end"),
    Status: S.status.value
  }
  sort by Start desc, End desc

define ReportPPIsMedicationStatements:
  (PPIsMedicationStatements) S
  return {
    Type:   'Statement',
    Name:   ConceptText(S.medication as FHIR.CodeableConcept),
    Start:  MedicationStatementDate(S),
    End:    DateTimeText((S.effective as FHIR.Period)."end"),
    Status: S.status.value
  }
  sort by Start desc, End desc

// ## Target population ##

// INCLUSIONS

// Determines if the patient has any record of adjuvant analgesic medications in the lookback period
//       - Medication Request within past 180 days (lookback can be made a parameter)
//       - Medication Statement by patient within past 180 days (lookback can be made a parameter)
define HasRecentWarfarinNsaidsStatements:
  exists WarfarinMedicationStatements
  and exists NsaidsMedicationStatements

// NOTE - currently no Medication Statement End Date is being considered here. Either assuming that Today() will always be "during" the Medication Statement, or that all MedicationStatements will use effectiveDateTime instead of effectivePeriod. Thus the final version of this function may depend on what the data looks like
define OverlappingWarfarinNsaids: 
  (WarfarinMedicationStatements) WS
  with (NsaidsMedicationStatements) NS
    such that 
      (ToDateTime(MedicationStatementDate(WS)) between ToDateTime(MedicationStatementDate(NS)) and Today())
      or 
      (ToDateTime(MedicationStatementDate(NS)) between ToDateTime(MedicationStatementDate(WS)) and Today())
      return {
        Type: 'Concomitant Statements',
        Drug1Name: ConceptText(WS.medication as FHIR.CodeableConcept),
        Drug1Start: MedicationStatementDate(WS),
        Drug1Status: WS.status.value/*,
        Drug2Name: ConceptText(NS.medication as FHIR.CodeableConcept),
        Drug2Start: MedicationStatementDate(NS),
        Drug2Status: NS.status.value*/
      }
      // sort by Drug1Start desc, Drug2Start desc

/*define HasOverlappingStatementsWithPPI:
  (PPIsMedicationStatements) PS
  and HasOverlappingWarfarinNsaidsStatements
    return true*/

// EXCLUSIONS


// ## Intervention(s) ##

// SUMMARY

// The Summary object represents the full Pain Management Summary to be displayed to the clinician.  All values are
// returned as user-friendly text representations, but a robust user interface (UI) should be implemented to
// display the data to the user in a friendly manner.  See the Pain Management Summary SMART on FHIR application as
// an example of how to integrate this summary into an EHR using modern web UI technologies.

define Summary: {
  Patient: {
    Name: Combine(Patient.name.given G return G.value, ' ') + ' ' + Combine(Patient.name.family F return F.value, ' '),
    Gender: Patient.gender.value,
    Age: AgeInYears()
  },
  HistoricalTreatments: {
    WarfarinMedications: ReportWarfarinMedicationStatements,
    NsaidsMedications: ReportNsaidsMedicationStatements,
    PPIsMedications: ReportPPIsMedicationStatements
  },
  OverlappingWarfarinNsaids: OverlappingWarfarinNsaids//,
  // HasOverlappingStatementsWithPPI: HasOverlappingStatementsWithPPI
}
