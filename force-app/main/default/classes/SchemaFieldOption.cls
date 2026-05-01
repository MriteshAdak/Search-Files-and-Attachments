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
     * @description Constructor to initialize field option with label and value
     * @param label The user-friendly display label
     * @param value The API name of the field
     */
    public SchemaFieldOption(String label, String value) {
        this.label = label;
        this.value = value;
    }
}