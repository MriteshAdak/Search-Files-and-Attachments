import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import QueryData from 'c/queryData';
import getObjectFieldOptions from '@salesforce/apex/QueryController.getObjectFieldOptions';
import executeQuery from '@salesforce/apex/QueryController.executeQuery';

jest.mock(
    '@salesforce/apex/QueryController.getObjectFieldOptions',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/QueryController.executeQuery',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

const getObjectFieldOptionsAdapter = registerApexTestWireAdapter(getObjectFieldOptions);

const mockFieldOptions = [
    {
        label: 'Name',
        value: 'Name',
        fieldType: 'TEXT',
        validOperators: ['=', '!=', 'LIKE', 'IN', 'NOT IN'],
        isRequired: true,
        isUpdateable: true,
        picklistValues: []
    },
    {
        label: 'Body Length',
        value: 'BodyLength',
        fieldType: 'NUMBER',
        validOperators: ['=', '!=', '<', '<=', '>', '>='],
        isRequired: false,
        isUpdateable: false,
        picklistValues: []
    }
];

const flushPromises = () => Promise.resolve();

describe('c-query-data', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('loads field options via wire adapter', async () => {
        const element = createElement('c-query-data', {
            is: QueryData
        });
        document.body.appendChild(element);

        getObjectFieldOptionsAdapter.emit(mockFieldOptions);
        await flushPromises();

        expect(element.fieldOptions).toEqual(mockFieldOptions);
        expect(element.fieldOptionsError).toBeUndefined();
        const listbox = element.shadowRoot.querySelector('lightning-dual-listbox');
        expect(listbox).toBeTruthy();
    });

    it('shows loading state before wire emits', () => {
        const element = createElement('c-query-data', {
            is: QueryData
        });
        document.body.appendChild(element);

        expect(element.isLoadingFields).toBe(true);
        const spinner = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner).toBeTruthy();
    });

    it('handles wire adapter errors', async () => {
        const element = createElement('c-query-data', {
            is: QueryData
        });
        document.body.appendChild(element);

        getObjectFieldOptionsAdapter.error({ body: { message: 'Test error' } });
        await flushPromises();

        expect(element.fieldOptions).toEqual([]);
        expect(element.hasFieldOptionsError).toBe(true);
        const errorBlock = element.shadowRoot.querySelector('.slds-text-color_error');
        expect(errorBlock).toBeTruthy();
    });
});