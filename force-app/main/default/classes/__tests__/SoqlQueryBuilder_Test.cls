/**
 * @description Focused test class for SoqlQueryBuilder orchestration behavior.
 *              Helper validation/formatting behavior is covered in Utils_*_Tests.
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */
@isTest
private class SoqlQueryBuilder_Test {
    
    @isTest
    static void testBuildQuery_Simple() {
        String objectName = 'Account';
        List<String> fields = new List<String>{'Name', 'Id'};
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        Integer limitVal = 10;
        
        Test.startTest();
        String query = SoqlQueryBuilder.build(objectName, fields, filters, limitVal);
        Test.stopTest();
        
        System.assert(query.contains('SELECT'), 'Should contain SELECT');
        System.assert(query.contains('Name'), 'Should select Name field');
        System.assert(query.contains('FROM Account'), 'Should query Account');
        System.assert(query.contains('LIMIT 10'), 'Should have limit');
    }

    @isTest
    static void testBuildQuery_WithFilters() {
        String objectName = 'Account';
        List<String> fields = new List<String>{'Name'};
        Integer limitVal = 5;
        
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        QueryFilterDto f1 = new QueryFilterDto();
        f1.fieldName = 'Name';
        f1.operator = '=';
        f1.value = 'TestAccount';
        filters.add(f1);
        
        Test.startTest();
        String query = SoqlQueryBuilder.build(objectName, fields, filters, limitVal);
        Test.stopTest();
        
        System.assert(query.contains('WHERE'), 'Should contain WHERE clause');
        System.assert(query.contains('Name ='), 'Should contain filter condition');
    }

    @isTest
    static void testAllowedOperators_Constant() {
        Set<String> operators = SoqlQueryBuilder.ALLOWED_OPERATORS;

        // Verify expected operators are present
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

        // Verify dangerous operators are not present
        System.assert(!operators.contains('OR'), 'Should not contain OR');
        System.assert(!operators.contains('AND'), 'Should not contain AND');
        System.assert(!operators.contains('SELECT'), 'Should not contain SELECT');
        System.assert(!operators.contains('DELETE'), 'Should not contain DELETE');
        System.assert(!operators.contains('UPDATE'), 'Should not contain UPDATE');
        System.assert(!operators.contains('INSERT'), 'Should not contain INSERT');

        // Backward compatibility: SoqlQueryBuilder exposes alias from Utils.
        System.assertEquals(Utils.ALLOWED_OPERATORS, operators,
            'SoqlQueryBuilder.ALLOWED_OPERATORS should alias Utils.ALLOWED_OPERATORS');
    }
    
    @isTest
    static void testBuildQuery_MultipleFilters_AND() {
        QueryFilterDto filter1 = new QueryFilterDto();
        filter1.fieldName = 'Name';
        filter1.operator = 'LIKE';
        filter1.value = 'test';
        
        QueryFilterDto filter2 = new QueryFilterDto();
        filter2.fieldName = 'NumberOfEmployees';
        filter2.operator = '>';
        filter2.value = '100';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildQuery('Account', 
            new List<String>{'Name', 'NumberOfEmployees'}, 
            new List<QueryFilterDto>{filter1, filter2}, 10);
        Test.stopTest();
        
        System.assert(query.contains(' AND '), 
            'Multiple filters should be AND-joined');
        System.assert(query.contains('Name LIKE'), 'Should include first filter');
        System.assert(query.contains('NumberOfEmployees >'), 'Should include second filter');
    }
    
    @isTest
    static void testBuildQuery_SQLInjectionAttempt() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = '=';
        filter.value = 'test\' OR 1=1 --';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildQuery('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        // Should escape the single quote
        System.assert(query.contains('\\\''), 
            'Should escape single quotes: ' + query);
    }
    
    @isTest
    static void testBuild_BackwardCompatibility() {
        // Test that old build() method still works
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = '=';
        filter.value = 'test';
        
        Test.startTest();
        String query = SoqlQueryBuilder.build('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assertNotEquals(null, query, 'Old method should still work');
        System.assert(query.contains('SELECT'), 'Should generate valid query');
    }

    @isTest
    static void testIsCompatibleWithSecurityEnforced_Simple() {
        String q = 'SELECT Id, Name FROM Account LIMIT 1';
        Test.startTest();
        Boolean compat = SoqlQueryBuilder.isCompatibleWithSecurityEnforced(q);
        Test.stopTest();
        System.assertEquals(true, compat, 'Simple select should be compatible');
    }

    @isTest
    static void testIsCompatibleWithSecurityEnforced_Aggregate() {
        String q = 'SELECT COUNT(Id) FROM Account';
        Test.startTest();
        Boolean compat = SoqlQueryBuilder.isCompatibleWithSecurityEnforced(q);
        Test.stopTest();
        System.assertEquals(false, compat, 'Aggregates should be incompatible');
    }

    @isTest
    static void testIsCompatibleWithSecurityEnforced_Typeof() {
        String q = 'SELECT TYPEOF What WHEN Account THEN Id END FROM Event';
        Test.startTest();
        Boolean compat = SoqlQueryBuilder.isCompatibleWithSecurityEnforced(q);
        Test.stopTest();
        System.assertEquals(false, compat, 'TYPEOF should be incompatible');
    }
}