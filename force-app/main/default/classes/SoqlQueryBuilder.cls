/**
 * @description Service class responsible for building dynamic SOQL queries with type-aware value formatting.
 *              Supports all standard field types and validates operators against a whitelist.
 *              Changed to 'with sharing' for explicit sharing enforcement.
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */


public with sharing class SoqlQueryBuilder {
    public SoqlQueryBuilder() {

    }

    /**
     * @description Builds a SOQL query with type-aware value formatting.
     *              Validates operators, determines field types, and formats values accordingly.
     *              Accessible objects and fields must be handled by the caller.
     * 
     * @param objectName The API name of the SObject to query
     * @param fields List of field API names to select
     * @param filters List of filter conditions (can be null or empty)
     * @param limitVal The maximum number of records to return (will be clamped to MIN_LIMIT/MAX_LIMIT)
     * @return A complete SOQL query string
     * @throws IllegalArgumentException if operator is invalid or value doesn't match field type
     */
    public static String buildQuery(String objectName, List<String> fields, List<QueryFilterDto> filters, Integer limitVal) {
        // Build SELECT clause. Accessible fields should have been validated by caller.
        String query = 'SELECT ' + String.join(fields, ', ') + 
                      ' FROM ' + String.escapeSingleQuotes(objectName);
        
        // Build WHERE clause if filters provided
        if (filters != null && !filters.isEmpty()) {
            query += ' WHERE ' + buildWhereClauseTyped(objectName, filters);
        }
        query = applySecurityEnforcementIfCompatible(query);
        
        // Add LIMIT with validation
        query += ' LIMIT ' + Utils.validateLimit(limitVal);

        
        return query;
    }

        /**
     * @description Helper to append WITH SECURITY_ENFORCED when the query is compatible.
     *
     * @param query The complete SOQL query string
     * @return Query string with WITH SECURITY_ENFORCED appended when compatible; original otherwise
     */
    public static String applySecurityEnforcementIfCompatible(String query) {
        if (isCompatibleWithSecurityEnforced(query)) {
            return query + ' WITH SECURITY_ENFORCED';
        }
        return query;
    }

    /**
     * @description Determines whether a query is compatible with WITH SECURITY_ENFORCED.
     *              Current implementation does not qualify for these checks
     *              but keeping it since it provides a structure for future enhancements.
     *              
     *              Incompatible when:
     *                - Aggregate functions present
     *                - TYPEOF expression present
     *
     * @param query The SOQL query string
     * @return True if compatible, false otherwise
     */
    public static Boolean isCompatibleWithSecurityEnforced(String query) {
        if (query == null) return false;

        String upper = query.toUpperCase();

        // Malformed query check that AgentForce decided to implement.
        // Keeping it because it doesn´t seem to hurt the functionallity.
        Integer selectPos = upper.indexOf('SELECT');
        Integer fromPos = upper.indexOf('FROM');
        if (selectPos == -1 || fromPos == -1 || fromPos <= selectPos) {
            return false;
        }

        String selectClause = query.substring(selectPos + 6, fromPos).trim();

        // Aggregate functions
        if (upper.contains('COUNT(') || upper.contains('SUM(') ||
            upper.contains('AVG(') || upper.contains('MAX(') || upper.contains('MIN(')) {
            return false;
        }

        // TYPEOF expressions
        if (upper.contains('TYPEOF')) {
            return false;
        }

        return true;
    }

    /**
     * @description Builds the WHERE clause of the query with type-aware value formatting.
     * 
     * @param objectName The API name of the SObject being queried
     * @param filters List of filter conditions
     * @return The WHERE clause string (without the 'WHERE' keyword)
     * @throws IllegalArgumentException if operator or value is invalid for field type
     */
    private static String buildWhereClauseTyped(String objectName, List<QueryFilterDto> filters) {

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        
        List<String> conditions = new List<String>();
        
        for (QueryFilterDto filter : filters) {

            Schema.SObjectField fieldToken = fieldMap.get(filter.fieldName);
            if (fieldToken == null) {
                throw new IllegalArgumentException('Invalid field: ' + filter.fieldName);
            }
            
            Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();

            String operator = Utils.validateOperator(filter.operator);

            // Future version must pass the whole filter DTO to utilize the value parsing funciton of the DTO.
            String formattedValue = Utils.formatValueByType(fieldDescribe, operator, filter.value, filter.fieldName);
            
            // Build condition
            String field = fieldDescribe.getName();
            conditions.add(field + ' ' + operator + ' ' + formattedValue);
        }
        
        // Logical Operator to be configurable in the next version if there is one.
        return String.join(conditions, ' AND ');
    }
}