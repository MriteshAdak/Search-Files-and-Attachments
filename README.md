# Search Files & Attachments

A Salesforce Lightning Web Component app for querying Files and Attachments directly from the platform. Users can choose the object, select fields, add filters, and run secure dynamic queries from a single tab in Salesforce. Build using Agentforce, and hence, the code is currently "in review". The generated code was checked (by me) throughout the creation phase (was segmented into 8 phases) but a comprehensive review is in the works. This README will be updated with the progress.

## Table of Contents

<ul>
	<li><a href="#getting-started">Getting Started</a></li>
	<li><a href="#installation-options">Installation Options</a></li>
	<li><a href="#post-installation-setup">Post-Installation Setup</a></li>
	<li><a href="#usage">Usage</a></li>
	<li><a href="#the-process-and-the-outcome-so-far">The Process and the Outcome So Far</a></li>
	<li><a href="#roadmap">Roadmap</a></li>
</ul>

## Getting Started

### Prerequisites

You need a Salesforce org to install and use the app. A Salesforce Developer Edition org is usually the quickest option if you do not already have one.

### Installation Options

#### Option 1: Install via Package Link (Recommended for Admins)

Install the unlocked package directly into your Sandbox or Production environment using the package link below:

<a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=0HoWU0000002AuX0AU">Install Package</a>

1. Open the link above.
2. Log in to your Salesforce org.
3. Choose "Install for All Users".
4. Click Install.

If prompted for an installation key, use:

```text
test1234
```

#### Option 2: Deploy from Source (Recommended for Developers)

If you have the Salesforce CLI installed, you can deploy the source directly from this repository.

1. Clone the repository.
2. Authorize your target org.
3. Deploy the source.

```sh
git clone https://github.com/MriteshAdak/Search-Files-and-Attachments
cd Search-Files-and-Attachments
sf org login web --alias target-org
sf project deploy start --target-org target-org
```

## Post-Installation Setup

After installation, assign the Search Files & Attachments permission set to every user who needs access to the app. Without it, the component cannot execute queries.

1. Go to Setup > Users > Permission Sets.
2. Open Search Files & Attachments.
3. Click Manage Assignments > Add Assignment.
4. Select the users and click Assign.

This permission set grants access to the Apex classes and Lightning components required by the app.

## Usage

1. Open the App Launcher.
2. Search for Search Files & Attachments and open the tab.
3. Choose the object you want to query.
4. Select the fields you want returned.
5. Add filters and adjust the limit if needed.
6. Execute the query and review the results.

## The Process and the Outcome So Far

### Architecture

The app follows a layered Salesforce architecture:

- LWC: `searchFilesAndAttachments` provides the user interface for selecting objects, fields, and filters.
- Apex Controller: `QueryController` serves as the entry point for client-side query execution and metadata retrieval.
- Security Layer: `SecurityService` validates object access, field-level access, and accessible field metadata.
- Query Layer: `SoqlQueryBuilder` constructs dynamic SOQL for the requested object, fields, and filters.
- DTO and Utility Layer: `QueryFilterDto`, `SchemaFieldOption`, `FieldTypeMetadata`, and `Utils` support validation, metadata normalization, and query building.

### Project Structure

```text
Search-Files-and-Attachments/
├── config/
├── docs/
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/
│           │   ├── FieldTypeMetadata.cls
│           │   ├── QueryController.cls
│           │   ├── QueryFilterDto.cls
│           │   ├── SchemaFieldOption.cls
│           │   ├── SecurityService.cls
│           │   ├── SoqlQueryBuilder.cls
│           │   └── Utils.cls
│           ├── flexipages/
│           │   └── Search_Files_Attachments.flexipage-meta.xml
│           ├── lwc/
│           │   ├── queryData/
│           │   ├── queryResults/
│           │   └── searchFilesAndAttachments/
│           ├── permissionsets/
│           │   └── SearchFiles_Attachments.permissionset-meta.xml
│           └── tabs/
│               └── Search_Files_Attachments.tab-meta.xml
├── manifest/
└── scripts/
```

### Known Issues and Limitations

- Error handling and user feedback can still be improved for edge cases such as empty results and query failures.
- Logical operators between filter conditions are not yet supported in the UI.
- Pagination is not implemented for query results.
- Filter validation is still basic and could provide better guidance for user input.
- Parent object fields are not currently supported in filter field selection.

## Roadmap

- [ ] Refine the application structure.
- [ ] Add a select menu for field selection in the WHERE clause.
- [ ] Add support for logical operators between filter conditions.
- [ ] Improve validation for filter inputs.

## References

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
