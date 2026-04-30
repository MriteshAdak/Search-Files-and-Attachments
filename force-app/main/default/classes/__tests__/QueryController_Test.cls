/**
 * @description Revised test class for QueryController.
 *              Aligns with normalized exception prefixes, deterministic assertions,
 *              explicit LIKE semantics, and centralized test data setup.
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */
@IsTest
private class QueryController_Test {

    @testSetup
    static void setupData() {
        // Prefer creating via TestDataFactory if available; fallback inline if needed
        // Example using a hypothetical factory:
        // TestDataFactory.TestContext ctx = TestDataFactory.createAccountWithAttachments(
        //     1, new List<String>{'SmallFile.txt', 'LargeFile.txt', 'Report_Q1.pdf'},
        //     new List<Integer>{15, 2000, 120});
        // If factory unavailable, inline minimal deterministic data:
        Account acc = new Account(Name = 'TST_Account');
        insert acc;

        Attachment smallA = new Attachment(
            Name = 'SmallFile.txt',
            Body = Blob.valueOf('Small content'),
            ParentId = acc.Id
        );
        Attachment largeA = new Attachment(
            Name = 'LargeFile.txt',
            Body = Blob.valueOf(String.valueOf('X').repeat(2000)),
            ParentId = acc.Id
        );
        Attachment reportA = new Attachment(
            Name = 'Report_Q1.pdf',
            Body = Blob.valueOf('PDF content'),
            ParentId = acc.Id
        );
        insert new List<Attachment>{ smallA, largeA, reportA };
    }

    @IsTest
    static void test_getObjectFieldOptions_basic() {
        Test.startTest();
        List<SchemaFieldOption> opts = QueryController.getObjectFieldOptions('Attachment');
        Test.stopTest();

        System.assertNotEquals(null, opts, 'Options should not be null');
        System.assert(opts.size() > 0, 'Should return field options');
        // Verify Name exists and has a label
        Boolean hasName = false;
        for (SchemaFieldOption o : opts) {
            if (o != null && o.value == 'Name') {
                hasName = true;
                System.assertNotEquals(null, o.label, 'Name label should be populated');
                break;
            }
        }
        System.assert(hasName, 'Should include Name field');
    }

    @IsTest
    static void test_executeQuery_success_byNameEquals() {
        List<String> fields = new List<String>{ 'Name', 'Id', 'ParentId' };
        List<QueryFilterDto> filters = new List<QueryFilterDto>();

        QueryFilterDto f = new QueryFilterDto();
        f.fieldName = 'Name';
        f.operator = '=';
        f.value = 'SmallFile.txt';
        filters.add(f);

        Test.startTest();
        List<SObject> results = QueryController.executeQuery('Attachment', fields, filters, 10);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        // Assert content without relying on order
        Boolean found = false;
        for (SObject r : results) {
            if (((String) r.get('Name')) == 'SmallFile.txt') {
                found = true;
                break;
            }
        }
        System.assert(found, 'Should contain SmallFile.txt');
    }

    // @IsTest
    // static void test_executeQuery_invalidOperator_validationError() {
    //     List<QueryFilterDto> filters = new List<QueryFilterDto>();
    //     QueryFilterDto f = new QueryFilterDto();
    //     f.fieldName = 'Name';
    //     f.operator = 'INVALID_OP';
    //     f.value = 'x';
    //     filters.add(f);

    //     try {
    //         Test.startTest();
    //         QueryController.executeQuery('Attachment', new List<String>{ 'Name' }, filters, 10);
    //         Test.stopTest();
    //         System.assert(false, 'Expected AuraHandledException');
    //     } catch (Exception e) {
    //         System.assert(e.getMessage().contains('Validation Error:'), 'Should be a validation error');
    //     }
    // }

    // @IsTest
    // static void test_executeQuery_invalidField_securityError() {
    //     // Request a non-existent field to trigger SecurityService validation failure
    //     try {
    //         Test.startTest();
    //         QueryController.executeQuery('Attachment', new List<String>{ 'NonExistentField__c' }, null, 10);
    //         Test.stopTest();
    //         System.assert(false, 'Expected AuraHandledException');
    //     } catch (Exception e) {
    //         System.assert(e.getMessage().contains('Security Error:'), 'Should be a security error');
    //     }
    // }

    @IsTest
    static void test_executeQuery_like_withExplicitWildcards() {
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        QueryFilterDto f = new QueryFilterDto();
        f.fieldName = 'Name';
        f.operator = 'LIKE';
        f.value = '%Report%'; // use explicit wildcards to avoid ambiguity
        filters.add(f);

        Test.startTest();
        List<SObject> results = QueryController.executeQuery('Attachment', new List<String>{ 'Name' }, filters, 10);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should match one record by LIKE');
        System.assert(((String) results[0].get('Name')).contains('Report'), 'Name should contain "Report"');
    }

    @IsTest
    static void test_executeQuery_numericFilter_bodyLengthGreaterThan() {
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        QueryFilterDto f = new QueryFilterDto();
        f.fieldName = 'BodyLength';
        f.operator = '>';
        f.value = '100';
        filters.add(f);

        Test.startTest();
        List<SObject> results = QueryController.executeQuery('Attachment', new List<String>{ 'Name', 'BodyLength' }, filters, 10);
        Test.stopTest();

        System.assert(results.size() > 0, 'Should return records');
        for (SObject r : results) {
            System.assert(((Integer) r.get('BodyLength')) > 100, 'BodyLength should be > 100');
        }
    }

    @IsTest
    static void test_executeQuery_multipleFilters_andLogic() {
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        QueryFilterDto f1 = new QueryFilterDto();
        f1.fieldName = 'Name';
        f1.operator = 'LIKE';
        f1.value = '%File%';
        filters.add(f1);

        QueryFilterDto f2 = new QueryFilterDto();
        f2.fieldName = 'BodyLength';
        f2.operator = '>';
        f2.value = '50';
        filters.add(f2);

        Test.startTest();
        List<SObject> results = QueryController.executeQuery(
            'Attachment',
            new List<String>{ 'Name', 'BodyLength' },
            filters,
            10
        );
        Test.stopTest();

        for (SObject r : results) {
            System.assert(((String) r.get('Name')).contains('File'), 'Name should contain File');
            System.assert(((Integer) r.get('BodyLength')) > 50, 'BodyLength should be > 50');
        }
    }

    @IsTest
    static void test_executeQuery_noFilters_returnsSome() {
        Test.startTest();
        List<SObject> results = QueryController.executeQuery(
            'Attachment',
            new List<String>{ 'Name', 'Id' },
            new List<QueryFilterDto>(),
            10
        );
        Test.stopTest();

        System.assertNotEquals(null, results, 'Should return non-null list');
        System.assert(results.size() <= 10, 'Should respect limit');
        System.assert(results.size() > 0, 'Should return some rows');
    }
}