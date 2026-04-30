/**
 * @description Test data factory for creating records used by Apex unit tests.
 *              Provides helpers to create parent records and related
 *              Attachment records for reporting scenarios.
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */
@IsTest
public class TestDataFactory {

    /**
     * @description Creates an Account with a related Attachment test record.
     */
    public static void createAttachment() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Attachment att = new Attachment();
        att.Name = 'TestFile.txt';
        att.Body = Blob.valueOf('Test Content');
        att.ParentId = acc.Id;
        insert att;
    }
}