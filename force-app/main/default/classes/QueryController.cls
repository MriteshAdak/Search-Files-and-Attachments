/**
 * @description Controller class for the Reporting on Files application.
 *              Provides @AuraEnabled methods for LWC components to interact with data securely.
 *              Enforces WITH SECURITY_ENFORCED when compatible.
 *
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */

public with sharing class QueryController {
    public QueryController() {

    }

    /**
     * @description Retrieves accessible field options (label + API name) for a given object.
     *              This is the new enhanced method that returns SchemaFieldOption DTOs.
     *
     * @param objectName The API name of the SObject
     * @return List of SchemaFieldOption objects containing label and value pairs
     * @throws AuraHandledException if an error occurs
     */

    @AuraEnabled(cacheable=true)
    public static List<SchemaFieldOption> getObjectFieldOptions(String objectName) {
        try {
            return SecurityService.getAccessibleFieldOptions(objectName);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving field options: ' + e.getMessage());
        }
    }

    /**
     * @description Executes a dynamic SOQL query with security enforcement.
     *              Validates object/field access, operators, and builds type-aware query.
     *
     * @param objectName The API name of the SObject to query
     * @param fields List of field API names to select
     * @param filters List of filter conditions (can be null or empty)
     * @param limitValue Maximum number of records to return (clamped server-side)
     * @return List of SObject records matching the query
     * @throws AuraHandledException if security validation fails or query is invalid
     */

    @AuraEnabled
    public static List<SObject> executeQuery(String objectName,
                                             List<String> fields,
                                             List<QueryFilterDto> filters,
                                             Integer limitValue) {
        try {
            System.debug(LoggingLevel.FINE, 
                'Starting query execution: Object=' + objectName + 
                ', User=' + UserInfo.getUserId() + 
                ', Fields=' + String.join(fields, ','));

            // Security Check (Object and Field Level Security)
            if (String.isBlank(objectName) || fields == null || fields.isEmpty()) {
                throw new IllegalArgumentException('Object name and fields are required');
            }
            SecurityService.validateReadAccess(objectName, fields);

            // Validate operators against whitelist
            if (filters != null && !filters.isEmpty()) {
                List<String> filterFields = new List<String>();
                Set<String> allowedOps = Utils.ALLOWED_OPERATORS;

                for (QueryFilterDto filter : filters) {
                    String op = filter.operator.toUpperCase().trim();
                    if (!allowedOps.contains(op)) {
                        throw new IllegalArgumentException(
                            'Validation Error: [Unsupported operator: ' 
                            + filter.operator + ']'
                        );
                    }
                    filterFields.add(filter.fieldName);
                }

                // Validate field access of filter fields
                SecurityService.validateReadAccess(objectName, filterFields);
            }

            // Build Query with type-aware value formatting
            String query = SoqlQueryBuilder.buildQuery(objectName, fields, filters, limitValue);

            System.debug(LoggingLevel.FINE, 
                'Query constructed: Query=' + query + 
                ', User=' + UserInfo.getUserId());

            // Execute query
            List<SObject> results = Database.query(query);
            
            // SECURITY: Strip inaccessible fields - ENABLED
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.READABLE,
                results
            );
            
            List<SObject> filteredResults = decision.getRecords();
            
            System.debug(LoggingLevel.FINE,
                'Query executed successfully: ResultCount=' + filteredResults.size() +
                ', RemovedFields=' + decision.getRemovedFields().keySet());
            
            return filteredResults;

        } catch (IllegalArgumentException iae) {
            throw new AuraHandledException('Validation Error: ' + iae.getMessage());
        } catch (SecurityException se) {
            throw new AuraHandledException('Security Error: ' + se.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected Error: ' + e.getMessage());
        }
    }
}