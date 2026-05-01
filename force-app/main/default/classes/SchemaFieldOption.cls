/**
 * @description Data Transfer Object (DTO) for transporting field metadata to LWC components.
 *              Contains both the user-friendly label and the API name for each field.
 *              This class is cacheable and serializable for use with @AuraEnabled(cacheable=true).
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */

public inherited sharing class SchemaFieldOption {
    /**
     * @description The user-friendly display label for the field (e.g., "Account Name")
     */
    @AuraEnabled
    public String label { get; set; }

    /**
     * @description The API name of the field (e.g., "Name")
     */
    @AuraEnabled
    public String value { get; set; }

    /**
     * @description Normalized field type (TEXT, NUMBER, DATE, DATETIME, BOOLEAN, PICKLIST, MULTIPICKLIST, REFERENCE)
     */
    @AuraEnabled
    public String fieldType { get; set; }

    /**
     * @description Picklist values for PICKLIST and MULTIPICKLIST fields
     */
    @AuraEnabled
    public List<PicklistValue> picklistValues { get; set; }

    /**
     * @description Indicates whether the field is required (non-nullable)
     */
    @AuraEnabled
    public Boolean isRequired { get; set; }

    /**
     * @description Indicates whether the field is updateable
     */
    @AuraEnabled
    public Boolean isUpdateable { get; set; }

    /**
     * @description Valid operators for the field type
     */
    @AuraEnabled
    public List<String> validOperators { get; set; }

    /**
     * @description Constructor to initialize field option with label, value, and field type
     * @param label The user-friendly display label
     * @param value The API name of the field
     * @param fieldType Normalized field type
     */
    public SchemaFieldOption(String label, String value, String fieldType) {
        this.label = label;
        this.value = value;
        this.fieldType = fieldType;
        this.picklistValues = new List<PicklistValue>();
        this.isRequired = false;
        this.isUpdateable = false;
        this.validOperators = new List<String>();
    }

    /**
     * @description DTO for picklist entries
     */
    public class PicklistValue {
        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String value { get; set; }

        @AuraEnabled
        public Boolean isDefaultValue { get; set; }

        public PicklistValue(String label, String value, Boolean isDefaultValue) {
            this.label = label;
            this.value = value;
            this.isDefaultValue = isDefaultValue;
        }
    }

    /**
     * @description Builder for optional SchemaFieldOption properties
     */
    public class Builder {
        private SchemaFieldOption option;

        public Builder(String label, String value, String fieldType) {
            option = new SchemaFieldOption(label, value, fieldType);
        }

        public Builder withPicklistValues(List<PicklistValue> picklistValues) {
            option.picklistValues = picklistValues;
            return this;
        }

        public Builder withRequired(Boolean isRequired) {
            option.isRequired = isRequired;
            return this;
        }

        public Builder withUpdateable(Boolean isUpdateable) {
            option.isUpdateable = isUpdateable;
            return this;
        }

        public Builder withValidOperators(List<String> validOperators) {
            option.validOperators = validOperators;
            return this;
        }

        public SchemaFieldOption build() {
            return option;
        }
    }

    public static Builder builder(String label, String value, String fieldType) {
        return new Builder(label, value, fieldType);
    }
}