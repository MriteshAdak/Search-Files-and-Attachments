/**
 * @description Shared utility class for query validation and value formatting.
 *              Centralizes operator validation, LIMIT normalization, and
 *              type-aware SOQL literal formatting used by query builder services.
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */

public with sharing class Utils {
    private static final Integer MIN_LIMIT = 1;
    private static final Integer MAX_LIMIT = 2000;
    private static final Integer DEFAULT_LIMIT = 50;

    // Whitelist of supported SOQL operators used for server-side validation.
    public static final Set<String> ALLOWED_OPERATORS = new Set<String>{
        '=', '!=', '<', '>', '<=', '>=',
        'LIKE',
        'IN', 'NOT IN',
        'INCLUDES', 'EXCLUDES'
    };

    /**
     * @description Validates and normalizes the operator string.
     */
    public static String validateOperator(String operator) {
        String normalized = operator.toUpperCase().trim();

        if (!ALLOWED_OPERATORS.contains(normalized)) {
            throw new IllegalArgumentException('Unsupported operator: ' + operator);
        }

        return normalized;
    }

    /**
     * @description Validates and clamps the LIMIT value to acceptable range.
     */
    public static Integer validateLimit(Integer limitVal) {
        if (limitVal == null) {
            return DEFAULT_LIMIT;
        }
        return Math.min(Math.max(limitVal, MIN_LIMIT), MAX_LIMIT);
    }

    /**
     * @description Routes value formatting based on field type.
     */
    public static String formatValueByType(Schema.DescribeFieldResult fieldDescribe,
                                           String operator,
                                           String value,
                                           String fieldName) {
        Schema.DisplayType fieldType = fieldDescribe.getType();

        try {
            switch on fieldType {
                when INTEGER, DOUBLE, CURRENCY, PERCENT {
                    return formatNumericValue(value, operator, fieldName);
                }
                when BOOLEAN {
                    return formatBooleanValue(value, fieldName);
                }
                when DATE {
                    return formatDateValue(value, fieldName);
                }
                when DATETIME {
                    return formatDateTimeValue(value, fieldName);
                }
                when MULTIPICKLIST {
                    return formatMultiSelectValue(value, operator, fieldName);
                }
                when else {
                    return formatTextValue(value, operator, fieldName);
                }
            }
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException(
                'Error formatting value for field "' + fieldName + '": ' + e.getMessage()
            );
        }
    }

    /**
     * @description Validates and formats numeric values for SOQL predicates.
     *              Supports single-value comparisons and IN/NOT IN lists.
     *
     * @param value Raw user value
     * @param operator Normalized SOQL operator
     * @param fieldName Field API name used in validation messages
     * @return Formatted numeric literal or list literal for SOQL
     */
    @TestVisible
    private static String formatNumericValue(String value, String operator, String fieldName) {
        if (operator == 'LIKE') {
            throw new IllegalArgumentException(
                'LIKE operator is not supported for numeric field "' + fieldName +
                '". Use =, !=, <, >, <=, >= instead.'
            );
        }

        if (operator == 'IN' || operator == 'NOT IN') {
            List<String> values = value.split('[,;]');
            if (values.isEmpty()) {
                throw new IllegalArgumentException(
                    'Field "' + fieldName + '" with ' + operator + ' operator requires at least one value in the list.'
                );
            }

            List<String> formatted = new List<String>();
            for (String val : values) {
                String trimmed = val.trim();
                try {
                    Decimal.valueOf(trimmed);
                    formatted.add(trimmed);
                } catch (Exception e) {
                    throw new IllegalArgumentException(
                        'Field "' + fieldName + '" requires numeric values in the list. Invalid value: "' + trimmed + '"'
                    );
                }
            }
            return '(' + String.join(formatted, ', ') + ')';
        }

        try {
            Decimal.valueOf(value.trim());
        } catch (Exception e) {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" requires a numeric value. Provided: "' + value + '"'
            );
        }

        return value.trim();
    }

    /**
     * @description Validates and normalizes boolean values to SOQL TRUE/FALSE literals.
     *
     * @param value Raw user value
     * @param fieldName Field API name used in validation messages
     * @return TRUE or FALSE
     */
    @TestVisible
    private static String formatBooleanValue(String value, String fieldName) {
        String normalized = value.trim().toLowerCase();

        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
            return 'TRUE';
        } else if (normalized == 'false' || normalized == '0' || normalized == 'no') {
            return 'FALSE';
        }

        throw new IllegalArgumentException(
            'Field "' + fieldName + '" requires a boolean value (true/false, yes/no, 1/0). Provided: "' + value + '"'
        );
    }

    /**
     * @description Validates and formats date input as a SOQL-compatible literal.
     *              Accepts ISO dates and supported relative date literals.
     *
     * @param value Raw user value
     * @param fieldName Field API name used in validation messages
     * @return Formatted date literal string
     */
    @TestVisible
    private static String formatDateValue(String value, String fieldName) {
        String trimmed = value.trim();

        if (isDateLiteral(trimmed)) {
            return trimmed;
        }

        try {
            Date.valueOf(trimmed);
            return trimmed;
        } catch (Exception e) {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" requires a date in YYYY-MM-DD format (e.g., 2024-01-15) ' +
                'or a date literal (e.g., LAST_N_DAYS:30). Provided: "' + value + '"'
            );
        }
    }

    /**
     * @description Returns whether the provided token matches a supported SOQL date literal.
     *
     * @param value Candidate literal
     * @return True when the token is a supported date literal
     */
    @TestVisible
    private static Boolean isDateLiteral(String value) {
        String upper = value.toUpperCase();
        return upper == 'TODAY' ||
               upper == 'YESTERDAY' ||
               upper == 'TOMORROW' ||
               upper.startsWith('LAST_N_DAYS:') ||
               upper.startsWith('NEXT_N_DAYS:') ||
               upper.startsWith('LAST_N_WEEKS:') ||
               upper.startsWith('NEXT_N_WEEKS:') ||
               upper.startsWith('LAST_N_MONTHS:') ||
               upper.startsWith('NEXT_N_MONTHS:') ||
               upper.startsWith('LAST_N_YEARS:') ||
               upper.startsWith('NEXT_N_YEARS:');
    }

    /**
     * @description Validates and formats datetime input as a UTC ISO-8601 SOQL literal.
     *              Accepts values with or without trailing Z.
     *
     * @param value Raw user value
     * @param fieldName Field API name used in validation messages
     * @return Normalized UTC datetime literal string
     */
    @TestVisible
    private static String formatDateTimeValue(String value, String fieldName) {
        // TODO: The logic desparatly needs refactoring.
        // Ways to improving the current implementation is also being explored on the UI front.
        String trimmed = value.trim();

        if (isDateLiteral(trimmed)) {
            return trimmed;
        }

        try {
            Datetime dt;
            if (trimmed.endsWith('Z')) {
                dt = Datetime.valueOf(trimmed.replace('T', ' ').replace('Z', ''));
            } else {
                dt = Datetime.valueOf(trimmed.replace('T', ' '));
            }

            return dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        } catch (Exception e) {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" requires a datetime in ISO format (e.g., 2024-01-15T10:30:00Z) ' +
                'or a date literal. Provided: "' + value + '"'
            );
        }
    }

    /**
     * @description Escapes and formats text values for SOQL predicates.
     *              Handles LIKE wildcards and IN/NOT IN list serialization.
     *
     * @param value Raw user value
     * @param operator Normalized SOQL operator
     * @param fieldName Field API name used in validation messages
     * @return Quoted SOQL literal or list literal
     */
    @TestVisible
    private static String formatTextValue(String value, String operator, String fieldName) {
        String escaped = String.escapeSingleQuotes(value);

        if (operator == 'LIKE') {
            if (!escaped.startsWith('%') && !escaped.endsWith('%')) {
                escaped = '%' + escaped + '%';
            }
            return '\'' + escaped + '\'';
        }

        if (operator == 'IN' || operator == 'NOT IN') {
            List<String> values = value.split('[,;]');
            if (values.isEmpty()) {
                throw new IllegalArgumentException(
                    'Field "' + fieldName + '" with ' + operator + ' operator requires at least one value in the list.'
                );
            }

            List<String> formatted = new List<String>();
            for (String val : values) {
                String trimmed = String.escapeSingleQuotes(val.trim());
                if (String.isNotBlank(trimmed)) {
                    formatted.add('\'' + trimmed + '\'');
                }
            }

            if (formatted.isEmpty()) {
                throw new IllegalArgumentException(
                    'Field "' + fieldName + '" with ' + operator + ' operator requires at least one non-empty value.'
                );
            }

            return '(' + String.join(formatted, ', ') + ')';
        }

        return '\'' + escaped + '\'';
    }

    /**
     * @description Formats multi-select picklist values for INCLUDES/EXCLUDES predicates.
     *
     * @param value Raw semicolon-delimited user value
     * @param operator Normalized SOQL operator
     * @param fieldName Field API name used in validation messages
     * @return Parenthesized and quoted multi-select literal list
     */
    @TestVisible
    private static String formatMultiSelectValue(String value, String operator, String fieldName) {
        if (operator != 'INCLUDES' && operator != 'EXCLUDES') {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" is a multi-select picklist and only supports INCLUDES or EXCLUDES operators. ' +
                'Operator used: ' + operator
            );
        }

        List<String> values = value.split(';');
        if (values.isEmpty()) {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" with ' + operator + ' operator requires at least one value.'
            );
        }

        List<String> formatted = new List<String>();
        for (String val : values) {
            String trimmed = String.escapeSingleQuotes(val.trim());
            if (String.isNotBlank(trimmed)) {
                formatted.add('\'' + trimmed + '\'');
            }
        }

        if (formatted.isEmpty()) {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" with ' + operator + ' operator requires at least one non-empty value.'
            );
        }

        return '(' + String.join(formatted, ';') + ')';
    }
}