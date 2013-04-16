<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Actual_FMV</fullName>
        <description>set Actual FMV to Estimated FMV</description>
        <field>Actual_FMV__c</field>
        <formula>Estimated_FMV__c</formula>
        <name>Update Actual FMV</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Update Auction Item Piece Actual FMV</fullName>
        <actions>
            <name>Update_Actual_FMV</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>update the Actual FMV field from the Estimated FMV calculated field.</description>
        <formula>true</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
