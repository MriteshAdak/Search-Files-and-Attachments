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
        SchemaFieldOption option = new SchemaFieldOption('Account Name', 'Name');
        Test.stopTest();
        
        System.assertEquals('Account Name', option.label, 'Label should match constructor parameter');
        System.assertEquals('Name', option.value, 'Value should match constructor parameter');
    }
    
    @isTest
    static void testSerialization() {
        // Test that DTO can be serialized for LWC consumption
        SchemaFieldOption option = new SchemaFieldOption('Test Label', 'TestValue');
        
        Test.startTest();
        String jsonStr = JSON.serialize(option);
        Test.stopTest();
        
        System.assert(jsonStr.contains('label'), 'JSON should contain label property');
        System.assert(jsonStr.contains('value'), 'JSON should contain value property');
        System.assert(jsonStr.contains('Test Label'), 'JSON should contain label value');
        System.assert(jsonStr.contains('TestValue'), 'JSON should contain API name value');
    }
    
    @isTest
    static void testDeserialization() {
        // Test that DTO can be deserialized from JSON
        String jsonStr = '{"label":"Test Label","value":"TestValue"}';
        
        Test.startTest();
        SchemaFieldOption option = (SchemaFieldOption)JSON.deserialize(
            jsonStr, 
            SchemaFieldOption.class
        );
        Test.stopTest();
        
        System.assertEquals('Test Label', option.label, 'Label should deserialize correctly');
        System.assertEquals('TestValue', option.value, 'Value should deserialize correctly');
    }
    
    @isTest
    static void testNullValues() {
        // Test handling of null values
        Test.startTest();
        SchemaFieldOption option = new SchemaFieldOption(null, null);
        Test.stopTest();
        
        System.assertEquals(null, option.label, 'Should allow null label');
        System.assertEquals(null, option.value, 'Should allow null value');
    }
    
    @isTest
    static void testEmptyStrings() {
        // Test handling of empty strings
        Test.startTest();
        SchemaFieldOption option = new SchemaFieldOption('', '');
        Test.stopTest();
        
        System.assertEquals('', option.label, 'Should allow empty label');
        System.assertEquals('', option.value, 'Should allow empty value');
    }
    
    @isTest
    static void testMultipleInstances() {
        // Test creating multiple instances
        Test.startTest();
        SchemaFieldOption option1 = new SchemaFieldOption('Label 1', 'Value1');
        SchemaFieldOption option2 = new SchemaFieldOption('Label 2', 'Value2');
        Test.stopTest();
        
        System.assertNotEquals(option1.label, option2.label, 'Instances should be independent');
        System.assertNotEquals(option1.value, option2.value, 'Instances should be independent');
    }
}