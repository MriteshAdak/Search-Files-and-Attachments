import { LightningElement, track, wire } from 'lwc';
import {
	subscribe,
	unsubscribe,
	APPLICATION_SCOPE,
	MessageContext
} from 'lightning/messageService';
import QUERY_MESSAGE_CHANNEL from '@salesforce/messageChannel/queryMessageChannel__c';
import { NavigationMixin } from 'lightning/navigation';

export default class QueryResults extends NavigationMixin(LightningElement) {
	@wire(MessageContext)
	messageContext;

	subscription = null;

	@track results = [];
	@track columns = [];
	isLoading = false;
	error;
	currentRequestId;
	queryMetadata;

	connectedCallback() {
		this.subscribeToMessageChannel();
	}

	disconnectedCallback() {
		this.unsubscribeFromMessageChannel();
	}

	subscribeToMessageChannel() {
		if (this.subscription) {
			return;
		}

		this.subscription = subscribe(
			this.messageContext,
			QUERY_MESSAGE_CHANNEL,
			(message) => this.handleQueryMessage(message),
			{ scope: APPLICATION_SCOPE }
		);
	}

	unsubscribeFromMessageChannel() {
		if (!this.subscription) {
			return;
		}

		unsubscribe(this.subscription);
		this.subscription = null;
	}

	handleQueryMessage(message) {
		const eventType = message?.eventType;

		switch (eventType) {
			case 'queryStarted':
				this.handleQueryStarted(message);
				break;
			case 'querySuccess':
				this.handleQuerySuccess(message);
				break;
			case 'queryError':
				this.handleQueryError(message);
				break;
			case 'queryCancelled':
				this.handleQueryCancelled(message);
				break;
			default:
				break;
		}
	}

	handleQueryStarted(message) {
		this.currentRequestId = message.requestId;
		this.isLoading = true;
		this.error = undefined;
		this.queryMetadata = message.query;
		this.results = [];
		this.columns = [];
	}

	handleQuerySuccess(message) {
		if (message.requestId !== this.currentRequestId) {
			return;
		}

		this.isLoading = false;
		this.results = message.results || [];
		this.queryMetadata = message.query;
		this.error = undefined;

		const fields = message.query?.fields || [];
		if (fields.length > 0) {
			this.generateDynamicColumns(fields, message.query?.object);
		} else {
			this.columns = [];
		}
	}

	handleQueryError(message) {
		if (message.requestId !== this.currentRequestId) {
			return;
		}

		this.isLoading = false;
		this.error = message.error;
		this.results = [];
		this.columns = [];
	}

	handleQueryCancelled(message) {
		if (message.requestId !== this.currentRequestId) {
			return;
		}

		this.isLoading = false;
		this.results = [];
		this.columns = [];
	}

	generateDynamicColumns(fields, objectName) {
		this.columns = (fields || []).map((fieldName) => {
			const columnType = this.inferColumnType(fieldName);
			const column = {
				label: this.getFieldLabel(fieldName),
				fieldName,
				type: columnType,
				sortable: true
			};

			const typeAttributes = this.getTypeAttributes(fieldName, columnType, objectName);
			if (typeAttributes) {
				column.typeAttributes = typeAttributes;
			}

			return column;
		});
	}

	getFieldLabel(fieldName) {
		return String(fieldName)
			.replace(/__c$/i, '')
			.replace(/([A-Z])/g, ' $1')
			.trim()
			.replace(/\s+/g, ' ');
	}

	inferColumnType(fieldName) {
		const lowerField = String(fieldName).toLowerCase();

		if (fieldName === 'Id' || lowerField === 'id') {
			return 'url';
		}

		if (lowerField.includes('date') || lowerField.includes('time')) {
			return 'date';
		}

		if (
			lowerField.includes('amount') ||
			lowerField.includes('price') ||
			lowerField.includes('value') ||
			lowerField.includes('total') ||
			lowerField.includes('length') ||
			lowerField.includes('size') ||
			lowerField.includes('count')
		) {
			return 'number';
		}

		if (lowerField.includes('currency')) {
			return 'currency';
		}

		if (lowerField.includes('percent') || lowerField.includes('rate')) {
			return 'percent';
		}

		if (lowerField.includes('email')) {
			return 'email';
		}

		if (lowerField.includes('phone') || lowerField.includes('fax')) {
			return 'phone';
		}

		if (
			lowerField.includes('url') ||
			lowerField.includes('link') ||
			lowerField.includes('website')
		) {
			return 'url';
		}

		if (
			lowerField.startsWith('is') ||
			lowerField.startsWith('has') ||
			lowerField.startsWith('can')
		) {
			return 'boolean';
		}

		return 'text';
	}

	getTypeAttributes(fieldName, columnType, objectName) {
		if (fieldName === 'Id') {
			return {
				label: { fieldName: 'Id' },
				target: '_blank',
				tooltip: 'View Record'
			};
		}

		if (columnType === 'date') {
			return {
				year: 'numeric',
				month: '2-digit',
				day: '2-digit',
				hour: '2-digit',
				minute: '2-digit'
			};
		}

		if (columnType === 'number') {
			return {
				minimumFractionDigits: 0,
				maximumFractionDigits: 2
			};
		}

		if (columnType === 'currency') {
			return {
				currencyCode: 'USD',
				currencyDisplayAs: 'symbol'
			};
		}

		if (columnType === 'percent') {
			return {
				minimumFractionDigits: 0,
				maximumFractionDigits: 2
			};
		}

		return null;
	}

	handleRowAction(event) {
		const actionName = event.detail.action.name;
		const row = event.detail.row;

		if (actionName === 'view_record' && row.Id) {
			this[NavigationMixin.Navigate]({
				type: 'standard__recordPage',
				attributes: {
					recordId: row.Id,
					objectApiName: this.queryMetadata?.object,
					actionName: 'view'
				}
			});
		}
	}

	handleExportCSV() {
		if (!this.results || this.results.length === 0) {
			return;
		}

		try {
			const csv = this.convertToCSV(this.results, this.queryMetadata?.fields || []);
			const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
			const url = window.URL.createObjectURL(blob);
			const link = document.createElement('a');
			link.href = url;
			link.download = `query_results_${this.queryMetadata?.object || 'data'}_${Date.now()}.csv`;
			link.click();
			window.URL.revokeObjectURL(url);
		} catch (error) {
			// eslint-disable-next-line no-console
			console.error('Error exporting CSV:', error);
		}
	}

	convertToCSV(data, fields) {
		const header = fields
			.map((field) => `"${this.getFieldLabel(field)}"`)
			.join(',');

		const rows = (data || []).map((record) =>
			fields
				.map((field) => {
					const value = record[field];
					if (value === null || value === undefined) {
						return '';
					}
					const stringValue = String(value).replace(/"/g, '""');
					return `"${stringValue}"`;
				})
				.join(',')
		);

		return [header, ...rows].join('\n');
	}

	get hasResults() {
		return this.results.length > 0;
	}

	get hasError() {
		return Boolean(this.error);
	}

	get showEmptyState() {
		return !this.isLoading && !this.hasError && !this.hasResults && !this.queryMetadata;
	}

	get showNoResultsMessage() {
		return !this.isLoading && !this.hasError && !this.hasResults && Boolean(this.queryMetadata);
	}

	get resultCount() {
		return this.results.length;
	}

	get resultSummary() {
		const count = this.resultCount;
		return `${count} record${count !== 1 ? 's' : ''}`;
	}

	get exportButtonDisabled() {
		return !this.hasResults;
	}
}