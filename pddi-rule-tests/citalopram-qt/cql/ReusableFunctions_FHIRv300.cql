library ReusableFunctions_FHIRv300 version '1.0.0'

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0' called FHIRHelpers 

include CDS_Connect_Commons_for_FHIRv300 version '1.1.0' called C3F 

// ## Re-usable functions ##

// Returns the first-found display text for a CodeableConcept, looking first at the `text` attribute, then the
// `display` on each `coding` until it finds a non-null value.
// @param c - a FHIR CodeableConcept to get text from
// @returns {System.String} the display text or null if none is found
define function ConceptText(c FHIR.CodeableConcept):
  Coalesce(c.text.value, Coalesce((c.coding) c2 return c2.display.value))

// Returns the first-found display text for an INGREDIENT within a CodeableConcept
// Medications should have an "ingredient" field that includes a list of "itemCodeableConcept" items. 
// TODO match Medication object with MedicationStatement object based on identical coding
define function DrugDailyDose(c FHIR.Medication):
  c.ingredient[0].amount.numerator.value.value / c.ingredient[0].amount.denominator.value.value

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
