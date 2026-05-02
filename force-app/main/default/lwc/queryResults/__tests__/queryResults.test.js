import { createElement } from 'lwc';
import { registerTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import QueryResults from 'c/queryResults';
import { MessageContext, subscribe, unsubscribe } from 'lightning/messageService';

jest.mock('lightning/messageService', () => {
    const original = jest.requireActual('lightning/messageService');
    return {
        ...original,
        subscribe: jest.fn(),
        unsubscribe: jest.fn()
    };
});

const messageContextAdapter = registerTestWireAdapter(MessageContext);

const flushPromises = () => Promise.resolve();

describe('c-query-results', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('shows empty state before any query', async () => {
        const element = createElement('c-query-results', {
            is: QueryResults
        });
        document.body.appendChild(element);

        messageContextAdapter.emit({});
        await flushPromises();

        const emptyHeading = element.shadowRoot.querySelector('h3');
        expect(emptyHeading).toBeTruthy();
    });

    it('subscribes on connect and unsubscribes on disconnect', async () => {
        subscribe.mockReturnValue({ id: 'sub-1' });

        const element = createElement('c-query-results', {
            is: QueryResults
        });
        document.body.appendChild(element);

        messageContextAdapter.emit({});
        await flushPromises();

        expect(subscribe).toHaveBeenCalled();

        document.body.removeChild(element);
        expect(unsubscribe).toHaveBeenCalled();
    });

    it('shows loading state on queryStarted', async () => {
        let handler;
        subscribe.mockImplementation((context, channel, callback) => {
            handler = callback;
            return { id: 'sub-1' };
        });

        const element = createElement('c-query-results', {
            is: QueryResults
        });
        document.body.appendChild(element);

        messageContextAdapter.emit({});
        await flushPromises();

        handler({
            eventType: 'queryStarted',
            requestId: 'test-123',
            query: { object: 'Account', fields: ['Name'] }
        });

        await flushPromises();
        const spinner = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner).toBeTruthy();
    });

    it('renders results and summary on querySuccess', async () => {
        let handler;
        subscribe.mockImplementation((context, channel, callback) => {
            handler = callback;
            return { id: 'sub-1' };
        });

        const element = createElement('c-query-results', {
            is: QueryResults
        });
        document.body.appendChild(element);

        messageContextAdapter.emit({});
        await flushPromises();

        handler({
            eventType: 'queryStarted',
            requestId: 'test-123',
            query: { object: 'Account', fields: ['Name'] }
        });

        handler({
            eventType: 'querySuccess',
            requestId: 'test-123',
            results: [{ Id: '001', Name: 'Test' }],
            query: { object: 'Account', fields: ['Name'] }
        });

        await flushPromises();
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        const badge = element.shadowRoot.querySelector('lightning-badge');
        expect(datatable).toBeTruthy();
        expect(badge).toBeTruthy();
    });

    it('renders no results message on querySuccess with empty results', async () => {
        let handler;
        subscribe.mockImplementation((context, channel, callback) => {
            handler = callback;
            return { id: 'sub-1' };
        });

        const element = createElement('c-query-results', {
            is: QueryResults
        });
        document.body.appendChild(element);

        messageContextAdapter.emit({});
        await flushPromises();

        handler({
            eventType: 'queryStarted',
            requestId: 'test-123',
            query: { object: 'Account', fields: ['Name'] }
        });

        handler({
            eventType: 'querySuccess',
            requestId: 'test-123',
            results: [],
            query: { object: 'Account', fields: ['Name'] }
        });

        await flushPromises();
        const warningIcon = element.shadowRoot.querySelector(
            'lightning-icon[icon-name="utility:warning"]'
        );
        expect(warningIcon).toBeTruthy();
    });

    it('renders error state on queryError', async () => {
        let handler;
        subscribe.mockImplementation((context, channel, callback) => {
            handler = callback;
            return { id: 'sub-1' };
        });

        const element = createElement('c-query-results', {
            is: QueryResults
        });
        document.body.appendChild(element);

        messageContextAdapter.emit({});
        await flushPromises();

        handler({
            eventType: 'queryStarted',
            requestId: 'test-123',
            query: { fields: ['Name'] }
        });

        handler({
            eventType: 'queryError',
            requestId: 'test-123',
            error: 'Test error'
        });

        await flushPromises();
        const errorBlock = element.shadowRoot.querySelector('.slds-theme_error');
        expect(errorBlock).toBeTruthy();
    });
});