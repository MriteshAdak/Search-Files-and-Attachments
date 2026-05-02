/**
 * @description Enhanced test class for SecurityService.
 *              Tests security validation and field option access behaviors.
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */
@isTest
private class SecurityService_Test {
    
    @isTest
    static void testValidateReadAccess_Positive() {
        // Test with a standard object that exists in all orgs
        String objectName = 'Account';
        List<String> fields = new List<String>{'Name', 'Id'};
        
        Test.startTest();
        try {
            SecurityService.validateReadAccess(objectName, fields);
            System.assert(true, 'Should not throw exception for valid Account access');
        } catch (Exception e) {
            System.assert(false, 'Should not have thrown an exception for valid Account access: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateReadAccess_InvalidObject() {
        String invalidObj = 'ReallyNonExistentObject__c';
        List<String> fields = new List<String>{'Name'};
        
        Test.startTest();
        try {
            SecurityService.validateReadAccess(invalidObj, fields);
            System.assert(false, 'Should have thrown exception for invalid object');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid Object'), 'Should indicate invalid object');
        } catch (Exception e) {
            System.assert(false, 'Wrong exception type thrown: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateReadAccess_InvalidField() {
        String objectName = 'Account';
        List<String> fields = new List<String>{'InvalidField__c'};
        
        Test.startTest();
        try {
            SecurityService.validateReadAccess(objectName, fields);
            System.assert(false, 'Should have thrown exception for invalid field');
        } catch (SecurityException e) {
            System.assert(e.getMessage().contains('Access denied'), 'Should indicate access denied');
        } catch (Exception e) {
            System.assert(false, 'Wrong exception type: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetAccessibleFieldOptions_Account() {
        // Test that field options include both label and value
        Test.startTest();
        List<SchemaFieldOption> options = SecurityService.getAccessibleFieldOptions('Account');
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Should return options');
        System.assert(options.size() > 0, 'Should have at least one field');
        
        // Find the Name field
        SchemaFieldOption nameField = null;
        for (SchemaFieldOption opt : options) {
            if (opt.value == 'Name') {
                nameField = opt;
                break;
            }
        }
        
        System.assertNotEquals(null, nameField, 'Should include Name field');
        System.assertEquals('Name', nameField.value, 'Value should be API name');
        System.assertNotEquals(null, nameField.label, 'Label should not be null');
        System.assert(nameField.label.length() > 0, 'Label should not be empty');
        System.assertEquals(FieldTypeMetadata.TYPE_TEXT, nameField.fieldType, 'Name should be a TEXT field');
        System.assert(nameField.validOperators.contains('LIKE'), 'TEXT fields should allow LIKE operator');
        System.assertEquals(true, nameField.isRequired, 'Name should be required');
        System.assertEquals(true, nameField.isUpdateable, 'Name should be updateable');
    }

    @isTest
    static void testGetAccessibleFieldOptions_PicklistValues() {
        Test.startTest();
        List<SchemaFieldOption> options = SecurityService.getAccessibleFieldOptions('Account');
        Test.stopTest();

        SchemaFieldOption picklistField = null;
        for (SchemaFieldOption opt : options) {
            if (opt.fieldType == FieldTypeMetadata.TYPE_PICKLIST) {
                picklistField = opt;
                break;
            }
        }

        System.assertNotEquals(null, picklistField, 'Should include at least one picklist field');
        System.assertNotEquals(null, picklistField.picklistValues, 'Picklist values should be initialized');
        System.assert(picklistField.picklistValues.size() > 0, 'Picklist fields should include values');
    }

    @isTest
    static void testGetAccessibleFieldOptions_ReferenceOperators() {
        Test.startTest();
        List<SchemaFieldOption> options = SecurityService.getAccessibleFieldOptions('Account');
        Test.stopTest();

        SchemaFieldOption referenceField = null;
        for (SchemaFieldOption opt : options) {
            if (opt.fieldType == FieldTypeMetadata.TYPE_REFERENCE) {
                referenceField = opt;
                break;
            }
        }

        System.assertNotEquals(null, referenceField, 'Should include at least one reference field');
        System.assert(!referenceField.validOperators.contains('LIKE'), 'REFERENCE fields should not allow LIKE');
        System.assert(referenceField.validOperators.contains('IN'), 'REFERENCE fields should allow IN');
    }

    @isTest
    static void testGetAccessibleFieldOptions_InvalidObject() {
        // Test with non-existent object
        Test.startTest();
        List<SchemaFieldOption> options = SecurityService.getAccessibleFieldOptions('InvalidObject__c');
        Test.stopTest();
        
        System.assertEquals(0, options.size(), 'Should return empty list for invalid object');
    }

    @isTest
    static void testGetAccessibleFieldOptions_EmptyObjectName() {
        // Test with blank object name
        Test.startTest();
        List<SchemaFieldOption> options = SecurityService.getAccessibleFieldOptions('');
        Test.stopTest();
        
        System.assertEquals(0, options.size(), 'Should return empty list for blank object');
    }

    @isTest
    static void testGetAccessibleFieldOptions_NullObjectName() {
        // Test with null object name
        Test.startTest();
        List<SchemaFieldOption> options = SecurityService.getAccessibleFieldOptions(null);
        Test.stopTest();
        
        System.assertEquals(0, options.size(), 'Should return empty list for null object');
    }

    @isTest
    static void testGetAccessibleFieldOptions_Sorted() {
        // Test that results are sorted by label
        Test.startTest();
        List<SchemaFieldOption> options = SecurityService.getAccessibleFieldOptions('Account');
        Test.stopTest();
        
        // Verify sorting (compare adjacent elements)
        for (Integer i = 0; i < options.size() - 1; i++) {
            String currentLabel = options[i].label != null ? options[i].label.toLowerCase() : '';
            String nextLabel = options[i + 1].label != null ? options[i + 1].label.toLowerCase() : '';
            System.assert(currentLabel <= nextLabel, 
                'Options should be sorted by label: "' + currentLabel + '" should come before or equal "' + nextLabel + '"');
        }
    }

    @isTest
    static void testGetAccessibleFieldOptions_Attachment() {
        // Test with Attachment object specifically
        Test.startTest();
        List<SchemaFieldOption> options = SecurityService.getAccessibleFieldOptions('Attachment');
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Should return options for Attachment');
        System.assert(options.size() > 0, 'Attachment should have accessible fields');
        
        // Verify at least one field has both label and value
        Boolean foundValidOption = false;
        for (SchemaFieldOption opt : options) {
            if (String.isNotBlank(opt.label) && String.isNotBlank(opt.value) && String.isNotBlank(opt.fieldType)) {
                foundValidOption = true;
                break;
            }
        }
        System.assert(foundValidOption, 'At least one option should have valid label, value, and fieldType');
    }
}