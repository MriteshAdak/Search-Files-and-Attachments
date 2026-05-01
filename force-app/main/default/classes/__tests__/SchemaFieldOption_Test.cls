/**
 * @description Test class for SchemaFieldOption DTO.
 *              Tests constructor, serialization, and edge cases.
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */
@isTest
private class SchemaFieldOption_Test {
    
    @isTest
    static void testConstructor() {
        // Test that constructor sets properties correctly
        Test.startTest();
        SchemaFieldOption option = new SchemaFieldOption('Account Name', 'Name', 'TEXT');
        Test.stopTest();
        
        System.assertEquals('Account Name', option.label, 'Label should match constructor parameter');
        System.assertEquals('Name', option.value, 'Value should match constructor parameter');
        System.assertEquals('TEXT', option.fieldType, 'Field type should match constructor parameter');
        System.assertEquals(0, option.picklistValues.size(), 'Picklist values should default to empty list');
        System.assertEquals(false, option.isRequired, 'isRequired should default to false');
        System.assertEquals(false, option.isUpdateable, 'isUpdateable should default to false');
        System.assertEquals(0, option.validOperators.size(), 'validOperators should default to empty list');
    }
    
    @isTest
    static void testSerialization() {
        // Test that DTO can be serialized for LWC consumption
        SchemaFieldOption option = SchemaFieldOption.builder('Test Label', 'TestValue', 'PICKLIST')
            .withPicklistValues(new List<SchemaFieldOption.PicklistValue>{
                new SchemaFieldOption.PicklistValue('Option A', 'A', true)
            })
            .withRequired(true)
            .withUpdateable(true)
            .withValidOperators(new List<String>{'=', '!='})
            .build();
        
        Test.startTest();
        String jsonStr = JSON.serialize(option);
        Test.stopTest();
        
        System.assert(jsonStr.contains('label'), 'JSON should contain label property');
        System.assert(jsonStr.contains('value'), 'JSON should contain value property');
        System.assert(jsonStr.contains('fieldType'), 'JSON should contain fieldType property');
        System.assert(jsonStr.contains('validOperators'), 'JSON should contain validOperators property');
        System.assert(jsonStr.contains('picklistValues'), 'JSON should contain picklistValues property');
    }
    
    @isTest
    static void testDeserialization() {
        // Test that DTO can be deserialized from JSON
        String jsonStr = '{"label":"Test Label","value":"TestValue","fieldType":"TEXT",' +
            '"isRequired":true,"isUpdateable":false,' +
            '"validOperators":["=","!="],' +
            '"picklistValues":[{"label":"Option A","value":"A","isDefaultValue":true}]}';
        
        Test.startTest();
        SchemaFieldOption option = (SchemaFieldOption)JSON.deserialize(
            jsonStr, 
            SchemaFieldOption.class
        );
        Test.stopTest();
        
        System.assertEquals('Test Label', option.label, 'Label should deserialize correctly');
        System.assertEquals('TestValue', option.value, 'Value should deserialize correctly');
        System.assertEquals('TEXT', option.fieldType, 'Field type should deserialize correctly');
        System.assertEquals(true, option.isRequired, 'isRequired should deserialize correctly');
        System.assertEquals(false, option.isUpdateable, 'isUpdateable should deserialize correctly');
        System.assertEquals(2, option.validOperators.size(), 'validOperators should deserialize correctly');
        System.assertEquals(1, option.picklistValues.size(), 'picklistValues should deserialize correctly');
    }
    
    @isTest
    static void testNullValues() {
        // Test handling of null values
        Test.startTest();
        SchemaFieldOption option = new SchemaFieldOption(null, null, null);
        Test.stopTest();
        
        System.assertEquals(null, option.label, 'Should allow null label');
        System.assertEquals(null, option.value, 'Should allow null value');
        System.assertEquals(null, option.fieldType, 'Should allow null fieldType');
    }
    
    @isTest
    static void testEmptyStrings() {
        // Test handling of empty strings
        Test.startTest();
        SchemaFieldOption option = new SchemaFieldOption('', '', '');
        Test.stopTest();
        
        System.assertEquals('', option.label, 'Should allow empty label');
        System.assertEquals('', option.value, 'Should allow empty value');
        System.assertEquals('', option.fieldType, 'Should allow empty fieldType');
    }
    
    @isTest
    static void testMultipleInstances() {
        // Test creating multiple instances
        Test.startTest();
        SchemaFieldOption option1 = new SchemaFieldOption('Label 1', 'Value1', 'TEXT');
        SchemaFieldOption option2 = new SchemaFieldOption('Label 2', 'Value2', 'NUMBER');
        Test.stopTest();
        
        System.assertNotEquals(option1.label, option2.label, 'Instances should be independent');
        System.assertNotEquals(option1.value, option2.value, 'Instances should be independent');
    }

    @isTest
    static void testBuilder() {
        SchemaFieldOption option = SchemaFieldOption.builder('Account Name', 'Name', 'TEXT')
            .withRequired(true)
            .withUpdateable(true)
            .withValidOperators(new List<String>{'=', '!='})
            .build();

        System.assertEquals('Account Name', option.label, 'Builder should set label');
        System.assertEquals('Name', option.value, 'Builder should set value');
        System.assertEquals('TEXT', option.fieldType, 'Builder should set fieldType');
        System.assertEquals(true, option.isRequired, 'Builder should set isRequired');
        System.assertEquals(true, option.isUpdateable, 'Builder should set isUpdateable');
        System.assertEquals(2, option.validOperators.size(), 'Builder should set validOperators');
    }
}