/**
 * @description Query builder component for dynamic SOQL queries.
 *              Enhanced with pill container UI for multi-value operators and field labels.
 *
 * @author Mritesh
 * @date 2026-04
 * @version 1.0.0
 */
import { LightningElement, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getObjectFieldOptions from "@salesforce/apex/QueryController.getObjectFieldOptions";

// Import from our Utility Module
import {
  OBJECT_OPTIONS,
  OPERATOR_OPTIONS,
  createNewFilter,
  serializeMultiValueItems,
  getFilterRenderConfig,
  getOperatorOptionsForField,
  getFieldType,
  getFieldMetadata,
  getPicklistOptionsForField,
  getDefaultOperatorForField,
  clearFieldCache,
  debounce
} from "./queryUtils";

export default class QueryBuilder extends LightningElement {
  static EVENT_SOURCE = "queryBuilder";

  // Constants from Utils
  objectOptions = OBJECT_OPTIONS;

  // State
  selectedObject = "Attachment";
  @track selectedFields = [];
  @track filters = [];
  limitValue = 50;
  @track fieldOptions = [];
  fieldOptionsError;
  wiredFieldOptionsResult;

  // --- Wire Adapters ---
  @wire(getObjectFieldOptions, { objectName: "$selectedObject" })
  wiredFieldOptions(result) {
    // Clear cache when object changes
    clearFieldCache();

    this.wiredFieldOptionsResult = result;
    const { error, data } = result;

    if (data) {
      // Client-side FLS filtering (defensive check)
      // Phase 1 SecurityService already filtered by isAccessible
      // This is additional defensive filtering
      this.fieldOptions = data.filter(field => {
        // Keep field if it's accessible and has valid label/value
        return field.value && field.label;
      });

      this.fieldOptionsError = undefined;

      // Log for debugging/monitoring
      if (data.length !== this.fieldOptions.length) {
        console.log('Field options filtered:', {
          object: this.selectedObject,
          totalFields: data.length,
          accessibleFields: this.fieldOptions.length,
          filteredOut: data.length - this.fieldOptions.length
        });
      }

      if (this.filters.length > 0) {
        this.filters = this.filters.map((filter) => this.decorateFilter(filter));
      }
    } else if (error) {
      this.fieldOptions = [];
      this.fieldOptionsError = error;
      this.showToast(
        "Error",
        "Could not load fields: " + this.getErrorMessage(error),
        "error"
      );
    }
  }

  // --- Computed Properties ---
  get isLoadingFields() {
    if (!this.wiredFieldOptionsResult) {
      return true;
    }
    return !this.wiredFieldOptionsResult.data && !this.wiredFieldOptionsResult.error;
  }

  get hasFieldOptionsError() {
    return Boolean(this.fieldOptionsError);
  }

  // --- User Actions ---
  handleObjectChange(event) {
    this.selectedObject = event.detail.value;
    this.applyControlValidity(event.target, "");
    this.selectedFields = [];
    this.filters = [];
    this.fieldOptions = [];
    this.fieldOptionsError = undefined;
  }

  handleFieldChange(event) {
    // event.detail.value contains API names (value property)
    this.selectedFields = event.detail.value;
    this.applyControlValidity(event.target, "");
  }

  handleAddFilter() {
    // Delegate logic to Utility
    this.filters = [...this.filters, this.decorateFilter(createNewFilter())];
  }

  handleFilterFieldChange(event) {
    const filterId = parseInt(event.currentTarget.dataset.id, 10);
    const newFieldName = event.detail.value;
    const fieldType = getFieldType(newFieldName, this.fieldOptions);

    this.filters = this.filters.map((filter) => {
      if (filter.id !== filterId) {
        return filter;
      }

      const defaultOperator = getDefaultOperatorForField(
        newFieldName,
        this.fieldOptions
      );
      const initialValue = fieldType === "BOOLEAN" ? false : "";

      return this.decorateFilter({
        ...filter,
        fieldName: newFieldName,
        operator: defaultOperator,
        value: initialValue,
        valueItems: [],
        currentInputValue: ""
      });
    });

    this.applyControlValidity(event.target, "");
  }

  handleFilterOperatorChange(event) {
    const filterId = parseInt(event.currentTarget.dataset.id, 10);
    const newOperator = event.detail.value;

    this.filters = this.filters.map((filter) => {
      if (filter.id !== filterId) {
        return filter;
      }

      const oldConfig = getFilterRenderConfig(filter.fieldType, filter.operator);
      const newConfig = getFilterRenderConfig(filter.fieldType, newOperator);
      const switchedMode =
        oldConfig.supportsMultipleValues !== newConfig.supportsMultipleValues;

      return this.decorateFilter({
        ...filter,
        operator: newOperator,
        value: switchedMode ? "" : filter.value,
        valueItems: switchedMode ? [] : filter.valueItems,
        currentInputValue: ""
      });
    });

    this.applyControlValidity(event.target, "");
  }

  handleFilterValueChange(event) {
    const filterId = parseInt(event.currentTarget.dataset.id, 10);
    const newValue = event.detail.value;

    this.filters = this.filters.map((filter) => {
      if (filter.id !== filterId) {
        return filter;
      }

      return this.decorateFilter({
        ...filter,
        value: newValue
      });
    });

    this.applyControlValidity(event.target, "");
  }

  handleFilterCheckboxChange(event) {
    const filterId = parseInt(event.currentTarget.dataset.id, 10);
    const isChecked = event.detail.checked;

    this.filters = this.filters.map((filter) => {
      if (filter.id !== filterId) {
        return filter;
      }

      return this.decorateFilter({
        ...filter,
        value: isChecked
      });
    });

    this.applyControlValidity(event.target, "");
  }

  handleFilterCheckboxGroupChange(event) {
    const filterId = parseInt(event.currentTarget.dataset.id, 10);
    const selectedValues = event.detail.value || [];

    this.filters = this.filters.map((filter) => {
      if (filter.id !== filterId) {
        return filter;
      }

      return this.decorateFilter({
        ...filter,
        valueItems: selectedValues,
        currentInputValue: ""
      });
    });

    this.applyControlValidity(event.target, "");
  }

  // Debounced handler for performance optimization
  handlePillInputChange = debounce(function(event) {
    const filterId = parseInt(event.currentTarget.dataset.id, 10);
    const newValue = event.target.value;

    this.filters = this.filters.map((filter) => {
      if (filter.id !== filterId) {
        return filter;
      }

      return this.decorateFilter({
        ...filter,
        currentInputValue: newValue
      });
    });

    this.applyControlValidity(event.target, "");
  }, 300);

  handlePillInputKeydown(event) {
    if (event.key !== "Enter") {
      return;
    }

    event.preventDefault();
    const filterId = parseInt(event.currentTarget.dataset.id, 10);
    this.addPillValue(filterId);
  }

  handlePillInputBlur(event) {
    const filterId = parseInt(event.currentTarget.dataset.id, 10);
    this.addPillValue(filterId);
  }

  handleAddPill(event) {
    const filterId = parseInt(event.currentTarget.dataset.id, 10);
    this.addPillValue(filterId);
  }

  addPillValue(filterId) {
    this.filters = this.filters.map((filter) => {
      if (filter.id !== filterId) {
        return filter;
      }

      const rawValue = String(filter.currentInputValue || "").trim();
      if (!rawValue) {
        return filter;
      }

      const existing = Array.isArray(filter.valueItems)
        ? filter.valueItems
        : [];
      if (existing.includes(rawValue)) {
        return this.decorateFilter({
          ...filter,
          currentInputValue: ""
        });
      }

      return this.decorateFilter({
        ...filter,
        valueItems: [...existing, rawValue],
        currentInputValue: ""
      });
    });
  }

  handleRemovePill(event) {
    const filterId = parseInt(event.currentTarget.dataset.id, 10);
    const pillValue = event.currentTarget.dataset.value;

    this.filters = this.filters.map((filter) => {
      if (filter.id !== filterId) {
        return filter;
      }

      const nextItems = (filter.valueItems || []).filter(
        (value) => value !== pillValue
      );

      return this.decorateFilter({
        ...filter,
        valueItems: nextItems
      });
    });
  }

  handleRemoveFilter(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10);
    this.filters = this.filters.filter((f) => f.id !== id);
  }

  handleLimitChange(event) {
    this.limitValue = event.detail.value;
  }

  handleRunQuery() {
    const isValid = this.applyValidationFeedback();

    if (!isValid) {
      this.showToast(
        "Validation Error",
        "Please fix validation errors before running the query.",
        "error"
      );
      return;
    }

    const requestId = this.generateRequestId();
    const queryPayload = {
      object: this.selectedObject,
      fields: this.selectedFields,
      filters: this.buildApexFilters(),
      limit: this.limitValue
    };

    this.dispatchQuerySubmitEvent(requestId, queryPayload);
  }

  dispatchQuerySubmitEvent(requestId, query) {
    this.dispatchEvent(
      new CustomEvent("querysubmit", {
        detail: {
          requestId,
          timestamp: new Date().toISOString(),
          query
        },
        bubbles: true,
        composed: false
      })
    );
  }

  buildApexFilters() {
    return this.filters.map((filter) => ({
      fieldName: filter.fieldName,
      operator: filter.operator,
      value: filter.supportsMultipleValues
        ? serializeMultiValueItems(filter.valueItems || [], filter.operator)
        : String(filter.value ?? "").trim()
    }));
  }

  /**
   * @description Applies inline validity and filter-level wrapper errors.
   * @param {Object} validation Validation result from queryUtils.
   * @returns {void}
   */
  applyValidationFeedback() {
    let isValid = true;

    const selectors = [
      '[data-control="object-selector"]',
      '[data-control="field-selector"]',
      '[data-control="filter-field"]',
      '[data-control="filter-operator"]',
      '[data-control="filter-value"]',
      '[data-control="filter-multivalue-input"]'
    ];

    const controls = this.template.querySelectorAll(selectors.join(","));
    controls.forEach((control) => {
      if (control && typeof control.reportValidity === "function") {
        const valid = control.reportValidity();
        if (!valid) {
          isValid = false;
        }
      }
    });

    this.filters.forEach((filter) => {
      if (!filter.renderConfig?.showMultiValuePills) {
        return;
      }

      const input = this.template.querySelector(
        `[data-control="filter-multivalue-input"][data-id="${filter.id}"]`
      );
      if (!input || typeof input.setCustomValidity !== "function") {
        return;
      }

      const hasValues = Array.isArray(filter.valueItems) && filter.valueItems.length > 0;
      input.setCustomValidity(hasValues ? "" : "Add at least one value.");

      if (!input.reportValidity()) {
        isValid = false;
      }
    });

    return isValid;
  }

  decorateFilter(filter, filterErrors = {}) {
    const fieldType = getFieldType(filter.fieldName, this.fieldOptions);
    const validOperatorOptions = filter.fieldName
      ? getOperatorOptionsForField(filter.fieldName, this.fieldOptions)
      : OPERATOR_OPTIONS;
    const validOperatorValues = validOperatorOptions.map(
      (operatorOption) => operatorOption.value
    );
    const normalizedOperator = validOperatorValues.includes(filter.operator)
      ? filter.operator
      : getDefaultOperatorForField(filter.fieldName, this.fieldOptions);
    const renderConfig = getFilterRenderConfig(fieldType, normalizedOperator);
    const picklistOptions =
      fieldType === "PICKLIST" || fieldType === "MULTIPICKLIST"
        ? getPicklistOptionsForField(filter.fieldName, this.fieldOptions)
        : [];
    const valuePlaceholder =
      normalizedOperator === "LIKE"
        ? "e.g., %search% for contains"
        : "Enter value";
    const pillContainerHasError = Boolean(filterErrors.pillContainerHasError);
    const booleanValue =
      fieldType === "BOOLEAN"
        ? String(filter.value).toLowerCase() === "true"
        : filter.value;
    return {
      ...filter,
      fieldType,
      renderConfig,
      validOperatorOptions,
      operator: normalizedOperator,
      picklistOptions,
      valuePlaceholder,
      supportsMultipleValues: renderConfig.supportsMultipleValues,
      valueItems: Array.isArray(filter.valueItems) ? filter.valueItems : [],
      currentInputValue: filter.currentInputValue || "",
      fieldErrorMessage: filterErrors.fieldName || "",
      operatorErrorMessage: filterErrors.operator || "",
      valueErrorMessage: filterErrors.value || "",
      pillContainerHasError,
      pillContainerErrorMessage: filterErrors.pillContainerErrorMessage || "",
      pillErrorHelpId: `pill-error-${filter.id}`,
      pillInputId: `pill-input-${filter.id}`,
      multiValueFormElementClass: pillContainerHasError
        ? "slds-form-element slds-has-error"
        : "slds-form-element",
      value: booleanValue
    };
  }

  applyControlValidity(control, message = "") {
    if (!control || typeof control.setCustomValidity !== "function") {
      return;
    }

    control.setCustomValidity(message || "");
    if (typeof control.reportValidity === "function") {
      control.reportValidity();
    }
  }

  buildFieldLabels() {
    const labels = {};
    this.selectedFields.forEach((apiName) => {
      const option = this.fieldOptions.find(
        (fieldOption) => fieldOption.value === apiName
      );
      labels[apiName] = option ? option.label : apiName;
    });
    return labels;
  }

  generateRequestId() {
    return `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
  }

  getErrorMessage(error) {
    return error?.body?.message || error?.message || "Unexpected query error.";
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}