/**
 * @description Service class responsible for enforcing data access security.
 *              Validates object-level security, field-level security (FLS), and provides
 *              accessible field metadata. Changed to 'with sharing' for explicit sharing enforcement.
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */


public with sharing class SecurityService {
    /**
     * @description Validates that the current user has read access to the SObject and all specified fields.
     * @param objectName The API name of the SObject (e.g., 'Attachment').
     * @param fields A list of field API names to check.
     * @throws IllegalArgumentException if the object does not exist
     * @throws SecurityException if the user lacks access to the object or any field
     */
    public static void validateReadAccess(String objectName, List<String> fields) {

        System.debug(
            LoggingLevel.FINE,
            'Security validation initiated by: ' + UserInfo.getUserId()
        );

        if(String.isBlank(objectName) || fields == null || fields.isEmpty()) {
            String errorMsg = 'Invalid input: Object name and fields must be provided. Object: ' + objectName;
            System.debug(LoggingLevel.ERROR, 'VALIDATION_FAILED | ' + errorMsg);
            throw new IllegalArgumentException(errorMsg);
        }
        
        // Validate Object Access
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            System.debug(LoggingLevel.ERROR, 'OBJECT_NOT_FOUND | Object: ' + objectName);
            throw new IllegalArgumentException('Invalid Object: ' + objectName);
        }
        if (!objectType.getDescribe().isAccessible()) {
            System.debug(LoggingLevel.WARN, 'ACCESS_DENIED_OBJECT | User: ' + UserInfo.getUserId() + ' Object: ' + objectName);
            throw new SecurityException('Cannot access object: ' + objectName);
        }

        // Validate Field Access (FLS)
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        for (String field : fields) {
            if (!fieldMap.containsKey(field) || !fieldMap.get(field).getDescribe().isAccessible()) {
                System.debug(LoggingLevel.ERROR, 'FIELD_NOT_FOUND | Object: ' + objectName + ' Field: ' + field);
                throw new SecurityException('Access denied or invalid field: ' + field);
            }
        }
        
        // Log successful validation for audit trail
        System.debug(
            LoggingLevel.FINE, 'Security validation passed: Object=' + objectName 
            + ', User=' + UserInfo.getUserId() + ', Fields=' + String.join(fields, ',')
        );
    }

    /**
     * @description Retrieves a sorted list of field options for a given SObject
     *              that the current user has access to view. Returns SchemaFieldOption DTOs
     *              with normalized field type, operators, and picklist values when applicable.
     * @param objectName The API name of the SObject.
     * @return A List of SchemaFieldOption objects containing field metadata.
     */
    @AuraEnabled(cacheable=true)
    public static List<SchemaFieldOption> getAccessibleFieldOptions(String objectName) {
        if (String.isBlank(objectName)) {
            return new List<SchemaFieldOption>();
        }

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null || !objectType.getDescribe().isAccessible()) {
            return new List<SchemaFieldOption>();
        }

        List<SchemaFieldOption> fieldOptions = new List<SchemaFieldOption>();
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult describe = field.getDescribe();
            if (describe.isAccessible()) {
                String normalizedType = FieldTypeMetadata.normalizeFieldType(describe.getType());
                SchemaFieldOption option = new SchemaFieldOption(
                    describe.getLabel(),
                    describe.getName(),
                    normalizedType
                );
                option.isRequired = !describe.isNillable();
                option.isUpdateable = describe.isUpdateable();
                option.validOperators = FieldTypeMetadata.getValidOperators(normalizedType);

                if (normalizedType == FieldTypeMetadata.TYPE_PICKLIST ||
                    normalizedType == FieldTypeMetadata.TYPE_MULTIPICKLIST) {
                    for (Schema.PicklistEntry entry : describe.getPicklistValues()) {
                        if (entry.isActive()) {
                            option.picklistValues.add(
                                new SchemaFieldOption.PicklistValue(
                                    entry.getLabel(),
                                    entry.getValue(),
                                    entry.isDefaultValue()
                                )
                            );
                        }
                    }
                }
                fieldOptions.add(option);
            }
        }
        
        // Sorting by label for better user experience in dropdowns
        for (Integer i = 0; i < fieldOptions.size() - 1; i++) {
            for (Integer j = i + 1; j < fieldOptions.size(); j++) {
                String labelI = fieldOptions[i].label != null ? fieldOptions[i].label.toLowerCase() : '';
                String labelJ = fieldOptions[j].label != null ? fieldOptions[j].label.toLowerCase() : '';
                if (labelI > labelJ) {
                    SchemaFieldOption temp = fieldOptions[i];
                    fieldOptions[i] = fieldOptions[j];
                    fieldOptions[j] = temp;
                }
            }
        }
        
        return fieldOptions;
    }
}