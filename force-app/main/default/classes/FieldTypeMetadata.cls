/**
 * @description Utility class for normalizing field types and mapping valid operators.
 *              Provides centralized metadata for field-type-driven query logic.
 *
 * @author Mritesh
 * @date 2026-05
 * @version 1.0.0
 */

public with sharing class FieldTypeMetadata {
    public static final String TYPE_TEXT = 'TEXT';
    public static final String TYPE_NUMBER = 'NUMBER';
    public static final String TYPE_DATE = 'DATE';
    public static final String TYPE_DATETIME = 'DATETIME';
    public static final String TYPE_BOOLEAN = 'BOOLEAN';
    public static final String TYPE_PICKLIST = 'PICKLIST';
    public static final String TYPE_MULTIPICKLIST = 'MULTIPICKLIST';
    public static final String TYPE_REFERENCE = 'REFERENCE';

    /**
     * @description Maps Schema.DisplayType to normalized type categories.
     */
    public static String normalizeFieldType(Schema.DisplayType displayType) {
        if (displayType == null) {
            return TYPE_TEXT;
        }

        switch on displayType {
            when STRING, TEXTAREA, EMAIL, PHONE, URL, ID, ENCRYPTEDSTRING {
                return TYPE_TEXT;
            }
            when INTEGER, DOUBLE, CURRENCY, PERCENT {
                return TYPE_NUMBER;
            }
            when DATE {
                return TYPE_DATE;
            }
            when DATETIME, TIME {
                return TYPE_DATETIME;
            }
            when BOOLEAN {
                return TYPE_BOOLEAN;
            }
            when PICKLIST, COMBOBOX {
                return TYPE_PICKLIST;
            }
            when MULTIPICKLIST {
                return TYPE_MULTIPICKLIST;
            }
            when REFERENCE {
                return TYPE_REFERENCE;
            }
            when else {
                return TYPE_TEXT;
            }
        }
    }

    /**
     * @description Returns valid operators for a given normalized field type.
     */
    public static List<String> getValidOperators(String normalizedType) {
        if (String.isBlank(normalizedType)) {
            return new List<String>{'=', '!='};
        }

        switch on normalizedType {
            when TYPE_TEXT {
                return new List<String>{'=', '!=', 'LIKE', 'IN', 'NOT IN'};
            }
            when TYPE_REFERENCE {
                return new List<String>{'=', '!=', 'IN', 'NOT IN'};
            }
            when TYPE_NUMBER, TYPE_DATE, TYPE_DATETIME {
                return new List<String>{'=', '!=', '<', '<=', '>', '>='};
            }
            when TYPE_BOOLEAN {
                return new List<String>{'=', '!='};
            }
            when TYPE_PICKLIST {
                return new List<String>{'=', '!=', 'IN', 'NOT IN'};
            }
            when TYPE_MULTIPICKLIST {
                return new List<String>{'INCLUDES', 'EXCLUDES'};
            }
            when else {
                return new List<String>{'=', '!='};
            }
        }
    }
}
