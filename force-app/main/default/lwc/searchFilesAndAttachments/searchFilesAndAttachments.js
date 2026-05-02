import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, MessageContext } from 'lightning/messageService';
import QUERY_MESSAGE_CHANNEL from '@salesforce/messageChannel/queryMessageChannel__c';
import executeQuery from '@salesforce/apex/QueryController.executeQuery';

export default class SearchFilesAndAttachments extends LightningElement {
	@wire(MessageContext)
	messageContext;

	currentRequestId;
	isQueryExecuting = false;
	pendingRequests = new Map(); // Track pending requests for deduplication

	handleQuerySubmit(event) {
		const detail = event?.detail || {};
		const requestId = detail.requestId;
		const query = detail.query;

		if (!requestId || !query) {
			return;
		}

		// Create request signature for deduplication
		const requestSignature = JSON.stringify({
			object: query.object,
			fields: [...query.fields].sort(), // Sort for consistent comparison
			filters: query.filters,
			limit: query.limit
		});

		// Check if identical request is already pending
		if (this.pendingRequests.has(requestSignature)) {
			console.log('Duplicate request detected, ignoring:', requestId);
			return;
		}

		this.currentRequestId = requestId;
		this.isQueryExecuting = true;
		this.pendingRequests.set(requestSignature, requestId);

		this.publishQueryStarted(requestId, query);
		this.executeQueryAsync(requestId, query, requestSignature);
	}

	handleQueryCancel(event) {
		const requestId = event?.detail?.requestId;

		if (!requestId) {
			return;
		}

		this.isQueryExecuting = false;
		this.publishQueryCancelled(requestId);
		this.showToast('Query Cancelled', 'Query execution cancelled', 'info');
	}

	async executeQueryAsync(requestId, query, requestSignature) {
		try {
			const results = await executeQuery({
				objectName: query.object,
				fields: query.fields,
				filters: query.filters,
				limitValue: query.limit
			});

			if (requestId !== this.currentRequestId) {
				// Cleanup pending request even if not current
				this.pendingRequests.delete(requestSignature);
				return;
			}

			this.isQueryExecuting = false;
			this.pendingRequests.delete(requestSignature);
			this.publishQuerySuccess(requestId, results, query);
			this.showToast(
				'Query Successful',
				'Found ' + results.length + ' record(s)',
				'success'
			);
		} catch (error) {
			// Cleanup pending request on error
			this.pendingRequests.delete(requestSignature);

			if (requestId !== this.currentRequestId) {
				return;
			}

			this.isQueryExecuting = false;
			const errorMessage = this.getErrorMessage(error);
			this.publishQueryError(requestId, errorMessage);
			this.showToast('Query Error', errorMessage, 'error');
		}
	}

	publishQueryStarted(requestId, query) {
		publish(this.messageContext, QUERY_MESSAGE_CHANNEL, {
			eventType: 'queryStarted',
			requestId,
			timestamp: new Date().toISOString(),
			query
		});
	}

	publishQuerySuccess(requestId, results, query) {
		publish(this.messageContext, QUERY_MESSAGE_CHANNEL, {
			eventType: 'querySuccess',
			requestId,
			timestamp: new Date().toISOString(),
			results: JSON.parse(JSON.stringify(results)),
			query: JSON.parse(JSON.stringify(query))
		});
	}

	publishQueryError(requestId, errorMessage) {
		publish(this.messageContext, QUERY_MESSAGE_CHANNEL, {
			eventType: 'queryError',
			requestId,
			timestamp: new Date().toISOString(),
			error: errorMessage
		});
	}

	publishQueryCancelled(requestId) {
		publish(this.messageContext, QUERY_MESSAGE_CHANNEL, {
			eventType: 'queryCancelled',
			requestId,
			timestamp: new Date().toISOString()
		});
	}

	getErrorMessage(error) {
		return error?.body?.message || error?.message || 'Unexpected query error';
	}

	showToast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
	}
}