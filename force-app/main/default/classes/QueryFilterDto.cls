/**
 * @description Data Transfer Object (DTO) representing a single filter condition in a query.
 *              Contains the field name, operator, and value(s) for filtering.
 * 
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */

public inherited sharing class QueryFilterDto {
    /**
     * @description The API name of the field to filter on
     */
    @AuraEnabled 
    public String fieldName { get; set; }
    
    /**
     * @description The operator to use for comparison (e.g., '=', 'LIKE', 'IN')
     */
    @AuraEnabled 
    public String operator { get; set; }
    
    /**
     * @description The value(s) to filter by. For multi-value operators (IN, NOT IN, INCLUDES, EXCLUDES),
     *              this should be a comma or semicolon-separated string which should be parsed into a list.
     */
    @AuraEnabled 
    public String value { get; set; }
}