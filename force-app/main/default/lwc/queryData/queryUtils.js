/**
 * @description Utility module for queryData component.
 *              Contains constants, factory functions, and validation logic.
 *
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */

// Cache for field type lookups to avoid repeated array searches
const fieldTypeCache = new Map();
const fieldMetadataCache = new Map();

// Object options for the dropdown
export const OBJECT_OPTIONS = [
  { label: "Attachment", value: "Attachment" },
  { label: "Content Document", value: "ContentDocument" }
];

// Operator options with multi-value flags
export const OPERATOR_OPTIONS = [
  { label: "Equals", value: "=", supportsMultipleValues: false },
  { label: "Not Equals", value: "!=", supportsMultipleValues: false },
  { label: "Less Than", value: "<", supportsMultipleValues: false },
  { label: "Less or Equal", value: "<=", supportsMultipleValues: false },
  { label: "Greater Than", value: ">", supportsMultipleValues: false },
  { label: "Greater or Equal", value: ">=", supportsMultipleValues: false },
  { label: "Contains", value: "LIKE", supportsMultipleValues: false },
  { label: "IN", value: "IN", supportsMultipleValues: true },
  { label: "NOT IN", value: "NOT IN", supportsMultipleValues: true },
  { label: "Includes", value: "INCLUDES", supportsMultipleValues: true },
  { label: "Excludes", value: "EXCLUDES", supportsMultipleValues: true }
];

// TODO: Consider deriving multi-value operators dynamically from OPERATOR_OPTIONS property
export const MULTI_VALUE_OPERATORS = new Set([
  "IN",
  "NOT IN",
  "INCLUDES",
  "EXCLUDES"
]);

// TODO: Consider deriving multi-select operators dynamically from OPERATOR_OPTIONS property
const MULTI_SELECT_OPERATORS = new Set(["INCLUDES", "EXCLUDES"]);

/**
 * @description Factory function to create a new empty filter with default values.
 * @returns {Object} New filter object.
 */
export const createNewFilter = () => {
  return {
    id: Date.now(), // TODO: Replace with UUID for better uniqueness in real applications
    fieldName: "",
    operator: "=",
    value: "",
    supportsMultipleValues: false,
    valueItems: [],
    currentInputValue: ""
  };
};

/**
 * @description Serializes pill values into backend-safe delimiter format.
 * @param {Array} valueItems Array of pill items.
 * @param {String} operator Active filter operator.
 * @returns {String} Serialized value payload.
 */
export const serializeMultiValueItems = (valueItems = [], operator = "") => {
  const serializedValues = Array.isArray(valueItems)
    ? valueItems
        .map((item) => {
          if (typeof item === "string") {
            return item.trim();
          }

          return String(item?.label ?? "").trim();
        })
        .filter((item) => item.length > 0)
    : [];

  const delimiter = MULTI_SELECT_OPERATORS.has(operator) ? ";" : ",";
  return serializedValues.join(delimiter);
};

/**
 * @description Validates query builder inputs for inline control-level feedback.
 * @param {Object} params Validation input parameters.
 * @param {String} params.selectedObject Selected object API name.
 * @param {Array} params.selectedFields Selected field API names.
 * @param {Array} params.filters Active filter definitions.
 * @returns {Object} Validation contract with field-level errors.
 */
export const validateFilterInputs = ({
  selectedObject,
  selectedFields,
  filters
}) => {
  const fieldErrors = {
    object: "",
    fields: "",
    filters: {}
  };

  if (!selectedObject || !selectedObject.trim()) {
    fieldErrors.object = "Select an object to query.";
  }

  if (!Array.isArray(selectedFields) || selectedFields.length === 0) {
    fieldErrors.fields = "Select at least one field.";
  }

  (filters || []).forEach((filter) => {
    const filterErrors = {
      fieldName: "",
      operator: "",
      value: "",
      pillContainerHasError: false,
      pillContainerErrorMessage: ""
    };

    if (!filter?.fieldName) {
      filterErrors.fieldName = "Select a field for this condition.";
    }

    if (!filter?.operator) {
      filterErrors.operator = "Select an operator for this condition.";
    }

    const isMultiValue =
      Boolean(filter?.supportsMultipleValues) ||
      MULTI_VALUE_OPERATORS.has(filter?.operator);
    if (isMultiValue) {
      const serializedValues = serializeMultiValueItems(
        filter?.valueItems || [],
        filter?.operator
      );
      if (!serializedValues) {
        filterErrors.value =
          "Add at least one value for the selected operator.";
        filterErrors.pillContainerHasError = true;
        filterErrors.pillContainerErrorMessage =
          "Add at least one value for the selected operator.";
      }
    } else if (!String(filter?.value ?? "").trim()) {
      filterErrors.value = "Enter a value for this condition.";
    }

    if (
      filterErrors.fieldName ||
      filterErrors.operator ||
      filterErrors.value ||
      filterErrors.pillContainerHasError
    ) {
      fieldErrors.filters[filter.id] = filterErrors;
    }
  });

  const hasFilterErrors = Object.keys(fieldErrors.filters).length > 0;
  const hasErrors = Boolean(
    fieldErrors.object || fieldErrors.fields || hasFilterErrors
  );

  return {
    isValid: !hasErrors,
    fieldErrors,
    formErrorMessage: hasErrors
      ? "Please fix validation errors before running the query."
      : ""
  };
};

/**
 * @description Returns field type metadata for a given field name.
 * @param {String} fieldName Field API name.
 * @param {Array} fieldOptions SchemaFieldOption list.
 * @returns {String|null} Normalized field type.
 */
export const getFieldType = (fieldName, fieldOptions) => {
  if (!fieldName || !Array.isArray(fieldOptions)) {
    return null;
  }

  const fieldMetadata = fieldOptions.find((option) => option.value === fieldName);
  return fieldMetadata?.fieldType || null;
};

/**
 * @description Gets picklist options for a given field.
 * @param {String} fieldName Field API name.
 * @param {Array} fieldOptions SchemaFieldOption list.
 * @returns {Array} Options for lightning-combobox or lightning-checkbox-group.
 */
export const getPicklistOptionsForField = (fieldName, fieldOptions) => {
  if (!fieldName || !Array.isArray(fieldOptions)) {
    return [];
  }

  const fieldMetadata = fieldOptions.find((option) => option.value === fieldName);
  if (!fieldMetadata || !Array.isArray(fieldMetadata.picklistValues)) {
    return [];
  }

  return fieldMetadata.picklistValues.map((picklistValue) => ({
    label: picklistValue.label,
    value: picklistValue.value
  }));
};

/**
 * @description Filters operator options based on field metadata.
 * @param {String} fieldName Field API name.
 * @param {Array} fieldOptions SchemaFieldOption list.
 * @returns {Array} Filtered operator options.
 */
export const getOperatorOptionsForField = (fieldName, fieldOptions) => {
  if (!fieldName || !Array.isArray(fieldOptions)) {
    return OPERATOR_OPTIONS;
  }

  const fieldMetadata = fieldOptions.find((option) => option.value === fieldName);
  if (!fieldMetadata || !Array.isArray(fieldMetadata.validOperators)) {
    return OPERATOR_OPTIONS;
  }

  return OPERATOR_OPTIONS.filter((operator) =>
    fieldMetadata.validOperators.includes(operator.value)
  );
};

/**
 * @description Returns default operator for a field based on metadata.
 * @param {String} fieldName Field API name.
 * @param {Array} fieldOptions SchemaFieldOption list.
 * @returns {String} Operator value.
 */
export const getDefaultOperatorForField = (fieldName, fieldOptions) => {
  const operators = getOperatorOptionsForField(fieldName, fieldOptions);
  return operators.length > 0 ? operators[0].value : "=";
};

/**
 * @description Determines render configuration based on field type and operator.
 * @param {String} fieldType Normalized field type.
 * @param {String} operator Selected operator.
 * @returns {Object} Render config flags.
 */
export const getFilterRenderConfig = (fieldType, operator) => {
  const config = {
    showTextInput: false,
    showNumberInput: false,
    showDateInput: false,
    showDateTimeInput: false,
    showBooleanInput: false,
    showPicklistCombobox: false,
    showMultiPicklistCheckboxes: false,
    showMultiValuePills: false,
    supportsMultipleValues: false
  };

  if (!fieldType) {
    return config;
  }

  const isMultiValueOperator = MULTI_VALUE_OPERATORS.has(operator);

  switch (fieldType) {
    case "TEXT":
    case "REFERENCE":
      if (isMultiValueOperator) {
        config.showMultiValuePills = true;
        config.supportsMultipleValues = true;
      } else {
        config.showTextInput = true;
      }
      break;
    case "NUMBER":
      config.showNumberInput = true;
      break;
    case "DATE":
      config.showDateInput = true;
      break;
    case "DATETIME":
      config.showDateTimeInput = true;
      break;
    case "BOOLEAN":
      config.showBooleanInput = true;
      break;
    case "PICKLIST":
      if (isMultiValueOperator) {
        config.showMultiValuePills = true;
        config.supportsMultipleValues = true;
      } else {
        config.showPicklistCombobox = true;
      }
      break;
    case "MULTIPICKLIST":
      config.showMultiPicklistCheckboxes = true;
      config.supportsMultipleValues = true;
      break;
    default:
      config.showTextInput = true;
  }

  return config;
};

/**
 * Gets field metadata with memoization.
 */
export const getFieldMetadata = (fieldName, fieldOptions, objectName = 'default') => {
  if (!fieldName || !Array.isArray(fieldOptions)) {
    return null;
  }

  const cacheKey = `${objectName}_${fieldName}`;

  if (fieldMetadataCache.has(cacheKey)) {
    return fieldMetadataCache.get(cacheKey);
  }

  const fieldMetadata = fieldOptions.find((option) => option.value === fieldName);

  if (fieldMetadata) {
    fieldMetadataCache.set(cacheKey, fieldMetadata);
  }

  return fieldMetadata || null;
};

/**
 * Clears cache when object changes.
 * Call this when switching objects to prevent stale cache.
 */
export const clearFieldCache = () => {
  fieldTypeCache.clear();
  fieldMetadataCache.clear();
};

/**
 * Debounce function for performance optimization.
 */
export function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func.apply(this, args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}
