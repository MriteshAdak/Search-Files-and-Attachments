/**
 * @description Validation-focused test class for Utils helper methods.
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */

@isTest
private class Utils_Test {

    @isTest
    static void testAllowedOperators_Constant() {
        Set<String> operators = Utils.ALLOWED_OPERATORS;

        System.assert(operators.contains('='), 'Should contain =');
        System.assert(operators.contains('!='), 'Should contain !=');
        System.assert(operators.contains('<'), 'Should contain <');
        System.assert(operators.contains('>'), 'Should contain >');
        System.assert(operators.contains('<='), 'Should contain <=');
        System.assert(operators.contains('>='), 'Should contain >=');
        System.assert(operators.contains('LIKE'), 'Should contain LIKE');
        System.assert(operators.contains('IN'), 'Should contain IN');
        System.assert(operators.contains('NOT IN'), 'Should contain NOT IN');
        System.assert(operators.contains('INCLUDES'), 'Should contain INCLUDES');
        System.assert(operators.contains('EXCLUDES'), 'Should contain EXCLUDES');

        System.assert(!operators.contains('OR'), 'Should not contain OR');
        System.assert(!operators.contains('AND'), 'Should not contain AND');
    }

    @isTest
    static void testValidateOperator_SupportedAndNormalized() {
        String op = Utils.validateOperator(' like ');
        System.assertEquals('LIKE', op, 'Should uppercase and trim operator');
    }

    @isTest
    static void testValidateOperator_Unsupported() {
        try {
            Utils.validateOperator('INVALID_OP');
            System.assert(false, 'Should throw for unsupported operator');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Unsupported operator'),
                'Should include unsupported operator message');
        }
    }

    @isTest
    static void testValidateLimit_TooLow() {
        System.assertEquals(1, Utils.validateLimit(0), 'Should clamp to min 1');
    }

    @isTest
    static void testValidateLimit_TooHigh() {
        System.assertEquals(2000, Utils.validateLimit(5000), 'Should clamp to max 2000');
    }

    @isTest
    static void testValidateLimit_NullDefaults() {
        System.assertEquals(50, Utils.validateLimit(null), 'Should default null to 50');
    }
}