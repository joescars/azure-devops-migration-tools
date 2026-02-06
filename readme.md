# Azure DevOps Migration Tools

This repo provides tools and configuration for migrating work items, projects, and other artifacts between Azure DevOps (ADO) instances using the open source project [Azure DevOps Migration Tools](https://devopsmigration.io/). 

It enables secure, automated migration of:

- **Work Items** (Epics, Features, User Stories, Tasks, etc.)
- **Project Structure** (Area Paths, Iteration Paths)
- **Attachments** and links
- **Work Item History** and comments

The migration process validates source and target configurations, applies custom WIQL queries to filter specific work items, and maintains data integrity throughout the migration process. All sensitive information like Personal Access Tokens are managed securely through environment variables.

### Environment Variables and Configuration Scripts

Instead of hardcoding sensitive values like Personal Access Tokens directly in the configuration.json file, this project supports using environment variables and provides helper scripts to manage them securely.

Your `configuration.json` file can reference environment variables if you leave the value empty. For example:

```json
"Authentication": {
    "AuthenticationMode": "AccessToken",
    "AccessToken": ""
}
```

### Setting Up Environment Variables

#### Option 1: Using the .env File (Recommended)

1. Edit the `.env` file in the project root with your actual tokens and values:

```env
# Personal Access Tokens for Azure DevOps migration
MigrationTools__Endpoints__Source__Authentication__AccessToken=your_source_pat_here
MigrationTools__Endpoints__Source__Collection=https://dev.azure.com/YourOrg/
MigrationTools__Endpoints__Source__Project=Your Source Project Name

MigrationTools__Endpoints__Target__Authentication__AccessToken=your_target_pat_here  
MigrationTools__Endpoints__Target__Collection=https://dev.azure.com/YourTargetOrg/
MigrationTools__Endpoints__Target__Project=Your Target Project Name
```

2. Load the environment variables from the .env file:

```powershell
# Load all variables from .env file (persistent)
.\scripts\Set-PAT-FromEnvFile.ps1

# Or load for current session only
.\scripts\Set-PAT-FromEnvFile.ps1 -SessionOnly
```

#### Option 2: Interactive Setup

Use the interactive script to securely enter your tokens:

```powershell
# Interactive setup with secure input (tokens are hidden while typing)
.\scripts\Set-PAT-Simple.ps1

# Session only mode
.\scripts\Set-PAT-Simple.ps1 -SessionOnly
```

### Benefits of Using Environment Variables

- ✅ **Security**: Keeps sensitive tokens out of configuration files
- ✅ **Version Control**: Configuration files can be safely committed without secrets
- ✅ **Flexibility**: Different environments can use different values without changing config files
- ✅ **Team Collaboration**: Team members can use their own tokens without conflicts

### Unicode Character Support

The scripts properly handle Unicode characters (like en dashes –) in project names by using UTF-8 encoding when reading .env files.

### Work Items to Migrate

Limit the work item types you wish migrate through custom WIQL query and the validator tool. This will ensure only the items you want to migrate are included and it will not try to validate everything in your ADO Instance.

#### WIQL Query

```json
"Processors": [
    {
        "ProcessorType": "TfsWorkItemMigrationProcessor",
        "Enabled": true,
        "WIQLQuery": "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @TeamProject 
        AND [System.WorkItemType] IN ('Epic', 'Feature','User Story','Task') 
        ORDER BY [System.ChangedDate] desc",
        "FixHtmlAttachmentLinks": true,
        "WorkItemCreateRetryLimit": 5,
        "FilterWorkItemsThatAlreadyExistInTarget": false,
        "GenerateMigrationComment": true,
        "SourceName": "Source",
        "TargetName": "Target"
    }
```

#### Validator Configuration

```json
"CommonTools": {
    "TfsWorkItemTypeValidatorTool": {
        "Enabled": true,
        "ExcludeDefaultWorkItemTypes": false,
        "IncludeWorkItemTypes": [
            "Task", "User Story", "Feature", "Epic"
        ]
    },
```


## Execute Commands

This command will first validate that the tool has the proper access and both instances are configured correctly. Once the validation passes it will run the migration. If the validation fails, it will provide verbose error logging for trouble shooting.

```powershell
devopsmigration execute --config .\configuration.json
```
