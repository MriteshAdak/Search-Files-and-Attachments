import { createElement } from 'lwc';
import { registerTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import SearchFilesAndAttachments from 'c/searchFilesAndAttachments';
import { MessageContext, publish } from 'lightning/messageService';
import executeQuery from '@salesforce/apex/QueryController.executeQuery';

jest.mock(
    '@salesforce/apex/QueryController.executeQuery',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock('lightning/messageService', () => {
    const original = jest.requireActual('lightning/messageService');
    return {
        ...original,
        publish: jest.fn()
    };
});

const messageContextAdapter = registerTestWireAdapter(MessageContext);

const flushPromises = () => Promise.resolve();

describe('c-search-files-and-attachments', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('handles query submit and publishes LMS events', async () => {
        executeQuery.mockResolvedValue([{ Id: '001', Name: 'Test' }]);

        const element = createElement('c-search-files-and-attachments', {
            is: SearchFilesAndAttachments
        });
        document.body.appendChild(element);

        messageContextAdapter.emit({});

        const queryData = element.shadowRoot.querySelector('c-query-data');
        queryData.dispatchEvent(
            new CustomEvent('querysubmit', {
                detail: {
                    requestId: 'test-123',
                    query: {
                        object: 'Account',
                        fields: ['Name'],
                        filters: [],
                        limit: 50
                    }
                }
            })
        );

        await flushPromises();

        expect(executeQuery).toHaveBeenCalled();
        expect(publish).toHaveBeenCalledWith(
            expect.anything(),
            expect.anything(),
            expect.objectContaining({ eventType: 'queryStarted' })
        );
        expect(publish).toHaveBeenCalledWith(
            expect.anything(),
            expect.anything(),
            expect.objectContaining({ eventType: 'querySuccess' })
        );
    });
});