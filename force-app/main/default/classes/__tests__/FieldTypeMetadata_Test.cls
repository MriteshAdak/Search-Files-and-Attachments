/**
 * @description Test class for FieldTypeMetadata.
 *              Verifies field type normalization and operator mappings.
 *
 * @author Mritesh
 * @date 2026-05
 * @version 1.0.0
 */
@isTest
private class FieldTypeMetadata_Test {

    @isTest
    static void testNormalizeFieldType_TextTypes() {
        System.assertEquals(
            FieldTypeMetadata.TYPE_TEXT,
            FieldTypeMetadata.normalizeFieldType(Schema.DisplayType.STRING)
        );
        System.assertEquals(
            FieldTypeMetadata.TYPE_TEXT,
            FieldTypeMetadata.normalizeFieldType(Schema.DisplayType.TEXTAREA)
        );
        System.assertEquals(
            FieldTypeMetadata.TYPE_TEXT,
            FieldTypeMetadata.normalizeFieldType(Schema.DisplayType.EMAIL)
        );
    }

    @isTest
    static void testNormalizeFieldType_NumericTypes() {
        System.assertEquals(
            FieldTypeMetadata.TYPE_NUMBER,
            FieldTypeMetadata.normalizeFieldType(Schema.DisplayType.INTEGER)
        );
        System.assertEquals(
            FieldTypeMetadata.TYPE_NUMBER,
            FieldTypeMetadata.normalizeFieldType(Schema.DisplayType.DOUBLE)
        );
        System.assertEquals(
            FieldTypeMetadata.TYPE_NUMBER,
            FieldTypeMetadata.normalizeFieldType(Schema.DisplayType.CURRENCY)
        );
    }

    @isTest
    static void testNormalizeFieldType_DateTimeTypes() {
        System.assertEquals(
            FieldTypeMetadata.TYPE_DATE,
            FieldTypeMetadata.normalizeFieldType(Schema.DisplayType.DATE)
        );
        System.assertEquals(
            FieldTypeMetadata.TYPE_DATETIME,
            FieldTypeMetadata.normalizeFieldType(Schema.DisplayType.DATETIME)
        );
    }

    @isTest
    static void testNormalizeFieldType_Reference() {
        System.assertEquals(
            FieldTypeMetadata.TYPE_REFERENCE,
            FieldTypeMetadata.normalizeFieldType(Schema.DisplayType.REFERENCE)
        );
    }

    @isTest
    static void testGetValidOperators_Text() {
        List<String> operators = FieldTypeMetadata.getValidOperators(FieldTypeMetadata.TYPE_TEXT);
        System.assert(operators.contains('='));
        System.assert(operators.contains('LIKE'));
        System.assert(operators.contains('IN'));
        System.assert(operators.contains('NOT IN'));
    }

    @isTest
    static void testGetValidOperators_Boolean() {
        List<String> operators = FieldTypeMetadata.getValidOperators(FieldTypeMetadata.TYPE_BOOLEAN);
        System.assertEquals(2, operators.size());
        System.assert(operators.contains('='));
        System.assert(operators.contains('!='));
        System.assert(!operators.contains('LIKE'));
    }

    @isTest
    static void testGetValidOperators_Multipicklist() {
        List<String> operators = FieldTypeMetadata.getValidOperators(FieldTypeMetadata.TYPE_MULTIPICKLIST);
        System.assert(operators.contains('INCLUDES'));
        System.assert(operators.contains('EXCLUDES'));
        System.assert(!operators.contains('='));
    }

    @isTest
    static void testGetValidOperators_Reference() {
        List<String> operators = FieldTypeMetadata.getValidOperators(FieldTypeMetadata.TYPE_REFERENCE);
        System.assert(operators.contains('='));
        System.assert(operators.contains('IN'));
        System.assert(!operators.contains('LIKE'));
    }

    @isTest
    static void testGetValidOperators_BlankType() {
        List<String> operators = FieldTypeMetadata.getValidOperators(null);
        System.assertEquals(2, operators.size());
        System.assert(operators.contains('='));
        System.assert(operators.contains('!='));
    }
}
