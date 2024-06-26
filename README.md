# Managed App Schema Builder

![GitHub release (latest by date)](https://img.shields.io/github/v/release/BIG-RAT/Managed-App-Schema-Builder?display_name=tag) ![GitHub all releases](https://img.shields.io/github/downloads/BIG-RAT/Managed-App-Schema-Builder/total) ![GitHub latest release](https://img.shields.io/github/downloads/BIG-RAT/Managed-App-Schema-Builder/latest/total)
 ![GitHub issues](https://img.shields.io/github/issues-raw/BIG-RAT/Managed-App-Schema-Builder) ![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/BIG-RAT/Managed-App-Schema-Builder) ![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/BIG-RAT/Managed-App-Schema-Builder) ![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/BIG-RAT/Managed-App-Schema-Builder)

Download: [Managed App Schema Builder](https://github.com/BIG-RAT/Managed-App-Schema-Builder/releases/download/current/Managed.App.Schema.Builder.zip)

Latest Beta: [Beta](https://github.com/BIG-RAT/Managed-App-Schema-Builder/releases/download/v1.0.0-b1/Managed.App.Schema.Builder_v1.0.0-b1.zip)

Before wasting time creating something that's already been done see if it's available:

* [https://github.com/ProfileCreator/ProfileManifests](https://github.com/ProfileCreator/ProfileManifests)

* [https://github.com/Jamf-Custom-Profile-Schemas/ProfileManifestsMirror](https://github.com/Jamf-Custom-Profile-Schemas/ProfileManifestsMirror)





Otherwise use the app to create a JSON file that can be used to set application preferences.  Then don't be shy, if it's new please share what you have crafted.

![alt text](./images/App.png "Managed App Schema Builder")

Starting with Jamf Pro v10.19 you are able to create a custom schema, in the form of a JSON, to create a template for setting application preferences within the Application & Custom Settings payload (Computer Configuration Profiles).


#### Usage:
* Provide a preference domain, something like: com.jamf.JamfRemote
* Provide (optional) a description for the preference domain.
* Start by adding a preference key (plus sign towards the bottom left).
* Modify the Key Friendly Name if desired.  This is what is displayed for the key within the Jamf Pro GUI.
* Provide (optional) a description of what the key does, what it applies to.  Perhaps descript the format of the data entered.
* Select the key type from the drop down menu.
* For 'integer (from list)', additional information can be entered.
	* Comma seperated list of options.  These will be items selectable from a menu. Quotes are not required when entering a menu choice and the choice cannot contain a comma in it.
	* Comma seperated list of integers.  This will be the integer value corresponding to the menu choice.
		<img src="./images/integerFromList.png" alt="integer (from list)" width="512" height="261">


Once all the keys and values have been set click 'Save'.  The contents of the saved file will be copied to the clipboard.  This can then be pasted into the Schema field in the Jamf Pro server.

The saved JSON file can later be imported and modify.  Add/Update/Remove keys or change the description.
___

Thanks @talkingmoose for all the help!
