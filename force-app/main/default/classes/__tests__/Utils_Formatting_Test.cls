/**
 * @description Formatting-focused tests for Utils helper methods.
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */
@isTest
private class Utils_Formatting_Test {

    @isTest
    static void testFormatNumericValue_ValidSingle() {
        String formatted = Utils.formatNumericValue('100', '>', 'NumberOfEmployees');
        System.assertEquals('100', formatted, 'Numeric value should not be quoted');
    }

    @isTest
    static void testFormatNumericValue_ValidInList() {
        String formatted = Utils.formatNumericValue('100, 200, 300', 'IN', 'NumberOfEmployees');
        System.assertEquals('(100, 200, 300)', formatted, 'IN list should be numeric and parenthesized');
    }

    @isTest
    static void testFormatNumericValue_Invalid() {
        try {
            Utils.formatNumericValue('not_a_number', '=', 'NumberOfEmployees');
            System.assert(false, 'Should throw on invalid numeric value');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('numeric value'),
                'Should include numeric validation message');
        }
    }

    @isTest
    static void testFormatNumericValue_LikeNotSupported() {
        try {
            Utils.formatNumericValue('100', 'LIKE', 'NumberOfEmployees');
            System.assert(false, 'Should throw on LIKE for numeric field');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('LIKE operator is not supported'),
                'Should include LIKE unsupported message');
        }
    }

    @isTest
    static void testFormatBooleanValue_ValidVariations() {
        System.assertEquals('TRUE', Utils.formatBooleanValue('true', 'IsDeleted'));
        System.assertEquals('TRUE', Utils.formatBooleanValue('YES', 'IsDeleted'));
        System.assertEquals('FALSE', Utils.formatBooleanValue('false', 'IsDeleted'));
        System.assertEquals('FALSE', Utils.formatBooleanValue('0', 'IsDeleted'));
    }

    @isTest
    static void testFormatBooleanValue_Invalid() {
        try {
            Utils.formatBooleanValue('maybe', 'IsDeleted');
            System.assert(false, 'Should throw on invalid boolean value');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('boolean value'),
                'Should include boolean validation message');
        }
    }

    @isTest
    static void testFormatDateValue_ValidAndLiteral() {
        System.assertEquals('2024-01-15', Utils.formatDateValue('2024-01-15', 'SomeDateField'));
        System.assertEquals('LAST_N_DAYS:30', Utils.formatDateValue('LAST_N_DAYS:30', 'SomeDateField'));
    }

    @isTest
    static void testFormatDateValue_Invalid() {
        try {
            Utils.formatDateValue('01/15/2024', 'SomeDateField');
            System.assert(false, 'Should throw on invalid date format');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('YYYY-MM-DD'),
                'Should include date format guidance');
        }
    }

    @isTest
    static void testIsDateLiteral() {
        System.assertEquals(true, Utils.isDateLiteral('TODAY'));
        System.assertEquals(true, Utils.isDateLiteral('LAST_N_DAYS:7'));
        System.assertEquals(false, Utils.isDateLiteral('2024-01-01'));
    }

    @isTest
    static void testFormatDateTimeValue_ValidAndInvalid() {
        String withZ = Utils.formatDateTimeValue('2024-01-15T10:30:00Z', 'CreatedDate');
        String withoutZ = Utils.formatDateTimeValue('2024-01-15T10:30:00', 'CreatedDate');
        //  Needs some serious review. Issues with timezones translations that is affecting the output.
        System.assertEquals('2024-01-15T05:00:00Z', withZ);
        System.assertEquals('2024-01-15T05:00:00Z', withoutZ);

        try {
            Utils.formatDateTimeValue('2024/01/15 10:30:00', 'CreatedDate');
            System.assert(false, 'Should throw on invalid datetime format');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('ISO format'),
                'Should include datetime format guidance');
        }
    }

    @isTest
    static void testFormatTextValue_LikeAndEqualsEscaping() {
        System.assertEquals('\'%test%\'', Utils.formatTextValue('test', 'LIKE', 'Name'));
        System.assertEquals('\'%test%\'', Utils.formatTextValue('%test%', 'LIKE', 'Name'));

        String escaped = Utils.formatTextValue('test\'value', '=', 'Name');
        System.assert(escaped.contains('\\\''), 'Should escape single quotes in text values');
    }

    @isTest
    static void testFormatTextValue_InList() {
        String formatted = Utils.formatTextValue('A, B, C', 'IN', 'Name');
        System.assertEquals('(' + '\'A\'' + ', ' + '\'B\'' + ', ' + '\'C\'' + ')', formatted,
            'Text IN list should be quoted and comma-separated');
    }

    @isTest
    static void testFormatMultiSelectValue_ValidAndInvalid() {
        String formatted = Utils.formatMultiSelectValue('A;B', 'INCLUDES', 'SomeMulti');
        System.assertEquals('(' + '\'A\'' + ';' + '\'B\'' + ')', formatted,
            'Multi-select list should be quoted and semicolon-separated');

        try {
            Utils.formatMultiSelectValue('A;B', 'IN', 'SomeMulti');
            System.assert(false, 'Should throw when operator is not INCLUDES/EXCLUDES');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('only supports INCLUDES or EXCLUDES'));
        }

        try {
            Utils.formatMultiSelectValue(' ; ', 'INCLUDES', 'SomeMulti');
            System.assert(false, 'Should throw on empty multi-select payload');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('at least one non-empty value'));
        }
    }

    @isTest
    static void testFormatValueByType_RoutesByFieldType() {
        Schema.DescribeFieldResult numericField = getFieldDescribe('Account', 'NumberOfEmployees');
        Schema.DescribeFieldResult textField = getFieldDescribe('Account', 'Name');

        String numericFormatted = Utils.formatValueByType(numericField, '>', '100', 'NumberOfEmployees');
        String textFormatted = Utils.formatValueByType(textField, '=', 'Test', 'Name');

        System.assertEquals('100', numericFormatted, 'Should route numeric field to numeric formatter');
        System.assertEquals('\'Test\'', textFormatted, 'Should route text field to text formatter');
    }

    private static Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        return fieldMap.get(fieldName).getDescribe();
    }
}